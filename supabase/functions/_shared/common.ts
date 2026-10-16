// Shared helpers for Khaja Attariya edge functions.
import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2.45.4";

// Comma-separated list of web origins allowed to call the functions from a browser (e.g.
const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",").map((o) => o.trim()).filter(Boolean);

export function corsHeaders(req: Request): HeadersInit {
  const origin = req.headers.get("Origin") ?? "";
  const allow = allowedOrigins.length === 0
    ? "*"
    : (allowedOrigins.includes(origin) ? origin : allowedOrigins[0]);
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

export function json(req: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(req), "Content-Type": "application/json" },
  });
}

/** Generic, safe error — details only go to the function logs. */
export function fail(req: Request, status: number, code: string, logDetail?: unknown): Response {
  if (logDetail !== undefined) console.error(code, logDetail);
  return json(req, { error: code }, status);
}

/** Service-role client (bypasses RLS) — only used after checking the caller. */
export function adminClient(): SupabaseClient {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });
}

/** The signed-in user who called the function, or null. */
export async function callerUser(req: Request): Promise<User | null> {
  const auth = req.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) return null;
  const client = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });
  const { data, error } = await client.auth.getUser();
  return error ? null : data.user;
}

// Khalti: sandbox by default (decision D-10).
export const KHALTI_BASE = (Deno.env.get("KHALTI_BASE_URL") ?? "https://dev.khalti.com/api/v2").replace(/\/$/, "");

export function khaltiKey(): string {
  const key = Deno.env.get("KHALTI_SECRET_KEY");
  if (!key) throw new Error("KHALTI_SECRET_KEY not set");
  return key;
}
