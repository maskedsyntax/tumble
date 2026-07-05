import { NextResponse } from "next/server";
import { emailToDocId, isValidEmail, normalizeEmail } from "@/lib/validation";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type Body = {
  email?: unknown;
  // Honeypot: a hidden field real users never fill. Bots that autofill it get
  // silently accepted-looking responses but never written.
  company?: unknown;
};

type FirestoreField =
  | { stringValue: string }
  | { timestampValue: string }
  | { nullValue: null };

function getFirestoreRestConfig() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const apiKey = process.env.FIREBASE_WEB_API_KEY;

  if (!projectId || !apiKey) {
    throw new Error(
      "Missing Firebase REST config. Set FIREBASE_PROJECT_ID and FIREBASE_WEB_API_KEY.",
    );
  }

  return { projectId, apiKey };
}

function asFirestoreFields(data: Record<string, FirestoreField>) {
  return { fields: data };
}

export async function POST(request: Request) {
  let body: Body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request." }, { status: 400 });
  }

  // Honeypot tripped — pretend success, write nothing.
  if (typeof body.company === "string" && body.company.trim() !== "") {
    return NextResponse.json({ ok: true });
  }

  if (typeof body.email !== "string" || !isValidEmail(body.email)) {
    return NextResponse.json(
      { ok: false, error: "Please enter a valid email address." },
      { status: 400 },
    );
  }

  const email = normalizeEmail(body.email);

  try {
    const { projectId, apiKey } = getFirestoreRestConfig();
    const params = new URLSearchParams({
      documentId: emailToDocId(email),
      key: apiKey,
    });
    const url =
      `https://firestore.googleapis.com/v1/projects/${projectId}` +
      `/databases/(default)/documents/waitlist?${params.toString()}`;

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(
        asFirestoreFields({
          email: { stringValue: email },
          source: { stringValue: "landing" },
          userAgent: request.headers.get("user-agent")
            ? { stringValue: request.headers.get("user-agent") as string }
            : { nullValue: null },
          createdAt: { timestampValue: new Date().toISOString() },
        }),
      ),
    });

    // Already exists means the person is already on the waitlist. Treat that as
    // success so repeat submissions stay friendly.
    if (!res.ok && res.status !== 409) {
      const text = await res.text().catch(() => "");
      throw new Error(`Firestore REST write failed (${res.status}): ${text}`);
    }

    return NextResponse.json({ ok: true });
  } catch (err) {
    console.error("waitlist write failed:", err);
    return NextResponse.json(
      { ok: false, error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }
}
