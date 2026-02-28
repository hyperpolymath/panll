// SPDX-License-Identifier: PMPL-1.0-or-later
// Deno static file server for PanLL dev mode — replaces python3 http.server
//
// Serves the project root on port 8000 so that public/index.html can resolve
// ES module imports like ../src/App.res.js.  Tauri's devUrl points at
// http://localhost:8000/public/ which auto-serves index.html.
//
// Only serves files that match known safe extensions to avoid leaking secrets
// or config.  Binds to localhost only (never 0.0.0.0).

import { serveDir } from "jsr:@std/http@1/file-server";

const port = 8000;

// Allowlist of file extensions the dev server will serve.
// Anything not matching gets a 403.
const ALLOWED_EXTENSIONS = new Set([
  ".html", ".css", ".js", ".mjs", ".ts",
  ".json", ".map",
  ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".webp",
  ".woff", ".woff2", ".ttf", ".eot",
]);

function isAllowedPath(pathname: string): boolean {
  // Allow directory paths (trailing slash) — needed for index.html resolution
  if (pathname.endsWith("/")) return true;
  const dot = pathname.lastIndexOf(".");
  if (dot === -1) return false;
  return ALLOWED_EXTENSIONS.has(pathname.slice(dot).toLowerCase());
}

Deno.serve({ port, hostname: "127.0.0.1", onListen: () => {
  console.log(`PanLL dev server: http://localhost:${port}/public/`);
  console.log("Serving project root (filtered by extension allowlist)");
}}, (req: Request) => {
  const url = new URL(req.url);

  if (!isAllowedPath(url.pathname)) {
    return new Response("403 Forbidden\n", { status: 403 });
  }

  return serveDir(req, { fsRoot: ".", quiet: true });
});
