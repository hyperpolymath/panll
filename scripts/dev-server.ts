// SPDX-License-Identifier: PMPL-1.0-or-later
// Deno static file server for PanLL dev mode — replaces python3 http.server
//
// Serves the public/ directory on port 8000.  Tauri's devUrl points here.
// ES module imports resolve relative to public/ thanks to the webview.

import { serveDir } from "jsr:@std/http@1/file-server";

const port = 8000;

Deno.serve({ port, onListen: () => {
  console.log(`PanLL dev server: http://localhost:${port}`);
  console.log("Serving: public/");
}}, (req: Request) =>
  serveDir(req, { fsRoot: "public", quiet: true })
);
