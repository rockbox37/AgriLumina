// Serves the built admin dashboard (Flutter web) as static files, so the
// dashboard is hosted on the same Supabase project with no extra services.
//
// The build output is NOT in git: scripts/deploy-admin.sh builds it into
// ./dist and deploys this function with the files bundled via the
// static_files entry in config.toml. verify_jwt is false because browsers
// request HTML/JS without Supabase headers — the app itself still requires
// an admin login, and non-admin sessions can read nothing.

const DIST = new URL("./dist/", import.meta.url);

const CONTENT_TYPES: Record<string, string> = {
  html: "text/html; charset=utf-8",
  js: "text/javascript",
  mjs: "text/javascript",
  css: "text/css",
  json: "application/json",
  wasm: "application/wasm",
  png: "image/png",
  ico: "image/x-icon",
  svg: "image/svg+xml",
  otf: "font/otf",
  ttf: "font/ttf",
  woff2: "font/woff2",
  frag: "application/octet-stream",
};

function contentTypeFor(path: string): string {
  const ext = path.split(".").pop() ?? "";
  return CONTENT_TYPES[ext] ?? "application/octet-stream";
}

async function serveFile(path: string): Promise<Response | null> {
  // Guard against path traversal out of dist/.
  if (path.includes("..")) return null;
  try {
    const data = await Deno.readFile(new URL(path, DIST));
    return new Response(data, {
      headers: {
        "Content-Type": contentTypeFor(path),
        // The launcher page is opened from disk (file://), so the engine's
        // asset fetches arrive from a null origin and need CORS.
        "Access-Control-Allow-Origin": "*",
        // Flutter's web artifacts are not content-hashed and the service
        // worker (its usual versioning layer) can't register cross-origin,
        // so everything must revalidate — otherwise deploys go stale.
        "Cache-Control": "no-cache",
      },
    });
  } catch {
    return null;
  }
}

Deno.serve(async (req) => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    return new Response("method not allowed", { status: 405 });
  }
  // Mounted at /functions/v1/admin-web; strip the function prefix.
  const segments = new URL(req.url).pathname.split("/").filter(Boolean);
  const path = segments.slice(1).join("/");
  return (await serveFile(path === "" ? "index.html" : path)) ??
    // SPA fallback: unknown paths get the app shell.
    (await serveFile("index.html")) ??
    new Response("not found", { status: 404 });
});
