// Pragmatic email check — good enough to reject obvious junk without trying to
// fully implement RFC 5322. Real validation is "did the confirmation land."
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

export function isValidEmail(raw: string): boolean {
  const email = normalizeEmail(raw);
  return email.length <= 254 && EMAIL_RE.test(email);
}

/**
 * Firestore document IDs can't contain "/" and must be non-empty / <=1500 bytes.
 * We key waitlist docs by the normalized email for free idempotency, so encode
 * it into a safe id. encodeURIComponent handles "/" and other reserved chars.
 */
export function emailToDocId(email: string): string {
  return encodeURIComponent(normalizeEmail(email));
}
