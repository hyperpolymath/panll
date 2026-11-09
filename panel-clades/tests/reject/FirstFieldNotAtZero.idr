-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- C allows no padding before the first member, so a struct whose only
-- field sits at offset 8 has no C layout.  The field is aligned, the
-- struct covers it and is aligned to 4: refused by checkCABI because the
-- first field is not at offset 0.
-- EXPECT: Mismatch between: True and False
module FirstFieldNotAtZero

import Data.Either
import Data.So
import Data.Nat
import Decidable.Equality
import PanelClades.ABI.Layout

%default total

padded : StructLayout
padded = MkStructLayout [MkField "x" 8 4 4] 12 4 (fitsIn 12 12) (DivideBy 3 Refl)

invalid : isRight (checkCABI FirstFieldNotAtZero.padded) = True
invalid = Refl
