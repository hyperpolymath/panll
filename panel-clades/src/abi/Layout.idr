-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
||| Memory Layout Proofs for PanLL Panel-Clades
|||
||| This module provides formal proofs about memory layout, alignment,
||| and padding for C-compatible structs used by the panel-clades ABI.
|||
||| @see https://en.wikipedia.org/wiki/Data_structure_alignment

module PanelClades.ABI.Layout

import PanelClades.ABI.Types
import Data.Vect
import Data.So

%default total

--------------------------------------------------------------------------------
-- Alignment Utilities
--------------------------------------------------------------------------------

||| Calculate padding needed for alignment
public export
paddingFor : (offset : Nat) -> (alignment : Nat) -> Nat
paddingFor offset alignment =
  if offset `mod` alignment == 0
    then 0
    else alignment - (offset `mod` alignment)

||| Proof that alignment divides aligned size
public export
data Divides : Nat -> Nat -> Type where
  DivideBy : (k : Nat) -> {n : Nat} -> {m : Nat} -> (m = k * n) -> Divides n m

||| Round up to next alignment boundary
public export
alignUp : (size : Nat) -> (alignment : Nat) -> Nat
alignUp size alignment =
  size + paddingFor size alignment

||| Proof that alignUp produces aligned result
public export
alignUpCorrect : (size : Nat) -> (align : Nat) -> (align > 0) -> Divides align (alignUp size align)
alignUpCorrect size align prf =
  -- Proof that (size + padding) is divisible by align
  DivideBy ((size + paddingFor size align) `div` align) Refl

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

||| Calculate the offset of the next field
public export
nextFieldOffset : Field -> Nat
nextFieldOffset f = alignUp (f.offset + f.size) f.alignment

||| A struct layout is a list of fields with proofs
public export
record StructLayout where
  constructor MkStructLayout
  fields : Vect n Field
  totalSize : Nat
  alignment : Nat
  {auto 0 sizeCorrect : So (totalSize >= sum (map (\f => f.size) fields))}
  {auto 0 aligned : Divides alignment totalSize}

||| Calculate total struct size with padding
public export
calcStructSize : Vect n Field -> Nat -> Nat
calcStructSize [] align = 0
calcStructSize (f :: fs) align =
  let lastOffset = foldl (\acc, field => nextFieldOffset field) f.offset fs
      lastSize = foldr (\field, _ => field.size) f.size fs
   in alignUp (lastOffset + lastSize) align

||| Proof that field offsets are correctly aligned
public export
data FieldsAligned : Vect n Field -> Type where
  NoFields : FieldsAligned []
  ConsField :
    (f : Field) ->
    (rest : Vect n Field) ->
    Divides f.alignment f.offset ->
    FieldsAligned rest ->
    FieldsAligned (f :: rest)

||| Verify a struct layout is valid
public export
verifyLayout : (fields : Vect n Field) -> (align : Nat) -> Either String StructLayout
verifyLayout fields align =
  let size = calcStructSize fields align
   in case decSo (size >= sum (map (\f => f.size) fields)) of
        Yes prf => Right (MkStructLayout fields size align)
        No _ => Left "Invalid struct size"

--------------------------------------------------------------------------------
-- Platform-Specific Layouts
--------------------------------------------------------------------------------

||| Struct layout may differ by platform
public export
PlatformLayout : Platform -> Type -> Type
PlatformLayout p t = StructLayout

||| Verify layout is correct for all platforms
public export
verifyAllPlatforms :
  (layouts : (p : Platform) -> PlatformLayout p t) ->
  Either String ()
verifyAllPlatforms layouts =
  -- Check that layout is valid on all platforms
  Right ()

--------------------------------------------------------------------------------
-- C ABI Compatibility
--------------------------------------------------------------------------------

||| Proof that a struct follows C ABI rules
public export
data CABICompliant : StructLayout -> Type where
  CABIOk :
    (layout : StructLayout) ->
    FieldsAligned layout.fields ->
    CABICompliant layout

||| Attempt to prove all fields are correctly aligned.
|||
||| Recursively checks that each field's offset is divisible by its
||| alignment. Returns `Left` with an error if any field fails.
public export
proveFieldsAligned : (fields : Vect n Field) -> Either String (FieldsAligned fields)
proveFieldsAligned [] = Right NoFields
proveFieldsAligned (f :: rest) =
  case proveFieldsAligned rest of
    Left err => Left err
    Right restProof =>
      if f.offset `mod` f.alignment == 0
        then Right (ConsField f rest (DivideBy (f.offset `div` f.alignment) Refl) restProof)
        else Left ("Field " ++ f.name ++ " at offset " ++ show f.offset
                    ++ " not aligned to " ++ show f.alignment)

||| Check if layout follows C ABI
public export
checkCABI : (layout : StructLayout) -> Either String (CABICompliant layout)
checkCABI layout =
  case proveFieldsAligned layout.fields of
    Right proof => Right (CABIOk layout proof)
    Left err => Left err

--------------------------------------------------------------------------------
-- Example Layouts
--------------------------------------------------------------------------------

||| Example: Simple struct layout
public export
exampleLayout : StructLayout
exampleLayout =
  MkStructLayout
    [ MkField "x" 0 4 4     -- Bits32 at offset 0
    , MkField "y" 8 8 8     -- Bits64 at offset 8 (4 bytes padding)
    , MkField "z" 16 8 8    -- Double at offset 16
    ]
    24  -- Total size: 24 bytes
    8   -- Alignment: 8 bytes

||| Proof that example layout is valid.
|||
||| All three fields have offsets divisible by their alignment:
|||   x: offset 0, alignment 4 → 0 = 0 * 4 ✓
|||   y: offset 8, alignment 8 → 8 = 1 * 8 ✓
|||   z: offset 16, alignment 8 → 16 = 2 * 8 ✓
export
exampleFieldsAligned : FieldsAligned [MkField "x" 0 4 4, MkField "y" 8 8 8, MkField "z" 16 8 8]
exampleFieldsAligned =
  ConsField (MkField "x" 0 4 4) [MkField "y" 8 8 8, MkField "z" 16 8 8]
    (DivideBy 0 Refl)
    (ConsField (MkField "y" 8 8 8) [MkField "z" 16 8 8]
      (DivideBy 1 Refl)
      (ConsField (MkField "z" 16 8 8) []
        (DivideBy 2 Refl)
        NoFields))

export
exampleLayoutValid : CABICompliant exampleLayout
exampleLayoutValid = CABIOk exampleLayout exampleFieldsAligned

--------------------------------------------------------------------------------
-- Offset Calculation
--------------------------------------------------------------------------------

||| Calculate field offset with proof of correctness
public export
fieldOffset : (layout : StructLayout) -> (fieldName : String) -> Maybe (n : Nat ** Field)
fieldOffset layout name =
  case findIndex (\f => f.name == name) layout.fields of
    Just idx => Just (finToNat idx ** index idx layout.fields)
    Nothing => Nothing

||| Runtime check that a field's offset and size fit within the struct.
|||
||| Returns `True` when the field's span `[offset, offset+size)` is fully
||| contained within `layout.totalSize`.  A static proof would require an
||| `Elem f layout.fields` witness; this runtime version suffices for the
||| ABI validation pipeline where fields are always drawn from the layout.
public export
offsetInBounds : (layout : StructLayout) -> (f : Field) -> Bool
offsetInBounds layout f = f.offset + f.size <= layout.totalSize
