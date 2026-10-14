-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
||| Graded clade resource contracts for PanLL panel-clades.
|||
||| A clade's resource contract is graded in typed-wasm's grade kernel
||| (TypedWasm.ABI.ResourceAlgebra, transcribed from hyperpolymath/
||| resource-algebra), imported at the pin in
||| panel-clades/scripts/fetch-siblings.sh — not re-declared here:
|||
|||   * panel state is graded by OCCUPANCY (the kernel's HWM instance): the
|||     high-water mark of the panel's live state, and what it still holds
|||     at the end of a phase;
|||   * the Panel-N → Panel-W crossing is graded by LOSS (the kernel's Loss
|||     instance, min-plus): how much a neural result loses on its way to
|||     the world panel (translation, confidence gating), with total
|||     collapse (Infinity) never within tolerance.
|||
||| The two must stay apart: an occupancy bound is not a cost bound
||| (resource-algebra S-1; `panelPhasesOccupancy` vs `panelPhasesCost`
||| below), and loss alternatives keep the LESS lossy branch.
|||
||| Status: the lemmas below are PROVEN (idris2 --build against the pinned
||| kernel).  A contract is checked against its clade's DECLARED budget,
||| which comes from the clade's config.k9.ncl through the generated
||| PanelClades.ABI.Budgets; a budget the declared grades do not fit fails
||| the typecheck.  The values are DESIGNED (declared for the owner to
||| confirm, not measured), and nothing in the panel runtime yet emits or
||| checks these grades.
|||
||| No unsafe casts, postulates or totality escapes.  %default total.

module PanelClades.ABI.Grades

import Data.Nat
import Data.So
import TypedWasm.ABI.ResourceAlgebra
import TypedWasm.ABI.ResourceAlgebra.Nat
import TypedWasm.ABI.ResourceAlgebra.Loss
import TypedWasm.ABI.ResourceAlgebra.MaxPlus
import TypedWasm.ABI.ResourceAlgebra.HWM
import PanelClades.ABI.Budgets

%default total

--------------------------------------------------------------------------------
-- Which algebra a grade comes from (the `algebra` field on the TypeLL wire)
--------------------------------------------------------------------------------

||| The kernel algebra a grade is drawn from.  Mirrors the `algebra` field of
||| schema/typell-grade.schema.json.
public export
data GradeAlgebra = AlgLoss | AlgMaxPlus | AlgHWM

||| The carrier of each algebra.
public export
GradeOf : GradeAlgebra -> Type
GradeOf AlgLoss    = LossGrade
GradeOf AlgMaxPlus = MaxPlusGrade
GradeOf AlgHWM     = HWMGrade

||| A grade tagged with its algebra: the `{grade, algebra}` pair.
public export
record TaggedGrade where
  constructor MkTaggedGrade
  algebra : GradeAlgebra
  grade   : GradeOf algebra

--------------------------------------------------------------------------------
-- Panel state: occupancy (HWM)
--------------------------------------------------------------------------------

||| The panel's live state stays within its budget: peak ≤ budget.
public export
data StateWithin : HWMGrade -> Nat -> Type where
  MkStateWithin : {g : HWMGrade} -> {budget : Nat} ->
                  LTE (peak g) budget -> StateWithin g budget

||| Two phases of a panel's life (e.g. before and after it transmutes): the
||| second starts from what the first still holds, so the run fits the
||| budget if the first phase does and the second fits in what the first
||| left.  This is the reclamation law (occupancy-types R-2) at the panel.
public export
phasesWithin : {a, b : HWMGrade} -> {m : Nat} ->
               StateWithin a m -> LTE (drift a + peak b) m ->
               StateWithin (hwmSeq a b) m
phasesWithin {a = MkHWM p1 n1 _} {b = MkHWM p2 n2 _} (MkStateWithin fits) after =
  MkStateWithin (maxLub fits after)

--------------------------------------------------------------------------------
-- The Panel-N → Panel-W crossing: loss
--------------------------------------------------------------------------------

||| The crossing loses no more than `tolerance`.  Total collapse (Infinity)
||| has no constructor: it is never within tolerance.
public export
data LossWithin : LossGrade -> Nat -> Type where
  MkLossWithin : {k, tolerance : Nat} -> LTE k tolerance -> LossWithin (Finite k) tolerance

||| Two crossings in sequence (Panel-N → bridge → Panel-W): losses add, and
||| so do the tolerances.  The kernel's sequence (lossSeq).
public export
crossTwice : {a, b : LossGrade} -> {n, m : Nat} ->
             LossWithin a n -> LossWithin b m -> LossWithin (lossSeq a b) (n + m)
crossTwice (MkLossWithin p) (MkLossWithin q) = MkLossWithin (plusLteMonotone p q)

||| min is below its left argument.
minLeLeft : (a, b : Nat) -> LTE (minimum a b) a
minLeLeft Z     _     = LTEZero
minLeLeft (S a) Z     = LTEZero
minLeLeft (S a) (S b) = LTESucc (minLeLeft a b)

||| Keeping the less lossy of two translations stays within tolerance.  The
||| kernel's alternatives (lossAlt = min).
public export
betterOfTwo : {a, b : LossGrade} -> {n : Nat} ->
              LossWithin a n -> LossWithin b n -> LossWithin (lossAlt a b) n
betterOfTwo {a = Finite x} {b = Finite y} (MkLossWithin p) (MkLossWithin _) =
  MkLossWithin (lteTrans (minLeLeft x y) p)

--------------------------------------------------------------------------------
-- The contract, against a declared budget
--------------------------------------------------------------------------------

||| An LTE proof found by evaluation.  For closed numbers `lte m n` reduces,
||| so the `So` is found automatically and no proof term is written by hand;
||| for numbers that do not fit there is no `So True`, and the typecheck
||| fails at the use site.
public export
fits : (m, n : Nat) -> {auto ok : So (lte m n)} -> LTE m n
fits m n {ok} = lteReflectsLTE m n (soToEq ok)

||| What a clade's contract is checked against: its declared state budget
||| and loss tolerance.
public export
record CladeBudget where
  constructor MkCladeBudget
  ||| Declared state budget, in the panel's state units.
  stateBudget   : Nat
  ||| Declared loss tolerance for the Panel-N → Panel-W crossing.
  lossTolerance : Nat

||| A clade's resource contract against a declared budget.
public export
record CladeResourceContract (budget : CladeBudget) where
  constructor MkCladeResourceContract
  ||| The clade's id (its directory under panel-clades/clades/).
  cladeId       : String
  ||| Panel state over a run, as an occupancy grade (HWM).
  stateGrade    : HWMGrade
  ||| The state fits the budget.
  stateFits     : StateWithin stateGrade (stateBudget budget)
  ||| Loss on the Panel-N → Panel-W crossing (Loss).
  crossingLoss  : LossGrade
  ||| The crossing stays within tolerance.
  crossingFits  : LossWithin crossingLoss (lossTolerance budget)

||| The contract's two grades on the wire, each tagged with its algebra.
public export
contractGrades : CladeResourceContract b -> List TaggedGrade
contractGrades c =
  [ MkTaggedGrade AlgHWM  c.stateGrade
  , MkTaggedGrade AlgLoss c.crossingLoss ]

||| The budget a clade declares in its config (via PanelClades.ABI.Budgets).
public export
budgetOf : DeclaredResources -> CladeBudget
budgetOf d = MkCladeBudget (budget d) (tolerance d)

||| The occupancy grade a clade declares (drift ≤ peak is checked here).
public export
declaredState : (d : DeclaredResources) -> {auto ok : So (lte (drift d) (peak d))} -> HWMGrade
declaredState d = MkHWM (peak d) (drift d) (fits (drift d) (peak d))

||| A clade's contract built from its config alone.  It typechecks exactly
||| when the declared peak fits the declared budget and the declared loss
||| fits the declared tolerance, with declared drift no greater than peak.
public export
declaredContract : (cladeId : String) -> (d : DeclaredResources)
                -> {auto okDrift : So (lte (drift d) (peak d))}
                -> {auto okState : So (lte (peak d) (budget d))}
                -> {auto okLoss  : So (lte (loss d) (tolerance d))}
                -> CladeResourceContract (budgetOf d)
declaredContract cladeId d =
  MkCladeResourceContract cladeId
    (declaredState d) (MkStateWithin (fits (peak d) (budget d)))
    (Finite (loss d)) (MkLossWithin (fits (loss d) (tolerance d)))

--------------------------------------------------------------------------------
-- One graded clade contract: neurosym-bridge (DESIGNED; values to confirm)
--------------------------------------------------------------------------------
--
-- neurosym-bridge (kind `bridge`) translates neural results (Panel-N) into
-- symbolic / world terms with confidence gating.  Its budgets are declared
-- in clades/neurosym-bridge/config.k9.ncl (`resources`), not here.

||| The graded contract, against neurosym-bridge's declared budget.
public export
neurosymBridgeContract : CladeResourceContract (budgetOf Budgets.neurosymBridge)
neurosymBridgeContract = declaredContract "neurosym-bridge" Budgets.neurosymBridge

--------------------------------------------------------------------------------
-- Occupancy is not cost, at the panel (resource-algebra S-1)
--------------------------------------------------------------------------------
--
-- Illustrative numbers, independent of any clade's config: a panel phase
-- that peaks at 48 and holds 16, run twice.

||| One illustrative phase.
public export
examplePhase : HWMGrade
examplePhase = MkHWM 48 16 (lteAddRight 16)

||| Two phases back to back fit 64: the second starts from the 16 units the
||| first still holds (16 + 48 = 64).
public export
exampleTwoPhases : StateWithin (hwmSeq Grades.examplePhase Grades.examplePhase) 64
exampleTwoPhases =
  phasesWithin {a = examplePhase} {b = examplePhase}
    (MkStateWithin (lteAddRight 48)) (lteRefl 64)

||| Occupancy of those two phases: 64 (the 32 freed between them are not
||| charged again)...
public export
panelPhasesOccupancy : peak (hwmSeq Grades.examplePhase Grades.examplePhase) = 64
panelPhasesOccupancy = Refl

||| ...whereas reading the same two phases as COST (max-plus) charges 96:
||| an occupancy budget must not be checked with a cost grade.
public export
panelPhasesCost : maxPlusSeq (Val 48) (Val 48) = Val 96
panelPhasesCost = Refl
