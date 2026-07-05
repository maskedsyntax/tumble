"use client";

import { useState, type FormEvent } from "react";

type Status = "idle" | "submitting" | "success" | "error";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [company, setCompany] = useState(""); // honeypot
  const [status, setStatus] = useState<Status>("idle");
  const [message, setMessage] = useState("");

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (status === "submitting") return;

    const trimmed = email.trim();
    if (!EMAIL_RE.test(trimmed)) {
      setStatus("error");
      setMessage("Please enter a valid email address.");
      return;
    }

    setStatus("submitting");
    setMessage("");

    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: trimmed, company }),
      });
      const data = (await res.json().catch(() => ({}))) as {
        ok?: boolean;
        error?: string;
      };

      if (res.ok && data.ok) {
        setStatus("success");
        setMessage("You're on the list. We'll email you when Tumble ships.");
        setEmail("");
      } else {
        setStatus("error");
        setMessage(data.error ?? "Something went wrong. Please try again.");
      }
    } catch {
      setStatus("error");
      setMessage("Network error. Please try again.");
    }
  }

  if (status === "success") {
    return (
      <div
        className="animate-fade-up rounded-2xl border border-cream/25 bg-cream/10 px-6 py-5 text-center backdrop-blur-sm"
        role="status"
        aria-live="polite"
      >
        <p className="font-display text-xl text-cream">You&rsquo;re on the list.</p>
        <p className="mt-1 text-sm text-cream/70">
          We&rsquo;ll email you the moment Tumble ships.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} noValidate className="mx-auto w-full max-w-xl">
      <label htmlFor="email" className="mb-3 block text-sm font-medium text-cream/85">
        Get notified when Tumble launches.
      </label>

      {/* Honeypot — visually hidden, off the tab order. Bots fill it, humans don't. */}
      <div aria-hidden="true" className="absolute left-[-9999px] h-0 w-0 overflow-hidden">
        <label htmlFor="company">Company</label>
        <input
          id="company"
          name="company"
          type="text"
          tabIndex={-1}
          autoComplete="off"
          value={company}
          onChange={(e) => setCompany(e.target.value)}
        />
      </div>

      <div className="flex flex-col gap-2 rounded-[1.65rem] border border-cream/15 bg-cream/[0.08] p-1.5 shadow-[0_22px_60px_-32px_rgba(0,0,0,0.95)] backdrop-blur-md sm:flex-row sm:rounded-full">
        <input
          id="email"
          name="email"
          type="email"
          inputMode="email"
          autoComplete="email"
          placeholder="you@email.com"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (status === "error") setStatus("idle");
          }}
          aria-invalid={status === "error"}
          aria-describedby="waitlist-status"
          className="w-full flex-1 rounded-full border border-cream/20 bg-cream/95 px-5 py-3.5 text-base text-ink shadow-inner outline-none transition placeholder:text-ink/40 focus:border-amber focus:ring-2 focus:ring-amber/55"
        />
        <button
          type="submit"
          disabled={status === "submitting"}
          className="shrink-0 rounded-full bg-amber px-6 py-3.5 text-base font-semibold text-ink shadow-[0_14px_32px_-18px_rgba(223,171,104,0.9)] transition hover:bg-cream focus:outline-none focus:ring-2 focus:ring-cream/80 focus:ring-offset-2 focus:ring-offset-blue-deep disabled:cursor-not-allowed disabled:opacity-60"
        >
          {status === "submitting" ? "Joining…" : "Join the waitlist"}
        </button>
      </div>

      <p
        id="waitlist-status"
        aria-live="polite"
        className={`mt-3 min-h-[1.25rem] text-sm ${
          status === "error" ? "text-amber" : "text-cream/60"
        }`}
      >
        {status === "error" ? message : "No spam. One email when we launch."}
      </p>
    </form>
  );
}
