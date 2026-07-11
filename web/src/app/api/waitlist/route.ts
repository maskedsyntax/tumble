import { NextResponse } from "next/server";
import { getApp, getApps, initializeApp } from "firebase/app";
import { addDoc, collection, getFirestore, serverTimestamp } from "firebase/firestore/lite";
import { isValidEmail, normalizeEmail } from "@/lib/validation";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type Body = {
  email?: unknown;
  // Honeypot: a hidden field real users never fill. Bots that autofill it get
  // silently accepted-looking responses but never written.
  company?: unknown;
};

function getFirebaseConfig() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const apiKey = process.env.FIREBASE_WEB_API_KEY;

  if (!projectId || !apiKey) {
    throw new Error(
      "Missing Firebase config. Set FIREBASE_PROJECT_ID and FIREBASE_WEB_API_KEY.",
    );
  }

  return {
    apiKey,
    projectId,
    authDomain: `${projectId}.firebaseapp.com`,
  };
}

function getWaitlistDb() {
  const app = getApps().length ? getApp() : initializeApp(getFirebaseConfig());
  return getFirestore(app);
}

export async function POST(request: Request) {
  let body: Body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request." }, { status: 400 });
  }

  // Honeypot tripped: pretend success, write nothing.
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
    await addDoc(collection(getWaitlistDb(), "waitlist"), {
      email,
      source: "landing",
      userAgent: request.headers.get("user-agent") ?? null,
      createdAt: serverTimestamp(),
    });

    return NextResponse.json({ ok: true });
  } catch (err) {
    console.error("waitlist write failed:", err);
    return NextResponse.json(
      { ok: false, error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }
}
