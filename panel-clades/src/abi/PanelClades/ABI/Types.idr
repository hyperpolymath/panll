-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
||| ABI Type Definitions for PanLL Panel-Clades
|||
||| This module defines the Application Binary Interface (ABI) for the
||| panel-clades subsystem of PanLL: clade identification, clade kinds,
||| panel integration records, clade capabilities, and the C types the
||| Zig FFI (`panel-clades/ffi/zig/`) exchanges.
|||
||| Panel-clades categorises every PanLL panel into one of 13 clade kinds.
||| Each kind describes the panel's primary role inside a workspace.
|||
||| What is proved here (checked by `panel-clades/scripts/check-abi.sh`):
|||   * the C tag encodings of `Result` and `CladeKind` round-trip, so they
|||     are injective (`resultRoundTrip`, `cladeKindRoundTrip`);
|||   * equality on both is decidable without a catch-all `absurd`;
|||   * `allCladeKinds` lists every kind (`cladeKindExhaustive`) and has
|||     length `cladeKindCount`;
|||   * a `Handle` is never null and a `CladeId` never empty, by
|||     construction.
||| What is NOT proved: that these sizes and tags are what the Zig side
||| actually uses.  `ffi/zig/src/main.zig` restates them by hand.

module PanelClades.ABI.Types

import Data.So
import Data.Vect
import Data.Vect.Elem
import Decidable.Equality

%default total

--------------------------------------------------------------------------------
-- Platform
--------------------------------------------------------------------------------

||| Supported platforms for this ABI
public export
data Platform = Linux | Windows | MacOS | BSD | WASM

||| Every platform, for checks that must hold on all of them.
public export
allPlatforms : List Platform
allPlatforms = [Linux, Windows, MacOS, BSD, WASM]

||| The platform these definitions are instantiated at.  A constant: there
||| is no target detection (an earlier `%runElab` here returned this same
||| constant and was described as detection).
public export
thisPlatform : Platform
thisPlatform = Linux

--------------------------------------------------------------------------------
-- Decidable equality through a retracted tag
--------------------------------------------------------------------------------

||| If `untag` is a left inverse of `tag`, then `tag` is injective and
||| equality is decided by comparing tags.  This replaces catch-all
||| `decEq _ _ = No absurd` clauses, which have no proof behind them.
public export
decEqViaTag : (tag : a -> Nat) -> (untag : Nat -> Maybe a)
           -> (retract : (x : a) -> untag (tag x) = Just x)
           -> (x, y : a) -> Dec (x = y)
decEqViaTag tag untag retract x y with (decEq (tag x) (tag y))
  _ | Yes same = Yes (injective (trans (sym (retract x)) (trans (cong untag same) (retract y))))
  _ | No diff  = No (\eq => diff (cong tag eq))

--------------------------------------------------------------------------------
-- Result codes
--------------------------------------------------------------------------------

||| Result codes for FFI operations (C-compatible integers)
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

||| The tag of a result code, as a natural number.
public export
resultTag : Result -> Nat
resultTag Ok           = 0
resultTag Error        = 1
resultTag InvalidParam = 2
resultTag OutOfMemory  = 3
resultTag NullPointer  = 4

public export
resultFromTag : Nat -> Maybe Result
resultFromTag 0 = Just Ok
resultFromTag 1 = Just Error
resultFromTag 2 = Just InvalidParam
resultFromTag 3 = Just OutOfMemory
resultFromTag 4 = Just NullPointer
resultFromTag _ = Nothing

public export
resultTagRetract : (r : Result) -> resultFromTag (resultTag r) = Just r
resultTagRetract Ok           = Refl
resultTagRetract Error        = Refl
resultTagRetract InvalidParam = Refl
resultTagRetract OutOfMemory  = Refl
resultTagRetract NullPointer  = Refl

||| Convert Result to its C integer
public export
resultToInt : Result -> Bits32
resultToInt Ok           = 0
resultToInt Error        = 1
resultToInt InvalidParam = 2
resultToInt OutOfMemory  = 3
resultToInt NullPointer  = 4

||| Convert a C integer back to a Result; Nothing for unknown codes.
public export
resultFromInt : Bits32 -> Maybe Result
resultFromInt 0 = Just Ok
resultFromInt 1 = Just Error
resultFromInt 2 = Just InvalidParam
resultFromInt 3 = Just OutOfMemory
resultFromInt 4 = Just NullPointer
resultFromInt _ = Nothing

||| The C encoding of a result code round-trips.
export
resultRoundTrip : (r : Result) -> resultFromInt (resultToInt r) = Just r
resultRoundTrip Ok           = Refl
resultRoundTrip Error        = Refl
resultRoundTrip InvalidParam = Refl
resultRoundTrip OutOfMemory  = Refl
resultRoundTrip NullPointer  = Refl

public export
DecEq Result where
  decEq = decEqViaTag resultTag resultFromTag resultTagRetract

--------------------------------------------------------------------------------
-- Opaque Handles
--------------------------------------------------------------------------------

||| Opaque handle type for FFI.  The erased witness makes a null handle
||| unconstructible; `createHandle` is the only way in.
public export
data Handle : Type where
  MkHandle : (ptr : Bits64) -> {0 nonNull : So (ptr /= 0)} -> Handle

||| Safely create a handle from a pointer value; Nothing if it is null.
public export
createHandle : Bits64 -> Maybe Handle
createHandle ptr = case choose (ptr /= 0) of
  Left nonNull => Just (MkHandle ptr {nonNull})
  Right _      => Nothing

||| Extract pointer value from handle
public export
handlePtr : Handle -> Bits64
handlePtr (MkHandle ptr) = ptr

--------------------------------------------------------------------------------
-- C types, as a closed universe
--------------------------------------------------------------------------------

||| The C types the ABI uses.  Sizes and alignments are functions of a
||| code, not of an Idris `Type`: Idris cannot pattern-match on types, so
||| an earlier `cSizeOf : Platform -> Type -> Nat` could not be written.
public export
data CType = CTInt | CTSize | CTU32 | CTU64 | CTDouble | CTPtr

||| C int width, by platform
public export
CInt : Platform -> Type
CInt _ = Bits32

||| C size_t width, by platform
public export
CSize : Platform -> Type
CSize WASM = Bits32
CSize _    = Bits64

||| Pointer width in bytes, by platform
public export
ptrBytes : Platform -> Nat
ptrBytes WASM = 4
ptrBytes _    = 8

||| Pointer width in bits, by platform
public export
ptrSize : Platform -> Nat
ptrSize p = 8 * ptrBytes p

||| A pointer crosses the C ABI as an unsigned integer of pointer width
||| (uintptr_t, which is size_t's width on every platform listed).  The
||| pointee type is a phantom.
public export
CPtr : Platform -> Type -> Type
CPtr p _ = CSize p

||| The Idris representation of each C type on a platform.
public export
interpC : Platform -> CType -> Type
interpC p CTInt    = CInt p
interpC p CTSize   = CSize p
interpC _ CTU32    = Bits32
interpC _ CTU64    = Bits64
interpC _ CTDouble = Double
interpC p CTPtr    = CPtr p ()

||| Size in bytes of a C type on a platform.
public export
cSizeOf : Platform -> CType -> Nat
cSizeOf _ CTInt    = 4
cSizeOf p CTSize   = ptrBytes p
cSizeOf _ CTU32    = 4
cSizeOf _ CTU64    = 8
cSizeOf _ CTDouble = 8
cSizeOf p CTPtr    = ptrBytes p

||| Alignment in bytes of a C type on a platform (natural alignment).
public export
cAlignOf : Platform -> CType -> Nat
cAlignOf = cSizeOf

||| `HasSize p t n`: on platform p, C type t occupies n bytes.  The only
||| constructor fixes n to `cSizeOf p t`, so a wrong size has no proof.
public export
data HasSize : Platform -> CType -> Nat -> Type where
  SizeIs : HasSize p t (cSizeOf p t)

||| `HasAlignment p t n`: on platform p, C type t is n-byte aligned.
public export
data HasAlignment : Platform -> CType -> Nat -> Type where
  AlignIs : HasAlignment p t (cAlignOf p t)

--------------------------------------------------------------------------------
-- Clade-Specific Types
--------------------------------------------------------------------------------

||| A non-empty string identifier for a panel clade.
public export
record CladeId where
  constructor MkCladeId
  ||| The raw string value of the clade identifier
  value : String
  ||| Erased proof that the identifier is non-empty
  {0 nonEmpty : So (value /= "")}

||| Safely construct a CladeId, returning Nothing if the string is empty
public export
mkCladeId : (s : String) -> Maybe CladeId
mkCladeId s = case choose (s /= "") of
  Left nonEmpty => Just (MkCladeId s {nonEmpty})
  Right _       => Nothing

||| The 13 clade kinds that classify every PanLL panel.
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

||| Convert a CladeKind to its C-compatible integer tag (0..12, contiguous).
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

||| Convert a C integer tag back to a CladeKind; Nothing out of range.
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

||| The C tag of a clade kind round-trips, so distinct kinds have
||| distinct tags.
export
cladeKindRoundTrip : (k : CladeKind) -> cladeKindFromInt (cladeKindToInt k) = Just k
cladeKindRoundTrip Directive  = Refl
cladeKindRoundTrip Scanner    = Refl
cladeKindRoundTrip Builder    = Refl
cladeKindRoundTrip Database   = Refl
cladeKindRoundTrip Network    = Refl
cladeKindRoundTrip Viewer     = Refl
cladeKindRoundTrip Ai         = Refl
cladeKindRoundTrip Loader     = Refl
cladeKindRoundTrip Meta       = Refl
cladeKindRoundTrip Service    = Refl
cladeKindRoundTrip Inspector  = Refl
cladeKindRoundTrip Bridge     = Refl
cladeKindRoundTrip Terminal   = Refl

||| The tag as a natural number (for decidable equality).
public export
cladeKindTag : CladeKind -> Nat
cladeKindTag Directive  = 0
cladeKindTag Scanner    = 1
cladeKindTag Builder    = 2
cladeKindTag Database   = 3
cladeKindTag Network    = 4
cladeKindTag Viewer     = 5
cladeKindTag Ai         = 6
cladeKindTag Loader     = 7
cladeKindTag Meta       = 8
cladeKindTag Service    = 9
cladeKindTag Inspector  = 10
cladeKindTag Bridge     = 11
cladeKindTag Terminal   = 12

public export
cladeKindFromTag : Nat -> Maybe CladeKind
cladeKindFromTag 0  = Just Directive
cladeKindFromTag 1  = Just Scanner
cladeKindFromTag 2  = Just Builder
cladeKindFromTag 3  = Just Database
cladeKindFromTag 4  = Just Network
cladeKindFromTag 5  = Just Viewer
cladeKindFromTag 6  = Just Ai
cladeKindFromTag 7  = Just Loader
cladeKindFromTag 8  = Just Meta
cladeKindFromTag 9  = Just Service
cladeKindFromTag 10 = Just Inspector
cladeKindFromTag 11 = Just Bridge
cladeKindFromTag 12 = Just Terminal
cladeKindFromTag _  = Nothing

public export
cladeKindTagRetract : (k : CladeKind) -> cladeKindFromTag (cladeKindTag k) = Just k
cladeKindTagRetract Directive  = Refl
cladeKindTagRetract Scanner    = Refl
cladeKindTagRetract Builder    = Refl
cladeKindTagRetract Database   = Refl
cladeKindTagRetract Network    = Refl
cladeKindTagRetract Viewer     = Refl
cladeKindTagRetract Ai         = Refl
cladeKindTagRetract Loader     = Refl
cladeKindTagRetract Meta       = Refl
cladeKindTagRetract Service    = Refl
cladeKindTagRetract Inspector  = Refl
cladeKindTagRetract Bridge     = Refl
cladeKindTagRetract Terminal   = Refl

public export
DecEq CladeKind where
  decEq = decEqViaTag cladeKindTag cladeKindFromTag cladeKindTagRetract

||| The total number of clade kinds.
public export
cladeKindCount : Nat
cladeKindCount = 13

||| All 13 clade kinds.  Its length is `cladeKindCount` by its type
||| (the name is qualified: a bare lower-case name in a type is bound as
||| an implicit variable, which is what broke this declaration before).
public export
allCladeKinds : Vect PanelClades.ABI.Types.cladeKindCount CladeKind
allCladeKinds =
  [ Directive, Scanner, Builder, Database, Network, Viewer, Ai
  , Loader, Meta, Service, Inspector, Bridge, Terminal ]

||| Exhaustiveness: every clade kind occurs in `allCladeKinds`.
export
cladeKindExhaustive : (k : CladeKind) -> Elem k PanelClades.ABI.Types.allCladeKinds
cladeKindExhaustive Directive  = Here
cladeKindExhaustive Scanner    = There Here
cladeKindExhaustive Builder    = There (There Here)
cladeKindExhaustive Database   = There (There (There Here))
cladeKindExhaustive Network    = There (There (There (There Here)))
cladeKindExhaustive Viewer     = There (There (There (There (There Here))))
cladeKindExhaustive Ai         = There (There (There (There (There (There Here)))))
cladeKindExhaustive Loader     = There (There (There (There (There (There (There Here))))))
cladeKindExhaustive Meta       = There (There (There (There (There (There (There (There Here)))))))
cladeKindExhaustive Service    = There (There (There (There (There (There (There (There (There Here))))))))
cladeKindExhaustive Inspector  = There (There (There (There (There (There (There (There (There (There Here)))))))))
cladeKindExhaustive Bridge     = There (There (There (There (There (There (There (There (There (There (There Here))))))))))
cladeKindExhaustive Terminal   = There (There (There (There (There (There (There (There (There (There (There (There Here)))))))))))

||| Record describing how a panel integrates with the clade system.
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
public export
record CladeCapability where
  constructor MkCladeCapability
  ||| Name of the capability (e.g. "syntax-highlight", "execute")
  name : String
  ||| Whether this capability is required (True) or optional (False)
  required : Bool

--------------------------------------------------------------------------------
-- Checked facts (replacing IO stubs that printed "verified" and checked
-- nothing)
--------------------------------------------------------------------------------

namespace Verify

  ||| C int is 4 bytes on every platform.
  export
  intIsFourBytes : (p : Platform) -> HasSize p CTInt 4
  intIsFourBytes _ = SizeIs

  ||| Pointers are 8 bytes on 64-bit platforms and 4 on WASM.
  export
  ptrLinux : HasSize Linux CTPtr 8
  ptrLinux = SizeIs

  export
  ptrWasm : HasSize WASM CTPtr 4
  ptrWasm = SizeIs

  ||| size_t and pointers have the same size everywhere.
  export
  sizeIsPtr : (p : Platform) -> cSizeOf p CTSize = cSizeOf p CTPtr
  sizeIsPtr _ = Refl
