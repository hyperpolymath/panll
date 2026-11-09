-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- Fields must be in order and must not overlap: b starts at 4, inside a,
-- which ends at 8, so no FieldsOrdered evidence exists for them.
-- EXPECT: Can't find an implementation for So False
module OverlappingFields

import Data.So
import Data.Nat
import PanelClades.ABI.Layout

%default total

invalid : FieldsOrdered [MkField "a" 0 8 8, MkField "b" 4 4 4]
invalid = OrdCons (fitsIn 8 4) OrdOne
