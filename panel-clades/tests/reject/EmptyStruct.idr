-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- A C struct needs at least one member (C11 6.7.2.1p8).  This layout has
-- none: size 0 covers its (no) fields and is a multiple of its alignment 1,
-- which is the largest field alignment of an empty list, so only the
-- member rule refuses it in checkCABI.
-- EXPECT: Mismatch between: True and False
module EmptyStruct

import Data.Either
import Data.So
import Data.Nat
import Decidable.Equality
import PanelClades.ABI.Layout

%default total

empty : StructLayout
empty = MkStructLayout [] 0 1 (fitsIn 0 0) (DivideBy 0 Refl)

invalid : isRight (checkCABI EmptyStruct.empty) = True
invalid = Refl
