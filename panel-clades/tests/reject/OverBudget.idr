-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- A panel whose state peaks at 80 does not fit a budget of 64; no proof of
-- StateWithin can be written.
-- EXPECT: Mismatch between: 0 and 16
module OverBudget

import TypedWasm.ABI.ResourceAlgebra.HWM
import PanelClades.ABI.Grades

%default total

invalid : StateWithin (MkHWM 80 0 LTEZero) 64
invalid = MkStateWithin (lteAddRight 64)
