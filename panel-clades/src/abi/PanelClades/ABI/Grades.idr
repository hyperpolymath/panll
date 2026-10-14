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
||| kernel).  The contract for `neurosym-bridge` at the end is DESIGNED: its
||| budgets are declared values for the owner to confirm, not measurements,
||| and nothing in the panel runtime yet emits or checks these grades.
|||
||| No unsafe casts, postulates or totality escapes.  %default total.

module PanelClades.ABI.Grades

import Data.Nat
import TypedWasm.ABI.ResourceAlgebra
import TypedWasm.ABI.ResourceAlgebra.Nat
import TypedWasm.ABI.ResourceAlgebra.Loss
import TypedWasm.ABI.ResourceAlgebra.MaxPlus
import TypedWasm.ABI.ResourceAlgebra.HWM

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

||| max is the least upper bound (local: the pinned kernel predates
||| typed-wasm's `maxLub`; drop this when re-pinned past it).
maxLeast : {a, b, c : Nat} -> LTE a c -> LTE b c -> LTE (maximum a b) c
maxLeast LTEZero     q           = q
maxLeast (LTESucc p) LTEZero     = LTESucc p
maxLeast (LTESucc p) (LTESucc q) = LTESucc (maxLeast p q)

||| Two phases of a panel's life (e.g. before and after it transmutes): the
||| second starts from what the first still holds, so the run fits the
||| budget if the first phase does and the second fits in what the first
||| left.  This is the reclamation law (occupancy-types R-2) at the panel.
public export
phasesWithin : {a, b : HWMGrade} -> {m : Nat} ->
               StateWithin a m -> LTE (drift a + peak b) m ->
               StateWithin (hwmSeq a b) m
phasesWithin {a = MkHWM p1 n1 _} {b = MkHWM p2 n2 _} (MkStateWithin fits) after =
  MkStateWithin (maxLeast fits after)

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
-- The contract
--------------------------------------------------------------------------------

||| A clade's resource contract, graded in the kernel.
public export
record CladeResourceContract where
  constructor MkCladeResourceContract
  ||| The clade's id (its A2ML `clade-metadata.id`).
  cladeId       : String
  ||| Panel state over a run, as an occupancy grade (HWM).
  stateGrade    : HWMGrade
  ||| Declared state budget, in the panel's state units.
  stateBudget   : Nat
  ||| The state fits the budget.
  stateFits     : StateWithin stateGrade stateBudget
  ||| Loss on the Panel-N → Panel-W crossing (Loss).
  crossingLoss  : LossGrade
  ||| Declared loss tolerance for the crossing.
  lossTolerance : Nat
  ||| The crossing stays within tolerance.
  crossingFits  : LossWithin crossingLoss lossTolerance

||| The contract's two grades on the wire, each tagged with its algebra.
public export
contractGrades : CladeResourceContract -> List TaggedGrade
contractGrades c =
  [ MkTaggedGrade AlgHWM  c.stateGrade
  , MkTaggedGrade AlgLoss c.crossingLoss ]

--------------------------------------------------------------------------------
-- One graded clade contract: neurosym-bridge (DESIGNED; values to confirm)
--------------------------------------------------------------------------------
--
-- neurosym-bridge (kind `bridge`, clades/neurosym-bridge/NeurosymBridge.a2ml)
-- translates neural results (Panel-N) into symbolic / world terms with
-- confidence gating.  Declared, not measured: its panel state peaks at 48
-- units and holds 16 between inferences, within a budget of 64; the
-- crossing loses 2 (two gating stages may each drop a candidate), within a
-- tolerance of 3.

||| neurosym-bridge's panel state over one inference.
public export
neurosymState : HWMGrade
neurosymState = MkHWM 48 16 (lteAddRight 16)

||| The graded contract.
public export
neurosymBridgeContract : CladeResourceContract
neurosymBridgeContract = MkCladeResourceContract
  "neurosym-bridge"
  neurosymState 64 (MkStateWithin (lteAddRight 48))
  (Finite 2) 3 (MkLossWithin (lteAddRight 2))

||| Two inferences back to back stay within budget: the second starts from
||| the 16 units the first still holds (16 + 48 = 64 ≤ 64).
public export
neurosymTwoInferences : StateWithin (hwmSeq Grades.neurosymState Grades.neurosymState) 64
neurosymTwoInferences =
  phasesWithin {a = neurosymState} {b = neurosymState}
    (MkStateWithin (lteAddRight 48)) (lteRefl 64)

||| Occupancy of those two inferences: 64 (the 32 freed between them are
||| not charged again)...
public export
panelPhasesOccupancy : peak (hwmSeq Grades.neurosymState Grades.neurosymState) = 64
panelPhasesOccupancy = Refl

||| ...whereas reading the same two phases as COST (max-plus) charges 96:
||| an occupancy budget must not be checked with a cost grade.
public export
panelPhasesCost : maxPlusSeq (Val 48) (Val 48) = Val 96
panelPhasesCost = Refl
