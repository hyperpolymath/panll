-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- HasSize has one constructor, fixed to cSizeOf: a pointer on WASM is 4
-- bytes, and no proof that it is 8 can be written.
-- EXPECT: Mismatch between: 0 and 4
module WasmPointerIsEightBytes

import PanelClades.ABI.Types

%default total

invalid : HasSize WASM CTPtr 8
invalid = SizeIs
