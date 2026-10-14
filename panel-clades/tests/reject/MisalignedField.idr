-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- A u64 at offset 4 is not 8-byte aligned: Divides is an equation, so no
-- quotient makes 4 a multiple of 8.
-- EXPECT: Mismatch between: 0 and 4
module MisalignedField

import PanelClades.ABI.Layout

%default total

invalid : Divides 8 4
invalid = DivideBy 0 Refl
