import { NextResponse } from "next/server";
import { APP_STORE_URL } from "@/lib/app-store";

export const runtime = "edge";

export function GET() {
  return NextResponse.redirect(APP_STORE_URL, 302);
}
