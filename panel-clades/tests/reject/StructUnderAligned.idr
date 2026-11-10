-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- A struct is aligned to its largest field alignment.  This one declares
-- 4 while its field needs 8: aligned, ordered, power-of-two, and still
-- refused by checkCABI.
-- EXPECT: Mismatch between: True and False
module StructUnderAligned

import Data.Either
import Data.So
import Data.Nat
import Decidable.Equality
import PanelClades.ABI.Layout

%default total

underAligned : StructLayout
underAligned = MkStructLayout [MkField "y" 0 8 8] 8 4 (fitsIn 8 8) (DivideBy 2 Refl)

invalid : isRight (checkCABI StructUnderAligned.underAligned) = True
invalid = Refl
