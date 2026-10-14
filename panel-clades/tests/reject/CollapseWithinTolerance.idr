-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- A Panel-N → Panel-W crossing that collapses totally (loss = Infinity, the
-- kernel's 𝟘) is never within any tolerance.
-- EXPECT: Mismatch between: Finite .* and Infinity
module CollapseWithinTolerance

import TypedWasm.ABI.ResourceAlgebra.Loss
import PanelClades.ABI.Grades

%default total

invalid : LossWithin Infinity 1000
invalid = MkLossWithin LTEZero
