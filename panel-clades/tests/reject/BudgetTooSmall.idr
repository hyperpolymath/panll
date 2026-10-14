-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- MUST FAIL (panel-clades/scripts/check-abi.sh).
--
-- A clade config that declares a state peaking at 48 within a budget of 40
-- yields no contract: declaredContract needs `So (lte 48 40)`, which has no
-- proof.  This is what happens to Grades.neurosymBridgeContract if its
-- config.k9.ncl budget is set below its declared peak.
-- EXPECT: Can't find an implementation for So False
module BudgetTooSmall

import Data.Nat
import Data.So
import PanelClades.ABI.Budgets
import PanelClades.ABI.Grades

%default total

invalid : CladeResourceContract (budgetOf (MkDeclaredResources 48 16 40 2 3))
invalid = declaredContract "over-budget" (MkDeclaredResources 48 16 40 2 3)
