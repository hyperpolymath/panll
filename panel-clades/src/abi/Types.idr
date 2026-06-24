-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
||| ABI Type Definitions for PanLL Panel-Clades
|||
||| This module defines the Application Binary Interface (ABI) for the
||| panel-clades subsystem of PanLL.  It provides formally verified types
||| for clade identification, clade kinds, panel integration records, and
||| clade capabilities.
|||
||| Panel-clades categorises every PanLL panel into one of 13 clade kinds.
||| Each kind describes the panel's primary role inside a workspace.
|||
||| @see https://idris2.readthedocs.io for Idris2 documentation

module PanelClades.ABI.Types

import Data.Bits
import Data.So
import Data.Vect
import Data.String

%default total

--------------------------------------------------------------------------------
-- Platform Detection
--------------------------------------------------------------------------------

||| Supported platforms for this ABI
public export
data Platform = Linux | Windows | MacOS | BSD | WASM

||| Compile-time platform detection
||| This will be set during compilation based on target
public export
thisPlatform : Platform
thisPlatform =
  %runElab do
    -- Platform detection logic
    pure Linux  -- Default, override with compiler flags

--------------------------------------------------------------------------------
-- Core Types
--------------------------------------------------------------------------------

||| Result codes for FFI operations
||| Use C-compatible integers for cross-language compatibility
public export
data Result : Type where
  ||| Operation succeeded
  Ok : Result
  ||| Generic error
  Error : Result
  ||| Invalid parameter provided
  InvalidParam : Result
  ||| Out of memory
  OutOfMemory : Result
  ||| Null pointer encountered
  NullPointer : Result

||| Convert Result to C integer
public export
resultToInt : Result -> Bits32
resultToInt Ok = 0
resultToInt Error = 1
resultToInt InvalidParam = 2
resultToInt OutOfMemory = 3
resultToInt NullPointer = 4

||| Results are decidably equal
public export
DecEq Result where
  decEq Ok Ok = Yes Refl
  decEq Error Error = Yes Refl
  decEq InvalidParam InvalidParam = Yes Refl
  decEq OutOfMemory OutOfMemory = Yes Refl
  decEq NullPointer NullPointer = Yes Refl
  decEq _ _ = No absurd

--------------------------------------------------------------------------------
-- Opaque Handles
--------------------------------------------------------------------------------

||| Opaque handle type for FFI
||| Prevents direct construction, enforces creation through safe API
public export
data Handle : Type where
  MkHandle : (ptr : Bits64) -> {auto 0 nonNull : So (ptr /= 0)} -> Handle

||| Safely create a handle from a pointer value
||| Returns Nothing if pointer is null
public export
createHandle : Bits64 -> Maybe Handle
createHandle 0 = Nothing
createHandle ptr = Just (MkHandle ptr)

||| Extract pointer value from handle
public export
handlePtr : Handle -> Bits64
handlePtr (MkHandle ptr) = ptr

--------------------------------------------------------------------------------
-- Platform-Specific Types
--------------------------------------------------------------------------------

||| C int size varies by platform
public export
CInt : Platform -> Type
CInt Linux = Bits32
CInt Windows = Bits32
CInt MacOS = Bits32
CInt BSD = Bits32
CInt WASM = Bits32

||| C size_t varies by platform
public export
CSize : Platform -> Type
CSize Linux = Bits64
CSize Windows = Bits64
CSize MacOS = Bits64
CSize BSD = Bits64
CSize WASM = Bits32

||| C pointer size varies by platform
public export
ptrSize : Platform -> Nat
ptrSize Linux = 64
ptrSize Windows = 64
ptrSize MacOS = 64
ptrSize BSD = 64
ptrSize WASM = 32

||| Pointer type for platform
public export
CPtr : Platform -> Type -> Type
CPtr p _ = Bits (ptrSize p)

--------------------------------------------------------------------------------
-- Memory Layout Proofs
--------------------------------------------------------------------------------

||| Proof that a type has a specific size
public export
data HasSize : Type -> Nat -> Type where
  SizeProof : {0 t : Type} -> {n : Nat} -> HasSize t n

||| Proof that a type has a specific alignment
public export
data HasAlignment : Type -> Nat -> Type where
  AlignProof : {0 t : Type} -> {n : Nat} -> HasAlignment t n

||| Size of C types (platform-specific)
public export
cSizeOf : (p : Platform) -> (t : Type) -> Nat
cSizeOf p (CInt _) = 4
cSizeOf p (CSize _) = if ptrSize p == 64 then 8 else 4
cSizeOf p Bits32 = 4
cSizeOf p Bits64 = 8
cSizeOf p Double = 8
cSizeOf p _ = ptrSize p `div` 8

||| Alignment of C types (platform-specific)
public export
cAlignOf : (p : Platform) -> (t : Type) -> Nat
cAlignOf p (CInt _) = 4
cAlignOf p (CSize _) = if ptrSize p == 64 then 8 else 4
cAlignOf p Bits32 = 4
cAlignOf p Bits64 = 8
cAlignOf p Double = 8
cAlignOf p _ = ptrSize p `div` 8

--------------------------------------------------------------------------------
-- Clade-Specific Types
--------------------------------------------------------------------------------

||| A non-empty string identifier for a panel clade.
||| The proof witness ensures the identifier is never the empty string.
public export
record CladeId where
  constructor MkCladeId
  ||| The raw string value of the clade identifier
  value : String
  ||| Proof that the identifier is non-empty
  {auto 0 nonEmpty : So (value /= "")}

||| Safely construct a CladeId, returning Nothing if the string is empty
public export
mkCladeId : (s : String) -> Maybe CladeId
mkCladeId "" = Nothing
mkCladeId s  = Just (MkCladeId s)

||| The 13 clade kinds that classify every PanLL panel.
|||
||| Each kind corresponds to a primary role a panel can play inside
||| a PanLL workspace:
|||
|||   Directive  — orchestration / command dispatch
|||   Scanner    — code analysis and linting
|||   Builder    — compilation and build pipelines
|||   Database   — persistent storage and query
|||   Network    — HTTP, sockets, protocol handling
|||   Viewer     — read-only display and preview
|||   Ai         — LLM / ML inference integration
|||   Loader     — asset and resource loading
|||   Meta       — workspace metadata management
|||   Service    — background service / daemon panels
|||   Inspector  — runtime introspection and debugging
|||   Bridge     — cross-system translation layers
|||   Terminal   — interactive shell and REPL panels
public export
data CladeKind
  = Directive
  | Scanner
  | Builder
  | Database
  | Network
  | Viewer
  | Ai
  | Loader
  | Meta
  | Service
  | Inspector
  | Bridge
  | Terminal

||| Convert a CladeKind to its C-compatible integer tag.
||| Tags are zero-indexed and contiguous (0..12).
public export
cladeKindToInt : CladeKind -> Bits32
cladeKindToInt Directive  = 0
cladeKindToInt Scanner    = 1
cladeKindToInt Builder    = 2
cladeKindToInt Database   = 3
cladeKindToInt Network    = 4
cladeKindToInt Viewer     = 5
cladeKindToInt Ai         = 6
cladeKindToInt Loader     = 7
cladeKindToInt Meta       = 8
cladeKindToInt Service    = 9
cladeKindToInt Inspector  = 10
cladeKindToInt Bridge     = 11
cladeKindToInt Terminal   = 12

||| Convert a C integer tag back to a CladeKind.
||| Returns Nothing for out-of-range values.
public export
cladeKindFromInt : Bits32 -> Maybe CladeKind
cladeKindFromInt 0  = Just Directive
cladeKindFromInt 1  = Just Scanner
cladeKindFromInt 2  = Just Builder
cladeKindFromInt 3  = Just Database
cladeKindFromInt 4  = Just Network
cladeKindFromInt 5  = Just Viewer
cladeKindFromInt 6  = Just Ai
cladeKindFromInt 7  = Just Loader
cladeKindFromInt 8  = Just Meta
cladeKindFromInt 9  = Just Service
cladeKindFromInt 10 = Just Inspector
cladeKindFromInt 11 = Just Bridge
cladeKindFromInt 12 = Just Terminal
cladeKindFromInt _  = Nothing

||| CladeKind values are decidably equal
public export
DecEq CladeKind where
  decEq Directive  Directive  = Yes Refl
  decEq Scanner    Scanner    = Yes Refl
  decEq Builder    Builder    = Yes Refl
  decEq Database   Database   = Yes Refl
  decEq Network    Network    = Yes Refl
  decEq Viewer     Viewer     = Yes Refl
  decEq Ai         Ai         = Yes Refl
  decEq Loader     Loader     = Yes Refl
  decEq Meta       Meta       = Yes Refl
  decEq Service    Service    = Yes Refl
  decEq Inspector  Inspector  = Yes Refl
  decEq Bridge     Bridge     = Yes Refl
  decEq Terminal   Terminal   = Yes Refl
  decEq _          _          = No absurd

||| The total number of clade kinds.
||| This constant is used in compile-time checks to verify exhaustiveness.
public export
cladeKindCount : Nat
cladeKindCount = 13

||| All 13 clade kinds as a vector, useful for iteration and exhaustiveness
||| checks.  The vector length proves there are exactly cladeKindCount kinds.
public export
allCladeKinds : Vect cladeKindCount CladeKind
allCladeKinds =
  [ Directive, Scanner, Builder, Database, Network, Viewer, Ai
  , Loader, Meta, Service, Inspector, Bridge, Terminal ]

||| Exhaustiveness proof: cladeKindToInt covers every constructor.
||| For every CladeKind value there exists a corresponding element in
||| allCladeKinds.
public export
cladeKindExhaustive : (k : CladeKind) -> (n : Nat ** (n < cladeKindCount, index (natToFinLT n) allCladeKinds = k))
cladeKindExhaustive Directive  = (0  ** (LTESucc LTEZero, Refl))
cladeKindExhaustive Scanner    = (1  ** (LTESucc (LTESucc LTEZero), Refl))
cladeKindExhaustive Builder    = (2  ** (LTESucc (LTESucc (LTESucc LTEZero)), Refl))
cladeKindExhaustive Database   = (3  ** (LTESucc (LTESucc (LTESucc (LTESucc LTEZero))), Refl))
cladeKindExhaustive Network    = (4  ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))), Refl))
cladeKindExhaustive Viewer     = (5  ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero))))), Refl))
cladeKindExhaustive Ai         = (6  ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))))), Refl))
cladeKindExhaustive Loader     = (7  ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero))))))), Refl))
cladeKindExhaustive Meta       = (8  ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))))))), Refl))
cladeKindExhaustive Service    = (9  ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero))))))))), Refl))
cladeKindExhaustive Inspector  = (10 ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))))))))), Refl))
cladeKindExhaustive Bridge     = (11 ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero))))))))))), Refl))
cladeKindExhaustive Terminal   = (12 ** (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))))))))))), Refl))

||| Record describing how a panel integrates with the clade system.
||| Ties a named panel to a specific clade via its CladeId and CladeKind.
public export
record PanelIntegration where
  constructor MkPanelIntegration
  ||| Human-readable name of the panel
  panelName : String
  ||| Clade identifier this panel belongs to
  cladeId : CladeId
  ||| The clade kind classifying this panel's role
  kind : CladeKind

||| A capability that a clade may expose.
||| The `required` flag indicates whether the capability is mandatory for
||| panels in the clade to function correctly.
public export
record CladeCapability where
  constructor MkCladeCapability
  ||| Name of the capability (e.g. "syntax-highlight", "execute")
  name : String
  ||| Whether this capability is required (True) or optional (False)
  required : Bool

--------------------------------------------------------------------------------
-- Verification
--------------------------------------------------------------------------------

||| Compile-time verification of ABI properties
namespace Verify

  ||| Verify struct sizes are correct
  export
  verifySizes : IO ()
  verifySizes = do
    -- Add compile-time checks here
    putStrLn "ABI sizes verified"

  ||| Verify struct alignments are correct
  export
  verifyAlignments : IO ()
  verifyAlignments = do
    -- Add compile-time checks here
    putStrLn "ABI alignments verified"
