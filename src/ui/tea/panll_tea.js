// SPDX-License-Identifier: AGPL-3.0-or-later
// PanLL GUI Bridge

/**
 * Wraps the PanLL AffineScript Wasm module.
 */
class PanLLTEA {
  constructor(exports) {
    this.exports = exports;
    this.memory = exports.memory;
  }

  init() {
    return this.exports.panll_init();
  }

  update(msg, model) {
    return this.exports.panll_update(msg, model);
  }

  view(model) {
    const ptr = this.exports.panll_view(model);
    return this.readString(ptr);
  }

  subs(model) {
    const ptr = this.exports.panll_subs(model);
    return this.readString(ptr);
  }

  readString(ptr) {
    const view = new DataView(this.memory.buffer);
    const len = view.getInt32(ptr, true);
    const bytes = new Uint8Array(this.memory.buffer, ptr + 4, len);
    return new TextDecoder().decode(bytes);
  }
}

export async function load(url) {
  const response = await fetch(url);
  const bytes = await response.arrayBuffer();
  const importObject = {
    wasi_snapshot_preview1: {
      fd_write: (fd, iovs, iovs_len, nwritten) => 0
    }
  };
  const result = await WebAssembly.instantiate(bytes, importObject);
  return new PanLLTEA(result.instance.exports);
}

export const Msg = {
  Navigate: (pane) => ({ tag: 0, value: pane }),
  PopState: () => ({ tag: 1 })
};

// Internal Wasm tags for Msg
export const MsgTag = {
  Navigate: 0,
  PopState: 1
};

export const PanLLPane = {
  PaneL: 0,
  PaneN: 1,
  PaneW: 2,
  Vexometer: 3
};
