-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
||| Memory Layout Proofs for PanLL Panel-Clades
|||
||| Alignment and struct layout for the C-compatible structs of the
||| panel-clades ABI.
|||
||| What is proved:
|||
|||   * rounding up to an alignment a ≥ 1 is tight: it lands on a multiple
|||     of a (`alignUpCorrect`), at or above the size (`alignUpCovers`) and
|||     below size + a (`alignUpTight`);
|||   * a computed struct size is a multiple of its alignment
|||     (`calcStructSizeAligned`) and covers every field
|||     (`calcStructSizeCovers`, `fieldWithinStruct`), so `verifyLayout`
|||     needs no run-time size check;
|||   * C layout evidence (`CABICompliant`) carries, for every field, an
|||     offset that is a multiple of its alignment (`FieldsAligned`), at
|||     least one field, the first at offset 0 (`FirstAtZero`), fields in
|||     order and not overlapping (`FieldsOrdered`), alignments that are
|||     powers of two (`AlignmentsPow2`), and a struct alignment equal to
|||     the largest field alignment (`maxAlignment`).  Each is decided by an
|||     equation or an `LTE` proof, never by a Boolean test followed by an
|||     unproved `Refl`.
|||
||| What is NOT proved: that a Zig or C compiler lays a struct out this way.
||| The evidence says a layout follows the C rules; matching the Zig side is
||| a separate check (PROOF-NEEDS.adoc, "Zig/Idris FFI agreement").
|||
||| @see https://en.wikipedia.org/wiki/Data_structure_alignment

module PanelClades.ABI.Layout

import PanelClades.ABI.Types
import Data.Either
import Data.List
import Data.List.Elem
import Data.Nat
import Data.So
import Decidable.Equality

%default total

--------------------------------------------------------------------------------
-- Nat lemmas (local, so this module imports nothing beyond base)
--------------------------------------------------------------------------------

lteR : (n : Nat) -> LTE n n
lteR Z     = LTEZero
lteR (S n) = LTESucc (lteR n)

lteT : LTE a b -> LTE b c -> LTE a c
lteT LTEZero     _           = LTEZero
lteT (LTESucc p) (LTESucc q) = LTESucc (lteT p q)

lteEqL : a = b -> LTE b c -> LTE a c
lteEqL Refl p = p

lteEqR : LTE a b -> b = c -> LTE a c
lteEqR p Refl = p

||| k - u never exceeds k.
minusLteSelf : (k, u : Nat) -> LTE (k `minus` u) k
minusLteSelf Z     _     = LTEZero
minusLteSelf (S k) Z     = lteR (S k)
minusLteSelf (S k) (S u) = lteSuccRight (minusLteSelf k u)

||| k fits in u plus what k has left over u.
lteMinusPlus : (k, u : Nat) -> LTE k (u + (k `minus` u))
lteMinusPlus Z     _     = LTEZero
lteMinusPlus (S k) Z     = lteR (S k)
lteMinusPlus (S k) (S u) = LTESucc (lteMinusPlus k u)

||| When k ≤ u, k - u is 0.
minusLteZero : (k, u : Nat) -> LTE k u -> k `minus` u = Z
minusLteZero Z     _     _           = Refl
minusLteZero (S k) (S u) (LTESucc p) = minusLteZero k u p
minusLteZero (S _) Z     LTEZero impossible

||| Adding back what was taken off.
addBack : (u, k, t : Nat) -> LTE u k -> u + ((k `minus` u) + t) = k + t
addBack u k t le =
  rewrite plusAssociative u (k `minus` u) t in
  rewrite plusCommutative u (k `minus` u) in
  rewrite plusMinusLte u k le in
  Refl

--------------------------------------------------------------------------------
-- Alignment Utilities
--------------------------------------------------------------------------------

||| `Divides n m`: m is k times n, for an explicit k.
public export
data Divides : Nat -> Nat -> Type where
  DivideBy : (k : Nat) -> {n : Nat} -> {m : Nat} -> (m = k * n) -> Divides n m

||| Units of `unit` bytes needed to cover `size` bytes, counting down a
||| fuel bound.  Structural, so it computes during type checking (Nat `div`
||| does not).  With fuel ≥ size and unit ≥ 1 the fuel never runs out.
||| The result is capped at fuel; for unit = 0 and size > 0 it is fuel.
public export
unitsFor : (fuel : Nat) -> (size : Nat) -> (unit : Nat) -> Nat
unitsFor Z        _     _    = Z
unitsFor (S _)    Z     _    = Z
unitsFor (S fuel) (S k) unit = S (unitsFor fuel (S k `minus` unit) unit)

||| How many alignment units are needed to cover `size` bytes (ceiling
||| division; 0 units when the alignment is 0).
public export
alignUnits : (size : Nat) -> (alignment : Nat) -> Nat
alignUnits _    Z         = Z
alignUnits size (S align) = unitsFor size size (S align)

||| Round up to the next alignment boundary: a whole number of units.
||| Returns a byte count, unchanged when already aligned, or 0 when
||| the alignment is 0.
public export
alignUp : (size : Nat) -> (alignment : Nat) -> Nat
alignUp size alignment = alignUnits size alignment * alignment

||| Padding needed after `offset` to reach the next boundary.
||| Returns bytes; 0 when already aligned or when the alignment is 0.
public export
paddingFor : (offset : Nat) -> (alignment : Nat) -> Nat
paddingFor offset alignment = alignUp offset alignment `minus` offset

||| `alignUp` always produces a multiple of the alignment.  This holds by
||| construction (alignUp is defined as units × alignment), for every
||| alignment including 0.  `alignUpCovers` and `alignUpTight` are the
||| properties that carry weight.
public export
alignUpCorrect : (size : Nat) -> (align : Nat) -> Divides align (alignUp size align)
alignUpCorrect size align = DivideBy (alignUnits size align) Refl

||| With enough fuel, the units cover the size.
unitsCover : (fuel, size, u : Nat) -> LTE size fuel
          -> LTE size (unitsFor fuel size (S u) * S u)
unitsCover _     Z     _ _   = LTEZero
unitsCover Z     (S k) _ prf = void (succNotLTEzero prf)
unitsCover (S f) (S k) u prf =
  let ih = unitsCover f (k `minus` u) u (lteT (minusLteSelf k u) (fromLteSucc prf))
  in LTESucc (lteT (lteMinusPlus k u) (plusLteMonotoneLeft u _ _ ih))

||| Units for nothing are none, whatever the fuel.
unitsZero : (fuel, unit : Nat) -> unitsFor fuel Z unit = Z
unitsZero Z     _ = Refl
unitsZero (S _) _ = Refl

||| With enough fuel, the units overshoot the size by less than one unit.
unitsTight : (fuel, size, u : Nat) -> LTE size fuel
          -> LT (unitsFor fuel size (S u) * S u) (size + S u)
unitsTight Z     Z     _ _   = LTESucc LTEZero
unitsTight (S _) Z     _ _   = LTESucc LTEZero
unitsTight Z     (S k) _ prf = void (succNotLTEzero prf)
unitsTight (S f) (S k) u prf with (isLTE u k)
  _ | Yes le =
    let ih   = unitsTight f (k `minus` u) u (lteT (minusLteSelf k u) (fromLteSucc prf))
        step = plusLteMonotoneLeft u _ _ ih
    in LTESucc (lteEqL (plusSuccRightSucc u _) (lteEqR step (addBack u k (S u) le)))
  _ | No gt =
    rewrite minusLteZero k u (lteSuccLeft (notLTEImpliesGT gt)) in
    rewrite unitsZero f (S u) in
    LTESucc (lteEqL (cong S (plusZeroRightNeutral u))
                    (lteEqR (lteAddRight (S u)) (plusCommutative (S u) k)))

||| Rounding up to an alignment of at least 1 never lands below the size.
export
alignUpCovers : (size, u : Nat) -> LTE size (alignUp size (S u))
alignUpCovers size u = unitsCover size size u (lteR size)

||| Rounding up to an alignment a ≥ 1 adds less than a: it is the least
||| multiple of a at or above the size.
export
alignUpTight : (size, u : Nat) -> LT (alignUp size (S u)) (size + S u)
alignUpTight size u = unitsTight size size u (lteR size)

||| Decide whether n divides m, returning the witness when it does.  The
||| candidate quotient is the ceiling quotient (equal to the exact one
||| whenever n divides m), then the equation is checked with Nat's
||| structural decidable equality, so a `Just` always carries a true
||| equation.  `Nothing` means "not shown to divide".
public export
decDivides : (n, m : Nat) -> Maybe (Divides n m)
decDivides n m =
  case decEq m (alignUnits m n * n) of
    Yes prf => Just (DivideBy (alignUnits m n) prf)
    No _    => Nothing

||| `n` is a power of two: 1, or twice a power of two.
public export
data IsPow2 : Nat -> Type where
  Pow2One    : IsPow2 1
  Pow2Double : IsPow2 n -> IsPow2 (n + n)

||| Decide whether n is a power of two by doubling from 1.  A `Just`
||| always carries a real `IsPow2` witness; `Nothing` means "not shown".
||| n + 1 doublings are more than enough fuel.
public export
decPow2 : (n : Nat) -> Maybe (IsPow2 n)
decPow2 n = go (S n) 1 Pow2One
  where
    go : (fuel : Nat) -> (p : Nat) -> IsPow2 p -> Maybe (IsPow2 n)
    go Z     _ _  = Nothing
    go (S f) p pf = case decEq p n of
      Yes same => Just (replace {p = IsPow2} same pf)
      No _     => if lte p n then go f (p + p) (Pow2Double pf) else Nothing

--------------------------------------------------------------------------------
-- Struct Field Layout
--------------------------------------------------------------------------------

||| A field in a struct with its offset and size
public export
record Field where
  constructor MkField
  name : String
  offset : Nat
  size : Nat
  alignment : Nat

||| The byte just past a field
public export
fieldEnd : Field -> Nat
fieldEnd f = f.offset + f.size

||| Calculate the offset of the next field after this one
public export
nextFieldOffset : Field -> Nat
nextFieldOffset f = alignUp (fieldEnd f) f.alignment

||| The greatest field end offset in bytes, or 0 for an empty list.
||| (Structural, with Data.Nat's `maximum`, so the lemmas below can reason
||| about it; it computes the same value as the earlier `max` fold.)
public export
structEnd : List Field -> Nat
structEnd []        = 0
structEnd (f :: fs) = maximum (fieldEnd f) (structEnd fs)

||| Every field ends at or before the struct's last field end.
export
fieldWithinEnd : (fs : List Field) -> Elem f fs -> LTE (fieldEnd f) (structEnd fs)
fieldWithinEnd (f :: fs) Here      = maximumLeftUpperBound (fieldEnd f) (structEnd fs)
fieldWithinEnd (g :: fs) (There e) =
  lteT (fieldWithinEnd fs e) (maximumRightUpperBound (fieldEnd g) (structEnd fs))

||| Total struct size: the furthest field end, rounded up to the struct's
||| alignment.  (Fields carry explicit offsets, so this is the C rule; the
||| earlier fold here ignored its accumulator and mixed up which field it
||| measured.)
||| Returns bytes; 0 for an empty field list or an alignment of 0.
public export
calcStructSize : List Field -> Nat -> Nat
calcStructSize fields align = alignUp (structEnd fields) align

||| Every computed struct size is a multiple of the struct alignment.
public export
calcStructSizeAligned : (fields : List Field) -> (align : Nat)
                     -> Divides align (calcStructSize fields align)
calcStructSizeAligned fields align = alignUpCorrect (structEnd fields) align

||| With an alignment of at least 1, the computed struct size covers every
||| field.
export
calcStructSizeCovers : (fields : List Field) -> (u : Nat)
                    -> LTE (structEnd fields) (calcStructSize fields (S u))
calcStructSizeCovers fields u = alignUpCovers (structEnd fields) u

||| A struct layout: its fields, its size and alignment, a proof that the
||| size covers the fields, and a proof that the size is a multiple of the
||| alignment.
public export
record StructLayout where
  constructor MkStructLayout
  fields : List Field
  totalSize : Nat
  alignment : Nat
  0 covers : LTE (structEnd fields) totalSize
  0 aligned : Divides alignment totalSize

||| Every field of a layout lies within its total size.
export
0 fieldWithinStruct : (layout : StructLayout) -> Elem f layout.fields
                   -> LTE (fieldEnd f) layout.totalSize
fieldWithinStruct layout e = lteT (fieldWithinEnd layout.fields e) layout.covers

||| Proof that every field's offset is a multiple of its alignment
public export
data FieldsAligned : List Field -> Type where
  NoFields : FieldsAligned []
  ConsField :
    (f : Field) ->
    (rest : List Field) ->
    Divides f.alignment f.offset ->
    FieldsAligned rest ->
    FieldsAligned (f :: rest)

||| Build a layout whose size is computed from its fields.  The size is
||| proved to cover the fields and to be a multiple of the alignment, so
||| the only refusal is an alignment of 0, which no C type has.
||| Field offsets and the C rules are checked separately by `checkCABI`.
public export
verifyLayout : (fields : List Field) -> (align : Nat) -> Either String StructLayout
verifyLayout _      Z     = Left "Alignment 0 is not a C alignment"
verifyLayout fields (S u) =
  Right (MkStructLayout fields (calcStructSize fields (S u)) (S u)
           (calcStructSizeCovers fields u) (calcStructSizeAligned fields (S u)))

--------------------------------------------------------------------------------
-- C ABI Compatibility
--------------------------------------------------------------------------------

||| The struct has at least one field, and the first starts at offset 0.
||| A C struct needs a member (C11 6.7.2.1p8: one with no named member is
||| undefined), and C allows padding between members and after the last,
||| never before the first (6.7.2.1p15).  There is no evidence for `[]`.
public export
data FirstAtZero : List Field -> Type where
  ZeroHead : f.offset = 0 -> FirstAtZero (f :: rest)

||| Fields in declaration order, each starting at or after the end of the
||| one before, so no two overlap.
public export
data FieldsOrdered : List Field -> Type where
  OrdNil  : FieldsOrdered []
  OrdOne  : FieldsOrdered [f]
  OrdCons : LTE (fieldEnd f) g.offset -> FieldsOrdered (g :: rest)
         -> FieldsOrdered (f :: g :: rest)

||| Every field's alignment is a power of two.
public export
data AlignmentsPow2 : List Field -> Type where
  Pow2Nil  : AlignmentsPow2 []
  Pow2Cons : IsPow2 f.alignment -> AlignmentsPow2 rest -> AlignmentsPow2 (f :: rest)

||| The C struct alignment: the largest field alignment, or 1 for no fields.
public export
maxAlignment : List Field -> Nat
maxAlignment []        = 1
maxAlignment (f :: fs) = maximum f.alignment (maxAlignment fs)

||| Proof that a struct follows the C layout rules: every field offset is
||| a multiple of its alignment, there is a field and the first is at
||| offset 0, the fields are in order and do not overlap, every alignment is
||| a power of two, and the struct is aligned to its largest field
||| alignment.  (Size covering the fields, and being a
||| multiple of the alignment, are carried by `StructLayout` itself.)
public export
data CABICompliant : StructLayout -> Type where
  CABIOk :
    (layout : StructLayout) ->
    FieldsAligned layout.fields ->
    FirstAtZero layout.fields ->
    FieldsOrdered layout.fields ->
    AlignmentsPow2 layout.fields ->
    layout.alignment = maxAlignment layout.fields ->
    CABICompliant layout

||| Attempt to prove all fields are correctly aligned.  Returns `Left`
||| naming the first field whose offset is not shown to be a multiple of
||| its alignment.
public export
proveFieldsAligned : (fields : List Field) -> Either String (FieldsAligned fields)
proveFieldsAligned [] = Right NoFields
proveFieldsAligned (f :: rest) =
  case decDivides f.alignment f.offset of
    Nothing => Left ("Field " ++ f.name ++ " at offset " ++ show f.offset
                     ++ " not aligned to " ++ show f.alignment)
    Just here =>
      case proveFieldsAligned rest of
        Left err => Left err
        Right restProof => Right (ConsField f rest here restProof)

||| Attempt to prove there is a field and the first is at offset 0.
public export
proveFirstAtZero : (fields : List Field) -> Either String (FirstAtZero fields)
proveFirstAtZero []       = Left "A C struct needs at least one member"
proveFirstAtZero (f :: _) =
  case decEq f.offset 0 of
    No _    => Left ("First field " ++ f.name ++ " is at offset "
                     ++ show f.offset ++ ", not 0")
    Yes zero => Right (ZeroHead zero)

||| Attempt to prove the fields are in order and do not overlap.  Returns
||| `Left` naming the first field that starts before the previous one ends.
public export
proveFieldsOrdered : (fields : List Field) -> Either String (FieldsOrdered fields)
proveFieldsOrdered []  = Right OrdNil
proveFieldsOrdered [_] = Right OrdOne
proveFieldsOrdered (f :: g :: rest) =
  case isLTE (fieldEnd f) g.offset of
    No _    => Left ("Field " ++ g.name ++ " at offset " ++ show g.offset
                     ++ " overlaps " ++ f.name ++ ", which ends at "
                     ++ show (fieldEnd f))
    Yes fit =>
      case proveFieldsOrdered (g :: rest) of
        Left err => Left err
        Right restProof => Right (OrdCons fit restProof)

||| Attempt to prove every field alignment is a power of two.
public export
proveAlignmentsPow2 : (fields : List Field) -> Either String (AlignmentsPow2 fields)
proveAlignmentsPow2 [] = Right Pow2Nil
proveAlignmentsPow2 (f :: rest) =
  case decPow2 f.alignment of
    Nothing => Left ("Field " ++ f.name ++ " has alignment "
                     ++ show f.alignment ++ ", not a power of two")
    Just p =>
      case proveAlignmentsPow2 rest of
        Left err => Left err
        Right restProof => Right (Pow2Cons p restProof)

||| Return C layout evidence for a layout, or the first rule it breaks.
public export
checkCABI : (layout : StructLayout) -> Either String (CABICompliant layout)
checkCABI layout = do
  aligned <- proveFieldsAligned layout.fields
  first   <- proveFirstAtZero layout.fields
  ordered <- proveFieldsOrdered layout.fields
  pow2    <- proveAlignmentsPow2 layout.fields
  case decEq layout.alignment (maxAlignment layout.fields) of
    No _ => Left ("Struct alignment " ++ show layout.alignment
                  ++ " is not the largest field alignment "
                  ++ show (maxAlignment layout.fields))
    Yes same => Right (CABIOk layout aligned first ordered pow2 same)

--------------------------------------------------------------------------------
-- Platform-Specific Layouts
--------------------------------------------------------------------------------

||| Struct layout may differ by platform
public export
PlatformLayout : Platform -> Type -> Type
PlatformLayout _ _ = StructLayout

||| Check a per-platform layout on every platform in `allPlatforms`
||| (this used to return `Right ()` without looking).
||| Returns Right () if all pass, or the first `checkCABI` error in that order.
public export
verifyAllPlatforms :
  (layouts : (p : Platform) -> PlatformLayout p t) ->
  Either String ()
verifyAllPlatforms layouts = go allPlatforms
  where
    ||| Check the remaining platforms, stopping at the first C-rule error.
    go : List Platform -> Either String ()
    go [] = Right ()
    go (p :: ps) = case checkCABI (layouts p) of
      Left err => Left err
      Right _  => go ps

--------------------------------------------------------------------------------
-- Example Layouts
--------------------------------------------------------------------------------

||| An LTE proof found by evaluation, for closed numbers: `lte m n`
||| reduces, so the `So` is found automatically, and numbers that do not
||| fit have no `So True` and fail the typecheck at the use site.
public export
fitsIn : (m, n : Nat) -> {auto ok : So (lte m n)} -> LTE m n
fitsIn m n {ok} = lteReflectsLTE m n (soToEq ok)

||| The example struct's fields: a u32, then a u64 and a double, each on
||| its natural boundary (4 bytes of padding after x).
public export
exampleFields : List Field
exampleFields =
  [ MkField "x" 0 4 4     -- Bits32 at offset 0
  , MkField "y" 8 8 8     -- Bits64 at offset 8 (4 bytes padding)
  , MkField "z" 16 8 8    -- Double at offset 16
  ]

||| Example: simple struct layout, 24 bytes, 8-byte aligned (24 = 3 × 8),
||| covering its last field end (16 + 8 = 24).
public export
exampleLayout : StructLayout
exampleLayout = MkStructLayout exampleFields 24 8 (fitsIn 24 24) (DivideBy 3 Refl)

||| The computed size agrees with the declared one.
export
exampleSizeComputed : calcStructSize PanelClades.ABI.Layout.exampleFields 8 = 24
exampleSizeComputed = Refl

||| Proof that example layout's fields are aligned:
|||   x: 0 = 0 × 4,  y: 8 = 1 × 8,  z: 16 = 2 × 8
export
exampleFieldsAligned : FieldsAligned PanelClades.ABI.Layout.exampleFields
exampleFieldsAligned =
  ConsField (MkField "x" 0 4 4) [MkField "y" 8 8 8, MkField "z" 16 8 8]
    (DivideBy 0 Refl)
    (ConsField (MkField "y" 8 8 8) [MkField "z" 16 8 8]
      (DivideBy 1 Refl)
      (ConsField (MkField "z" 16 8 8) []
        (DivideBy 2 Refl)
        NoFields))

||| The example's fields are in order: x ends at 4 ≤ 8, y ends at 16 ≤ 16.
export
exampleFieldsOrdered : FieldsOrdered PanelClades.ABI.Layout.exampleFields
exampleFieldsOrdered = OrdCons (fitsIn 4 8) (OrdCons (fitsIn 16 16) OrdOne)

||| The example's alignments are 4 = 2 × 2 and 8 = 2 × 4.
export
exampleAlignmentsPow2 : AlignmentsPow2 PanelClades.ABI.Layout.exampleFields
exampleAlignmentsPow2 = Pow2Cons four (Pow2Cons eight (Pow2Cons eight Pow2Nil))
  where
    four : IsPow2 4
    four = Pow2Double (Pow2Double Pow2One)
    eight : IsPow2 8
    eight = Pow2Double four

||| The example layout follows the C rules: aligned, first field at 0,
||| ordered, power-of-two
||| alignments, and struct alignment 8, its largest field alignment.
export
exampleLayoutValid : CABICompliant PanelClades.ABI.Layout.exampleLayout
exampleLayoutValid =
  CABIOk exampleLayout exampleFieldsAligned (ZeroHead Refl)
         exampleFieldsOrdered exampleAlignmentsPow2 Refl

||| The decision procedure agrees on the example.
export
exampleCheckPasses : isRight (checkCABI PanelClades.ABI.Layout.exampleLayout) = True
exampleCheckPasses = Refl

--------------------------------------------------------------------------------
-- Field lookup
--------------------------------------------------------------------------------

||| Find a field by name.
||| Returns the first exact match, or Nothing if no field has that name.
public export
lookupField : (layout : StructLayout) -> (fieldName : String) -> Maybe Field
lookupField layout name = find (\f => f.name == name) layout.fields

||| Run-time check that a field's span `[offset, offset+size)` fits inside
||| the struct.  For a field of the layout this always holds
||| (`fieldWithinStruct`); it remains for fields from elsewhere.
public export
offsetInBounds : (layout : StructLayout) -> (f : Field) -> Bool
offsetInBounds layout f = fieldEnd f <= layout.totalSize
