-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
||| Memory Layout Proofs for PanLL Panel-Clades
|||
||| Alignment and struct layout for the C-compatible structs of the
||| panel-clades ABI.
|||
||| What is proved: rounding up to an alignment always lands on a multiple
||| of it (`alignUpCorrect`, by construction), every computed struct size
||| is a multiple of its alignment (`calcStructSizeAligned`), and every
||| `Divides` / `FieldsAligned` witness is a real equation.  Field
||| alignment is decided by an equation on Nat (`decDivides`), not by a
||| Boolean test followed by an unproved `Refl`.
|||
||| What is NOT proved: that a computed size is at least the end of the
||| last field.  `verifyLayout` checks that at run time, and refuses a
||| layout that fails it.
|||
||| @see https://en.wikipedia.org/wiki/Data_structure_alignment

module PanelClades.ABI.Layout

import PanelClades.ABI.Types
import Data.List
import Data.So
import Decidable.Equality

%default total

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
public export
alignUp : (size : Nat) -> (alignment : Nat) -> Nat
alignUp size alignment = alignUnits size alignment * alignment

||| Padding needed after `offset` to reach the next boundary.
public export
paddingFor : (offset : Nat) -> (alignment : Nat) -> Nat
paddingFor offset alignment = alignUp offset alignment `minus` offset

||| `alignUp` always produces a multiple of the alignment.  This holds by
||| construction (alignUp is defined as units × alignment), for every
||| alignment including 0.
public export
alignUpCorrect : (size : Nat) -> (align : Nat) -> Divides align (alignUp size align)
alignUpCorrect size align = DivideBy (alignUnits size align) Refl

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

||| The furthest byte any field reaches
public export
structEnd : List Field -> Nat
structEnd = foldr (\f, acc => max (fieldEnd f) acc) 0

||| Total struct size: the furthest field end, rounded up to the struct's
||| alignment.  (Fields carry explicit offsets, so this is the C rule; the
||| earlier fold here ignored its accumulator and mixed up which field it
||| measured.)
public export
calcStructSize : List Field -> Nat -> Nat
calcStructSize fields align = alignUp (structEnd fields) align

||| Every computed struct size is a multiple of the struct alignment.
public export
calcStructSizeAligned : (fields : List Field) -> (align : Nat)
                     -> Divides align (calcStructSize fields align)
calcStructSizeAligned fields align = alignUpCorrect (structEnd fields) align

||| A struct layout: its fields, its size and alignment, a check that the
||| size covers the fields, and a proof that the size is a multiple of the
||| alignment.
public export
record StructLayout where
  constructor MkStructLayout
  fields : List Field
  totalSize : Nat
  alignment : Nat
  {auto 0 sizeCorrect : So (totalSize >= structEnd fields)}
  0 aligned : Divides alignment totalSize

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

||| Build a layout whose size is computed from its fields; refused when
||| the computed size does not cover them.
public export
verifyLayout : (fields : List Field) -> (align : Nat) -> Either String StructLayout
verifyLayout fields align =
  case choose (calcStructSize fields align >= structEnd fields) of
    Left covers =>
      Right (MkStructLayout fields (calcStructSize fields align) align
               {sizeCorrect = covers} (calcStructSizeAligned fields align))
    Right _ => Left "Invalid struct size"

--------------------------------------------------------------------------------
-- C ABI Compatibility
--------------------------------------------------------------------------------

||| Proof that a struct follows C ABI rules (every field aligned)
public export
data CABICompliant : StructLayout -> Type where
  CABIOk :
    (layout : StructLayout) ->
    FieldsAligned layout.fields ->
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

||| Check if layout follows C ABI
public export
checkCABI : (layout : StructLayout) -> Either String (CABICompliant layout)
checkCABI layout =
  case proveFieldsAligned layout.fields of
    Right prf => Right (CABIOk layout prf)
    Left err => Left err

--------------------------------------------------------------------------------
-- Platform-Specific Layouts
--------------------------------------------------------------------------------

||| Struct layout may differ by platform
public export
PlatformLayout : Platform -> Type -> Type
PlatformLayout _ _ = StructLayout

||| Check a per-platform layout on every platform in `allPlatforms`
||| (this used to return `Right ()` without looking).
public export
verifyAllPlatforms :
  (layouts : (p : Platform) -> PlatformLayout p t) ->
  Either String ()
verifyAllPlatforms layouts = go allPlatforms
  where
    go : List Platform -> Either String ()
    go [] = Right ()
    go (p :: ps) = case checkCABI (layouts p) of
      Left err => Left err
      Right _  => go ps

--------------------------------------------------------------------------------
-- Example Layouts
--------------------------------------------------------------------------------

||| The example struct's fields: a u32, then a u64 and a double, each on
||| its natural boundary (4 bytes of padding after x).
public export
exampleFields : List Field
exampleFields =
  [ MkField "x" 0 4 4     -- Bits32 at offset 0
  , MkField "y" 8 8 8     -- Bits64 at offset 8 (4 bytes padding)
  , MkField "z" 16 8 8    -- Double at offset 16
  ]

||| Example: simple struct layout, 24 bytes, 8-byte aligned (24 = 3 × 8).
public export
exampleLayout : StructLayout
exampleLayout = MkStructLayout exampleFields 24 8 (DivideBy 3 Refl)

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

export
exampleLayoutValid : CABICompliant PanelClades.ABI.Layout.exampleLayout
exampleLayoutValid = CABIOk exampleLayout exampleFieldsAligned

--------------------------------------------------------------------------------
-- Field lookup
--------------------------------------------------------------------------------

||| Find a field by name.
public export
lookupField : (layout : StructLayout) -> (fieldName : String) -> Maybe Field
lookupField layout name = find (\f => f.name == name) layout.fields

||| Run-time check that a field's span `[offset, offset+size)` fits inside
||| the struct.
public export
offsetInBounds : (layout : StructLayout) -> (f : Field) -> Bool
offsetInBounds layout f = fieldEnd f <= layout.totalSize
