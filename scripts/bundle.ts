// SPDX-License-Identifier: PMPL-1.0-or-later
// esbuild bundler for PanLL — resolves bare npm specifiers that WebKitGTK
// cannot handle via import maps.
//
// Usage:
//   deno run --allow-read --allow-write --allow-env --allow-net scripts/bundle.ts          # one-shot build
//   deno run --allow-read --allow-write --allow-env --allow-net scripts/bundle.ts --watch  # watch mode for dev

import * as esbuild from "npm:esbuild@0.24";

const watch = Deno.args.includes("--watch");

const ctx = await esbuild.context({
  entryPoints: ["src/App.res.js"],
  bundle: true,
  format: "esm",
  outfile: "public/app.bundle.js",
  sourcemap: true,
  // Tauri JS APIs are thin wrappers around window.__TAURI_INTERNALS__ IPC —
  // bundling them is the standard approach and avoids bare-specifier issues
  // in WebKitGTK which lacks import map support.
  nodePaths: ["node_modules"],
  logLevel: "info",
});

if (watch) {
  await ctx.watch();
  console.log("esbuild watching for changes...");
} else {
  await ctx.rebuild();
  await ctx.dispose();
}
