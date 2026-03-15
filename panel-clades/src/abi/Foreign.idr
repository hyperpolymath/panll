-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
||| Foreign Function Interface Declarations for PanLL Panel-Clades
|||
||| This module declares all C-compatible functions that will be
||| implemented in the Zig FFI layer for the panel-clades subsystem.
|||
||| In addition to the standard library lifecycle (init/free), this
||| module exposes clade-specific FFI functions:
|||   - loadClade   — load a clade definition by identifier
|||   - queryTraits — query the traits/capabilities of a loaded clade
|||   - cladeKindCount — return the compile-time count of clade kinds (13)
|||
||| All functions are declared here with type signatures and safety proofs.
||| Implementations live in ffi/zig/

module PanelClades.ABI.Foreign

import PanelClades.ABI.Types
import PanelClades.ABI.Layout

%default total

--------------------------------------------------------------------------------
-- Library Lifecycle
--------------------------------------------------------------------------------

||| Initialize the panel-clades library
||| Returns a handle to the library instance, or Nothing on failure
export
%foreign "C:panel_clades_init, libpanel_clades"
prim__init : PrimIO Bits64

||| Safe wrapper for library initialization
export
init : IO (Maybe Handle)
init = do
  ptr <- primIO prim__init
  pure (createHandle ptr)

||| Clean up panel-clades library resources
export
%foreign "C:panel_clades_free, libpanel_clades"
prim__free : Bits64 -> PrimIO ()

||| Safe wrapper for cleanup
export
free : Handle -> IO ()
free h = primIO (prim__free (handlePtr h))

--------------------------------------------------------------------------------
-- Core Operations
--------------------------------------------------------------------------------

||| Process data through the panel-clades engine
export
%foreign "C:panel_clades_process, libpanel_clades"
prim__process : Bits64 -> Bits32 -> PrimIO Bits32

||| Safe wrapper with error handling
export
process : Handle -> Bits32 -> IO (Either Result Bits32)
process h input = do
  result <- primIO (prim__process (handlePtr h) input)
  pure $ case result of
    0 => Left Error
    n => Right n

--------------------------------------------------------------------------------
-- Clade-Specific FFI
--------------------------------------------------------------------------------

||| Load a clade definition by its string identifier.
||| The string is passed as a C pointer; returns a result code.
export
%foreign "C:panel_clades_load_clade, libpanel_clades"
prim__loadClade : Bits64 -> String -> PrimIO Bits32

||| Safely load a clade definition into the library context.
||| Returns Ok on success or an error Result on failure.
export
loadClade : Handle -> String -> IO (Either Result ())
loadClade h cladeIdStr = do
  result <- primIO (prim__loadClade (handlePtr h) cladeIdStr)
  pure $ case resultFromInt result of
    Just Ok  => Right ()
    Just err => Left err
    Nothing  => Left Error
  where
    resultFromInt : Bits32 -> Maybe Result
    resultFromInt 0 = Just Ok
    resultFromInt 1 = Just Error
    resultFromInt 2 = Just InvalidParam
    resultFromInt 3 = Just OutOfMemory
    resultFromInt 4 = Just NullPointer
    resultFromInt _ = Nothing

||| Query the traits (capabilities) of a loaded clade.
||| Returns a pointer to a null-terminated trait descriptor string, or 0
||| on failure.  The caller must free the string via panel_clades_free_string.
export
%foreign "C:panel_clades_query_traits, libpanel_clades"
prim__queryTraits : Bits64 -> Bits32 -> PrimIO Bits64

||| Safe wrapper: query traits for a given clade kind.
||| Returns a human-readable trait descriptor or Nothing on failure.
export
queryTraits : Handle -> CladeKind -> IO (Maybe String)
queryTraits h kind = do
  ptr <- primIO (prim__queryTraits (handlePtr h) (cladeKindToInt kind))
  if ptr == 0
    then pure Nothing
    else do
      let str = prim__getString ptr
      primIO (prim__freeString ptr)
      pure (Just str)

||| Return the number of clade kinds known to the library.
||| This MUST equal cladeKindCount (13) — mismatch indicates an ABI
||| version incompatibility between the Idris2 definitions and the
||| Zig implementation.
export
%foreign "C:panel_clades_clade_kind_count, libpanel_clades"
prim__cladeKindCount : PrimIO Bits32

||| Retrieve the clade kind count from the FFI layer and verify it
||| matches the compile-time constant.  Returns True when consistent.
export
verifyCladeKindCount : IO Bool
verifyCladeKindCount = do
  n <- primIO prim__cladeKindCount
  pure (n == cast cladeKindCount)

--------------------------------------------------------------------------------
-- String Operations
--------------------------------------------------------------------------------

||| Convert C string to Idris String
export
%foreign "support:idris2_getString, libidris2_support"
prim__getString : Bits64 -> String

||| Free C string
export
%foreign "C:panel_clades_free_string, libpanel_clades"
prim__freeString : Bits64 -> PrimIO ()

||| Get string result from library
export
%foreign "C:panel_clades_get_string, libpanel_clades"
prim__getResult : Bits64 -> PrimIO Bits64

||| Safe string getter
export
getString : Handle -> IO (Maybe String)
getString h = do
  ptr <- primIO (prim__getResult (handlePtr h))
  if ptr == 0
    then pure Nothing
    else do
      let str = prim__getString ptr
      primIO (prim__freeString ptr)
      pure (Just str)

--------------------------------------------------------------------------------
-- Array/Buffer Operations
--------------------------------------------------------------------------------

||| Process array data
export
%foreign "C:panel_clades_process_array, libpanel_clades"
prim__processArray : Bits64 -> Bits64 -> Bits32 -> PrimIO Bits32

||| Safe array processor
export
processArray : Handle -> (buffer : Bits64) -> (len : Bits32) -> IO (Either Result ())
processArray h buf len = do
  result <- primIO (prim__processArray (handlePtr h) buf len)
  pure $ case resultFromInt result of
    Just Ok => Right ()
    Just err => Left err
    Nothing => Left Error
  where
    resultFromInt : Bits32 -> Maybe Result
    resultFromInt 0 = Just Ok
    resultFromInt 1 = Just Error
    resultFromInt 2 = Just InvalidParam
    resultFromInt 3 = Just OutOfMemory
    resultFromInt 4 = Just NullPointer
    resultFromInt _ = Nothing

--------------------------------------------------------------------------------
-- Error Handling
--------------------------------------------------------------------------------

||| Get last error message
export
%foreign "C:panel_clades_last_error, libpanel_clades"
prim__lastError : PrimIO Bits64

||| Retrieve last error as string
export
lastError : IO (Maybe String)
lastError = do
  ptr <- primIO prim__lastError
  if ptr == 0
    then pure Nothing
    else pure (Just (prim__getString ptr))

||| Get error description for result code
export
errorDescription : Result -> String
errorDescription Ok = "Success"
errorDescription Error = "Generic error"
errorDescription InvalidParam = "Invalid parameter"
errorDescription OutOfMemory = "Out of memory"
errorDescription NullPointer = "Null pointer"

--------------------------------------------------------------------------------
-- Version Information
--------------------------------------------------------------------------------

||| Get library version
export
%foreign "C:panel_clades_version, libpanel_clades"
prim__version : PrimIO Bits64

||| Get version as string
export
version : IO String
version = do
  ptr <- primIO prim__version
  pure (prim__getString ptr)

||| Get library build info
export
%foreign "C:panel_clades_build_info, libpanel_clades"
prim__buildInfo : PrimIO Bits64

||| Get build information
export
buildInfo : IO String
buildInfo = do
  ptr <- primIO prim__buildInfo
  pure (prim__getString ptr)

--------------------------------------------------------------------------------
-- Callback Support
--------------------------------------------------------------------------------

||| Callback function type (C ABI)
public export
Callback : Type
Callback = Bits64 -> Bits32 -> Bits32

||| Register a callback
export
%foreign "C:panel_clades_register_callback, libpanel_clades"
prim__registerCallback : Bits64 -> AnyPtr -> PrimIO Bits32

-- TODO: Implement safe callback registration.
-- The callback must be wrapped via a proper FFI callback mechanism.
-- Do NOT use cast — it is banned per project safety standards.
-- See: https://idris2.readthedocs.io/en/latest/ffi/ffi.html#callbacks

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

||| Check if library is initialized
export
%foreign "C:panel_clades_is_initialized, libpanel_clades"
prim__isInitialized : Bits64 -> PrimIO Bits32

||| Check initialization status
export
isInitialized : Handle -> IO Bool
isInitialized h = do
  result <- primIO (prim__isInitialized (handlePtr h))
  pure (result /= 0)
