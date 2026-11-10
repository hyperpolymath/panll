-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- C alignments are powers of two.  decPow2 refuses 12, so a field aligned
-- to 12 has no AlignmentsPow2 evidence and checkCABI refuses its layout.
-- EXPECT: Mismatch between: True and False
module AlignmentNotPow2

import Data.Maybe
import Data.Nat
import Decidable.Equality
import PanelClades.ABI.Layout

%default total

invalid : isJust (decPow2 12) = True
invalid = Refl
