;; SPDX-License-Identifier: MPL-2.0
;; Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
;;
;; Guix development environment for panll.
;; Usage: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (gnu packages node)
             (gnu packages rust)
             (gnu packages crates-io)
             (gnu packages zig))

(package
  (name "panll")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (native-inputs
   (list deno
         rust
         rust-cargo
         zig))
  (synopsis "PanLL eNSAID panel layout system")
  (description
   "PanLL is a neurosymbolic panel layout system providing type-safe
workspace management with constraint-based panel composition,
Deno runtime, Rust core, and Zig FFI.")
  (license #f))
