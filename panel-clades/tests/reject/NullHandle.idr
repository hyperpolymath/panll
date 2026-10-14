-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- A Handle carries an erased proof that its pointer is not null, so a null
-- handle cannot be built.
-- EXPECT: Mismatch between: True and False
module NullHandle

import Data.So
import PanelClades.ABI.Types

%default total

invalid : Handle
invalid = MkHandle 0 {nonNull = Oh}
