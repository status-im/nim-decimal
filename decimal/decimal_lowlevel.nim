# Decimal
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import strutils, macros, ospaths
from os import DirSep, walkFiles

const cSourcesPath = currentSourcePath.rsplit(DirSep, 1)[0] & "/mpdecimal_wrapper/generated"
const cHeader = csourcesPath / "mpdecimal.h"

{.passC: "-I" & cSourcesPath .}
{.passC: "-DHAVE_CONFIG_H".}

when sizeof(int) == 8:
  # Test if 64-bit arch
  {.passC: "-DCONFIG_64".}
elif sizeof(int) == 4:
  {.passC: "-DCONFIG_32".}
else:
  {.fatal: "CPU is neither 32 or 64 bit".}

when defined(x86_64) or defined(x86):
  # Test if it supports x86 ASM
  {.passC: "-DASM".}
else:
  {.passC: "-DANSI".}

{.deadCodeElim: on.}
{.pragma: Pdecimal, importc, cdecl,importc.}
{.pragma: Tdecimal, importc, header: cHeader.}

macro compileFilesFromDir(path: static[string], fileNameBody: untyped): untyped =
  # Generate the list of compile statement like so:
  # {.compile: "mpdecimal_wrapper/generated/constants.c".}
  # {.compile: "mpdecimal_wrapper/generated/mpdecimal.c".}
  # ...
  #
  # from
  # compileFilesFromDir("mpdecimal_wrapper/generated/"):
  #   "constants.c"
  #   "mpdecimal.c"
  #   ...

  result = newStmtList()

  for file in fileNameBody:
    assert file.kind == nnkStrLit
    result.add nnkPragma.newTree(
      nnkExprColonExpr.newTree(
        newIdentNode("compile"),
        newLit(path & $file)
      )
    )

# Order is important
compileFilesFromDir("mpdecimal_wrapper/generated/"):
  "basearith.c"
  "context.c"
  "constants.c"
  "convolute.c"
  "crt.c"
  "mpdecimal.c"
  "mpsignal.c"
  "difradix2.c"
  "fnt.c"
  "fourstep.c"
  "io.c"
  "memory.c"
  "numbertheory.c"
  "sixstep.c"
  "transpose.c"


# ##### C2NIM

## ****************************************************************************
##                                   Version
## ****************************************************************************

const
  MPD_MAJOR_VERSION* = 2
  MPD_MINOR_VERSION* = 4
  MPD_MICRO_VERSION* = 2
  MPD_VERSION* = "2.4.2"
  MPD_VERSION_HEX* = ((MPD_MAJOR_VERSION shl 24) or (MPD_MINOR_VERSION shl 16) or
      (MPD_MICRO_VERSION shl 8))

proc mpd_version*(): cstring {.cdecl, importc: "mpd_version",
                            header: cHeader.}
## ****************************************************************************
##                               Configuration
## ****************************************************************************
##  ABI: 64-bit

when sizeof(int) == 4:
  quit "cannot use CONFIG_32 with 64-bit header."

##  BEGIN CONFIG_64
when sizeof(int) == 8:
  ##  types for modular and base arithmetic
  const
    MPD_UINT_MAX* = not 0'u64
    MPD_BITS_PER_UINT* = 64
  type
    mpd_uint_t* = uint64
  ##  unsigned mod type
  const
    MPD_SIZE_MAX* = high(csize)
  type
    mpd_size_t* = csize
  ##  unsigned size type
  ##  type for exp, digits, len, prec
  const
    MPD_SSIZE_MAX* = high(int64)
    MPD_SSIZE_MIN* = low(int64)
  type
    mpd_ssize_t* = int64
  # const
  #   _mpd_strtossize* = strtoll
  ##  decimal arithmetic
  const
    MPD_RDIGITS* = 19
    MPD_MAX_POW10* = 19
    MPD_EXPDIGITS* = 19
    MPD_MAX_PREC_LOG2* = 64
  ##  conversion specifiers
  # const
  #   PRI_mpd_uint_t* = PRIu64
  #   PRI_mpd_ssize_t* = PRIi64
  ##  END CONFIG_64
  ##  BEGIN CONFIG_32
elif defined(CONFIG_32):
  ##  types for modular and base arithmetic
  const
    MPD_UINT_MAX* = UINT32_MAX
    MPD_BITS_PER_UINT* = 32
  type
    mpd_uint_t* = uint32
  ##  unsigned mod type
  when not defined(LEGACY_COMPILER):
    const
      MPD_UUINT_MAX* = UINT64_MAX
    type
      mpd_uuint_t* = uint64
    ##  double width unsigned mod type
  const
    MPD_SIZE_MAX* = SIZE_MAX
  type
    mpd_size_t* = csize
  ##  unsigned size type
  ##  type for dec->len, dec->exp, ctx->prec
  const
    MPD_SSIZE_MAX* = INT32_MAX
    MPD_SSIZE_MIN* = INT32_MIN
  type
    mpd_ssize_t* = int32
  # const
  #   _mpd_strtossize* = strtol
  ##  decimal arithmetic
  const
    MPD_RDIGITS* = 9
    MPD_MAX_POW10* = 9
    MPD_EXPDIGITS* = 10
    MPD_MAX_PREC_LOG2* = 32
  ##  conversion specifiers
  # const
  #   PRI_mpd_uint_t* = PRIu32
  #   PRI_mpd_ssize_t* = PRIi32
  ##  END CONFIG_32
else:
  quit "define CONFIG_64 or CONFIG_32"

##  END CONFIG
## ****************************************************************************
##                                 Context
## ****************************************************************************

const
  MPD_ROUND_UP* = 0             ##  round away from 0
  MPD_ROUND_DOWN* = 1           ##  round toward 0 (truncate)
  MPD_ROUND_CEILING* = 2        ##  round toward +infinity
  MPD_ROUND_FLOOR* = 3          ##  round toward -infinity
  MPD_ROUND_HALF_UP* = 4        ##  0.5 is rounded up
  MPD_ROUND_HALF_DOWN* = 5      ##  0.5 is rounded down
  MPD_ROUND_HALF_EVEN* = 6      ##  0.5 is rounded to even
  MPD_ROUND_05UP* = 7           ##  round zero or five away from 0
  MPD_ROUND_TRUNC* = 8          ##  truncate, but set infinity
  MPD_ROUND_GUARD* = 9

const
  MPD_CLAMP_DEFAULT* = 0
  MPD_CLAMP_IEEE_754* = 1
  MPD_CLAMP_GUARD* = 2

var mpd_round_string* {.importc: "mpd_round_string", header: cHeader.}: array[
    MPD_ROUND_GUARD, cstring]

var mpd_clamp_string* {.importc: "mpd_clamp_string", header: cHeader.}: array[
    MPD_CLAMP_GUARD, cstring]

type
  mpd_context_t* {.importc: "mpd_context_t", header: cHeader, bycopy.} = object
    prec* {.importc: "prec".}: mpd_ssize_t ##  precision
    emax* {.importc: "emax".}: mpd_ssize_t ##  max positive exp
    emin* {.importc: "emin".}: mpd_ssize_t ##  min negative exp
    traps* {.importc: "traps".}: uint32 ##  status events that should be trapped
    status* {.importc: "status".}: uint32 ##  status flags
    newtrap* {.importc: "newtrap".}: uint32 ##  set by mpd_addstatus_raise()
    round* {.importc: "round".}: cint ##  rounding mode
    clamp* {.importc: "clamp".}: cint ##  clamp mode
    allcr* {.importc: "allcr".}: cint ##  all functions correctly rounded


##  Status flags

const
  MPD_Clamped* = 0x00000001
  MPD_Conversion_syntax* = 0x00000002
  MPD_Division_by_zero* = 0x00000004
  MPD_Division_impossible* = 0x00000008
  MPD_Division_undefined* = 0x00000010
  MPD_Fpu_error* = 0x00000020
  MPD_Inexact* = 0x00000040
  MPD_Invalid_context* = 0x00000080
  MPD_Invalid_operation* = 0x00000100
  MPD_Malloc_error* = 0x00000200
  MPD_Not_implemented* = 0x00000400
  MPD_Overflow* = 0x00000800
  MPD_Rounded* = 0x00001000
  MPD_Subnormal* = 0x00002000
  MPD_Underflow* = 0x00004000
  MPD_Max_status* = (0x00008000 - 1)

##  Conditions that result in an IEEE 754 exception

const
  MPD_IEEE_Invalid_operation* = (MPD_Conversion_syntax or MPD_Division_impossible or
      MPD_Division_undefined or MPD_Fpu_error or MPD_Invalid_context or
      MPD_Invalid_operation or MPD_Malloc_error)

##  Errors that require the result of an operation to be set to NaN

const
  MPD_Errors* = (MPD_IEEE_Invalid_operation or MPD_Division_by_zero)

##  Default traps

const
  MPD_Traps* = (MPD_IEEE_Invalid_operation or MPD_Division_by_zero or MPD_Overflow or
      MPD_Underflow)

##  Official name

const
  MPD_Insufficient_storage* = MPD_Malloc_error

##  IEEE 754 interchange format contexts

const
  MPD_IEEE_CONTEXT_MAX_BITS* = 512
  MPD_DECIMAL32* = 32
  MPD_DECIMAL64* = 64
  MPD_DECIMAL128* = 128
  MPD_MINALLOC_MIN* = 2
  MPD_MINALLOC_MAX* = 64

var MPD_MINALLOC* {.importc: "MPD_MINALLOC", header: cHeader.}: mpd_ssize_t

var mpd_traphandler*: proc (a2: ptr mpd_context_t) {.cdecl.}

proc mpd_dflt_traphandler*(a2: ptr mpd_context_t) {.cdecl,
    importc: "mpd_dflt_traphandler", header: cHeader.}
proc mpd_setminalloc*(n: mpd_ssize_t) {.cdecl, importc: "mpd_setminalloc",
                                     header: cHeader.}
proc mpd_init*(ctx: ptr mpd_context_t; prec: mpd_ssize_t) {.cdecl, importc: "mpd_init",
    header: cHeader.}
proc mpd_maxcontext*(ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_maxcontext",
    header: cHeader.}
proc mpd_defaultcontext*(ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_defaultcontext", header: cHeader.}
proc mpd_basiccontext*(ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_basiccontext",
    header: cHeader.}
proc mpd_ieee_context*(ctx: ptr mpd_context_t; bits: cint): cint {.cdecl,
    importc: "mpd_ieee_context", header: cHeader.}
proc mpd_getprec*(ctx: ptr mpd_context_t): mpd_ssize_t {.cdecl,
    importc: "mpd_getprec", header: cHeader.}
proc mpd_getemax*(ctx: ptr mpd_context_t): mpd_ssize_t {.cdecl,
    importc: "mpd_getemax", header: cHeader.}
proc mpd_getemin*(ctx: ptr mpd_context_t): mpd_ssize_t {.cdecl,
    importc: "mpd_getemin", header: cHeader.}
proc mpd_getround*(ctx: ptr mpd_context_t): cint {.cdecl, importc: "mpd_getround",
    header: cHeader.}
proc mpd_gettraps*(ctx: ptr mpd_context_t): uint32 {.cdecl, importc: "mpd_gettraps",
    header: cHeader.}
proc mpd_getstatus*(ctx: ptr mpd_context_t): uint32 {.cdecl,
    importc: "mpd_getstatus", header: cHeader.}
proc mpd_getclamp*(ctx: ptr mpd_context_t): cint {.cdecl, importc: "mpd_getclamp",
    header: cHeader.}
proc mpd_getcr*(ctx: ptr mpd_context_t): cint {.cdecl, importc: "mpd_getcr",
    header: cHeader.}
proc mpd_qsetprec*(ctx: ptr mpd_context_t; prec: mpd_ssize_t): cint {.cdecl,
    importc: "mpd_qsetprec", header: cHeader.}
proc mpd_qsetemax*(ctx: ptr mpd_context_t; emax: mpd_ssize_t): cint {.cdecl,
    importc: "mpd_qsetemax", header: cHeader.}
proc mpd_qsetemin*(ctx: ptr mpd_context_t; emin: mpd_ssize_t): cint {.cdecl,
    importc: "mpd_qsetemin", header: cHeader.}
proc mpd_qsetround*(ctx: ptr mpd_context_t; newround: cint): cint {.cdecl,
    importc: "mpd_qsetround", header: cHeader.}
proc mpd_qsettraps*(ctx: ptr mpd_context_t; flags: uint32): cint {.cdecl,
    importc: "mpd_qsettraps", header: cHeader.}
proc mpd_qsetstatus*(ctx: ptr mpd_context_t; flags: uint32): cint {.cdecl,
    importc: "mpd_qsetstatus", header: cHeader.}
proc mpd_qsetclamp*(ctx: ptr mpd_context_t; c: cint): cint {.cdecl,
    importc: "mpd_qsetclamp", header: cHeader.}
proc mpd_qsetcr*(ctx: ptr mpd_context_t; c: cint): cint {.cdecl, importc: "mpd_qsetcr",
    header: cHeader.}
proc mpd_addstatus_raise*(ctx: ptr mpd_context_t; flags: uint32) {.cdecl,
    importc: "mpd_addstatus_raise", header: cHeader.}
## ****************************************************************************
##                            Decimal Arithmetic
## ****************************************************************************
##  mpd_t flags

const # TODO use enum + set
  MPD_POS* = 0'u8
  MPD_NEG* = 1'u8
  MPD_INF* = 2'u8
  MPD_NAN* = 4'u8
  MPD_SNAN* = 8'u8
  MPD_SPECIAL* = (MPD_INF or MPD_NAN or MPD_SNAN)
  MPD_STATIC* = 16'u8
  MPD_STATIC_DATA* = 32'u8
  MPD_SHARED_DATA* = 64'u8
  MPD_CONST_DATA* = 128'u8
  MPD_DATAFLAGS* = (MPD_STATIC_DATA or MPD_SHARED_DATA or MPD_CONST_DATA)

##  mpd_t

type
  mpd_t* {.importc: "mpd_t", header: cHeader, bycopy.} = object
    flags* {.importc: "flags".}: uint8
    exp* {.importc: "exp".}: mpd_ssize_t
    digits* {.importc: "digits".}: mpd_ssize_t
    len* {.importc: "len".}: mpd_ssize_t
    alloc* {.importc: "alloc".}: mpd_ssize_t
    data* {.importc: "data".}: ptr mpd_uint_t

  uchar* = cuchar

## ****************************************************************************
##                        Quiet, thread-safe functions
## ****************************************************************************
##  format specification

type
  mpd_spec_t* {.importc: "mpd_spec_t", header: cHeader, bycopy.} = object
    min_width* {.importc: "min_width".}: mpd_ssize_t ##  minimum field width
    prec* {.importc: "prec".}: mpd_ssize_t ##  fraction digits or significant digits
    Ttype* {.importc: "type".}: char ##  conversion specifier ### MODIFIED for Nim compat ###
    align* {.importc: "align".}: char ##  alignment
    sign* {.importc: "sign".}: char ##  sign printing/alignment
    fill* {.importc: "fill".}: array[5, char] ##  fill character
    dot* {.importc: "dot".}: cstring ##  decimal point
    sep* {.importc: "sep".}: cstring ##  thousands separator
    grouping* {.importc: "grouping".}: cstring ##  grouping of digits


##  output to a string

proc mpd_to_sci*(dec: ptr mpd_t; fmt: cint): cstring {.cdecl, importc: "mpd_to_sci",
    header: cHeader.}
proc mpd_to_eng*(dec: ptr mpd_t; fmt: cint): cstring {.cdecl, importc: "mpd_to_eng",
    header: cHeader.}
proc mpd_to_sci_size*(res: cstringArray; dec: ptr mpd_t; fmt: cint): mpd_ssize_t {.cdecl,
    importc: "mpd_to_sci_size", header: cHeader.}
proc mpd_to_eng_size*(res: cstringArray; dec: ptr mpd_t; fmt: cint): mpd_ssize_t {.cdecl,
    importc: "mpd_to_eng_size", header: cHeader.}
proc mpd_validate_lconv*(spec: ptr mpd_spec_t): cint {.cdecl,
    importc: "mpd_validate_lconv", header: cHeader.}
proc mpd_parse_fmt_str*(spec: ptr mpd_spec_t; fmt: cstring; caps: cint): cint {.cdecl,
    importc: "mpd_parse_fmt_str", header: cHeader.}
proc mpd_qformat_spec*(dec: ptr mpd_t; spec: ptr mpd_spec_t; ctx: ptr mpd_context_t;
                      status: ptr uint32): cstring {.cdecl,
    importc: "mpd_qformat_spec", header: cHeader.}
proc mpd_qformat*(dec: ptr mpd_t; fmt: cstring; ctx: ptr mpd_context_t;
                 status: ptr uint32): cstring {.cdecl, importc: "mpd_qformat",
    header: cHeader.}
const
  MPD_NUM_FLAGS* = 15
  MPD_MAX_FLAG_STRING* = 208
  MPD_MAX_FLAG_LIST* = (MPD_MAX_FLAG_STRING + 18)
  MPD_MAX_SIGNAL_LIST* = 121

proc mpd_snprint_flags*(dest: cstring; nmemb: cint; flags: uint32): cint {.cdecl,
    importc: "mpd_snprint_flags", header: cHeader.}
proc mpd_lsnprint_flags*(dest: cstring; nmemb: cint; flags: uint32;
                        flag_string: ptr cstring): cint {.cdecl,
    importc: "mpd_lsnprint_flags", header: cHeader.}
proc mpd_lsnprint_signals*(dest: cstring; nmemb: cint; flags: uint32;
                          signal_string: ptr cstring): cint {.cdecl,
    importc: "mpd_lsnprint_signals", header: cHeader.}
##  output to a file

proc mpd_fprint*(file: ptr FILE; dec: ptr mpd_t) {.cdecl, importc: "mpd_fprint",
    header: cHeader.}
proc mpd_print*(dec: ptr mpd_t) {.cdecl, importc: "mpd_print",
                              header: cHeader.}
##  assignment from a string

proc mpd_qset_string*(dec: ptr mpd_t; s: cstring; ctx: ptr mpd_context_t;
                     status: ptr uint32) {.cdecl, importc: "mpd_qset_string",
    header: cHeader.}
##  set to NaN with error flags

proc mpd_seterror*(result: ptr mpd_t; flags: uint32; status: ptr uint32) {.cdecl,
    importc: "mpd_seterror", header: cHeader.}
##  set a special with sign and type

proc mpd_setspecial*(dec: ptr mpd_t; sign: uint8; Ttype: uint8) {.cdecl,
    importc: "mpd_setspecial", header: cHeader.}
##  set coefficient to zero or all nines

proc mpd_zerocoeff*(result: ptr mpd_t) {.cdecl, importc: "mpd_zerocoeff",
                                     header: cHeader.}
proc mpd_qmaxcoeff*(result: ptr mpd_t; ctx: ptr mpd_context_t; status: ptr uint32) {.
    cdecl, importc: "mpd_qmaxcoeff", header: cHeader.}
##  quietly assign a C integer type to an mpd_t

proc mpd_qset_ssize*(result: ptr mpd_t; a: mpd_ssize_t; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qset_ssize",
    header: cHeader.}
proc mpd_qset_i32*(result: ptr mpd_t; a: int32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qset_i32",
                                       header: cHeader.}
proc mpd_qset_uint*(result: ptr mpd_t; a: mpd_uint_t; ctx: ptr mpd_context_t;
                   status: ptr uint32) {.cdecl, importc: "mpd_qset_uint",
                                        header: cHeader.}
proc mpd_qset_u32*(result: ptr mpd_t; a: uint32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qset_u32",
                                       header: cHeader.}
when not defined(LEGACY_COMPILER):
  proc mpd_qset_i64*(result: ptr mpd_t; a: int64; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qset_i64",
      header: cHeader.}
  proc mpd_qset_u64*(result: ptr mpd_t; a: uint64; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qset_u64",
      header: cHeader.}
##  quietly assign a C integer type to an mpd_t with a static coefficient

proc mpd_qsset_ssize*(result: ptr mpd_t; a: mpd_ssize_t; ctx: ptr mpd_context_t;
                     status: ptr uint32) {.cdecl, importc: "mpd_qsset_ssize",
    header: cHeader.}
proc mpd_qsset_i32*(result: ptr mpd_t; a: int32; ctx: ptr mpd_context_t;
                   status: ptr uint32) {.cdecl, importc: "mpd_qsset_i32",
                                        header: cHeader.}
proc mpd_qsset_uint*(result: ptr mpd_t; a: mpd_uint_t; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qsset_uint",
    header: cHeader.}
proc mpd_qsset_u32*(result: ptr mpd_t; a: uint32; ctx: ptr mpd_context_t;
                   status: ptr uint32) {.cdecl, importc: "mpd_qsset_u32",
                                        header: cHeader.}
##  quietly get a C integer type from an mpd_t

proc mpd_qget_ssize*(dec: ptr mpd_t; status: ptr uint32): mpd_ssize_t {.cdecl,
    importc: "mpd_qget_ssize", header: cHeader.}
proc mpd_qget_uint*(dec: ptr mpd_t; status: ptr uint32): mpd_uint_t {.cdecl,
    importc: "mpd_qget_uint", header: cHeader.}
proc mpd_qabs_uint*(dec: ptr mpd_t; status: ptr uint32): mpd_uint_t {.cdecl,
    importc: "mpd_qabs_uint", header: cHeader.}
proc mpd_qget_i32*(dec: ptr mpd_t; status: ptr uint32): int32 {.cdecl,
    importc: "mpd_qget_i32", header: cHeader.}
proc mpd_qget_u32*(dec: ptr mpd_t; status: ptr uint32): uint32 {.cdecl,
    importc: "mpd_qget_u32", header: cHeader.}
when not defined(LEGACY_COMPILER):
  proc mpd_qget_i64*(dec: ptr mpd_t; status: ptr uint32): int64 {.cdecl,
      importc: "mpd_qget_i64", header: cHeader.}
  proc mpd_qget_u64*(dec: ptr mpd_t; status: ptr uint32): uint64 {.cdecl,
      importc: "mpd_qget_u64", header: cHeader.}
##  quiet functions

proc mpd_qcheck_nan*(nanresult: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                    status: ptr uint32): cint {.cdecl, importc: "mpd_qcheck_nan",
    header: cHeader.}
proc mpd_qcheck_nans*(nanresult: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t;
                     ctx: ptr mpd_context_t; status: ptr uint32): cint {.cdecl,
    importc: "mpd_qcheck_nans", header: cHeader.}
proc mpd_qfinalize*(result: ptr mpd_t; ctx: ptr mpd_context_t; status: ptr uint32) {.
    cdecl, importc: "mpd_qfinalize", header: cHeader.}
proc mpd_class*(a: ptr mpd_t; ctx: ptr mpd_context_t): cstring {.cdecl,
    importc: "mpd_class", header: cHeader.}
proc mpd_qcopy*(result: ptr mpd_t; a: ptr mpd_t; status: ptr uint32): cint {.cdecl,
    importc: "mpd_qcopy", header: cHeader.}
proc mpd_qncopy*(a: ptr mpd_t): ptr mpd_t {.cdecl, importc: "mpd_qncopy",
                                      header: cHeader.}
proc mpd_qcopy_abs*(result: ptr mpd_t; a: ptr mpd_t; status: ptr uint32): cint {.cdecl,
    importc: "mpd_qcopy_abs", header: cHeader.}
proc mpd_qcopy_negate*(result: ptr mpd_t; a: ptr mpd_t; status: ptr uint32): cint {.
    cdecl, importc: "mpd_qcopy_negate", header: cHeader.}
proc mpd_qcopy_sign*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; status: ptr uint32): cint {.
    cdecl, importc: "mpd_qcopy_sign", header: cHeader.}
proc mpd_qand*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qand",
                                   header: cHeader.}
proc mpd_qinvert*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                 status: ptr uint32) {.cdecl, importc: "mpd_qinvert",
                                      header: cHeader.}
proc mpd_qlogb*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
               status: ptr uint32) {.cdecl, importc: "mpd_qlogb",
                                    header: cHeader.}
proc mpd_qor*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
             status: ptr uint32) {.cdecl, importc: "mpd_qor",
                                  header: cHeader.}
proc mpd_qscaleb*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                 status: ptr uint32) {.cdecl, importc: "mpd_qscaleb",
                                      header: cHeader.}
proc mpd_qxor*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qxor",
                                   header: cHeader.}
proc mpd_same_quantum*(a: ptr mpd_t; b: ptr mpd_t): cint {.cdecl,
    importc: "mpd_same_quantum", header: cHeader.}
proc mpd_qrotate*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                 status: ptr uint32) {.cdecl, importc: "mpd_qrotate",
                                      header: cHeader.}
proc mpd_qshiftl*(result: ptr mpd_t; a: ptr mpd_t; n: mpd_ssize_t; status: ptr uint32): cint {.
    cdecl, importc: "mpd_qshiftl", header: cHeader.}
proc mpd_qshiftr*(result: ptr mpd_t; a: ptr mpd_t; n: mpd_ssize_t; status: ptr uint32): mpd_uint_t {.
    cdecl, importc: "mpd_qshiftr", header: cHeader.}
proc mpd_qshiftr_inplace*(result: ptr mpd_t; n: mpd_ssize_t): mpd_uint_t {.cdecl,
    importc: "mpd_qshiftr_inplace", header: cHeader.}
proc mpd_qshift*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                status: ptr uint32) {.cdecl, importc: "mpd_qshift",
                                     header: cHeader.}
proc mpd_qshiftn*(result: ptr mpd_t; a: ptr mpd_t; n: mpd_ssize_t;
                 ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qshiftn", header: cHeader.}
proc mpd_qcmp*(a: ptr mpd_t; b: ptr mpd_t; status: ptr uint32): cint {.cdecl,
    importc: "mpd_qcmp", header: cHeader.}
proc mpd_qcompare*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                  status: ptr uint32): cint {.cdecl, importc: "mpd_qcompare",
    header: cHeader.}
proc mpd_qcompare_signal*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t;
                         ctx: ptr mpd_context_t; status: ptr uint32): cint {.cdecl,
    importc: "mpd_qcompare_signal", header: cHeader.}
proc mpd_cmp_total*(a: ptr mpd_t; b: ptr mpd_t): cint {.cdecl, importc: "mpd_cmp_total",
    header: cHeader.}
proc mpd_cmp_total_mag*(a: ptr mpd_t; b: ptr mpd_t): cint {.cdecl,
    importc: "mpd_cmp_total_mag", header: cHeader.}
proc mpd_compare_total*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t): cint {.cdecl,
    importc: "mpd_compare_total", header: cHeader.}
proc mpd_compare_total_mag*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t): cint {.cdecl,
    importc: "mpd_compare_total_mag", header: cHeader.}
proc mpd_qround_to_intx*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                        status: ptr uint32) {.cdecl,
    importc: "mpd_qround_to_intx", header: cHeader.}
proc mpd_qround_to_int*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                       status: ptr uint32) {.cdecl, importc: "mpd_qround_to_int",
    header: cHeader.}
proc mpd_qtrunc*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                status: ptr uint32) {.cdecl, importc: "mpd_qtrunc",
                                     header: cHeader.}
proc mpd_qfloor*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                status: ptr uint32) {.cdecl, importc: "mpd_qfloor",
                                     header: cHeader.}
proc mpd_qceil*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
               status: ptr uint32) {.cdecl, importc: "mpd_qceil",
                                    header: cHeader.}
proc mpd_qabs*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qabs",
                                   header: cHeader.}
proc mpd_qmax*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qmax",
                                   header: cHeader.}
proc mpd_qmax_mag*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qmax_mag",
                                       header: cHeader.}
proc mpd_qmin*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qmin",
                                   header: cHeader.}
proc mpd_qmin_mag*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qmin_mag",
                                       header: cHeader.}
proc mpd_qminus*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                status: ptr uint32) {.cdecl, importc: "mpd_qminus",
                                     header: cHeader.}
proc mpd_qplus*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
               status: ptr uint32) {.cdecl, importc: "mpd_qplus",
                                    header: cHeader.}
proc mpd_qnext_minus*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                     status: ptr uint32) {.cdecl, importc: "mpd_qnext_minus",
    header: cHeader.}
proc mpd_qnext_plus*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qnext_plus",
    header: cHeader.}
proc mpd_qnext_toward*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t;
                      ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qnext_toward", header: cHeader.}
proc mpd_qquantize*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                   status: ptr uint32) {.cdecl, importc: "mpd_qquantize",
                                        header: cHeader.}
proc mpd_qrescale*(result: ptr mpd_t; a: ptr mpd_t; exp: mpd_ssize_t;
                  ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qrescale", header: cHeader.}
proc mpd_qrescale_fmt*(result: ptr mpd_t; a: ptr mpd_t; exp: mpd_ssize_t;
                      ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qrescale_fmt", header: cHeader.}
proc mpd_qreduce*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                 status: ptr uint32) {.cdecl, importc: "mpd_qreduce",
                                      header: cHeader.}
proc mpd_qadd*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qadd",
                                   header: cHeader.}
proc mpd_qadd_ssize*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_ssize_t;
                    ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qadd_ssize", header: cHeader.}
proc mpd_qadd_i32*(result: ptr mpd_t; a: ptr mpd_t; b: int32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qadd_i32",
                                       header: cHeader.}
proc mpd_qadd_uint*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_uint_t;
                   ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qadd_uint", header: cHeader.}
proc mpd_qadd_u32*(result: ptr mpd_t; a: ptr mpd_t; b: uint32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qadd_u32",
                                       header: cHeader.}
proc mpd_qsub*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qsub",
                                   header: cHeader.}
proc mpd_qsub_ssize*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_ssize_t;
                    ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qsub_ssize", header: cHeader.}
proc mpd_qsub_i32*(result: ptr mpd_t; a: ptr mpd_t; b: int32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qsub_i32",
                                       header: cHeader.}
proc mpd_qsub_uint*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_uint_t;
                   ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qsub_uint", header: cHeader.}
proc mpd_qsub_u32*(result: ptr mpd_t; a: ptr mpd_t; b: uint32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qsub_u32",
                                       header: cHeader.}
proc mpd_qmul*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qmul",
                                   header: cHeader.}
proc mpd_qmul_ssize*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_ssize_t;
                    ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qmul_ssize", header: cHeader.}
proc mpd_qmul_i32*(result: ptr mpd_t; a: ptr mpd_t; b: int32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qmul_i32",
                                       header: cHeader.}
proc mpd_qmul_uint*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_uint_t;
                   ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qmul_uint", header: cHeader.}
proc mpd_qmul_u32*(result: ptr mpd_t; a: ptr mpd_t; b: uint32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qmul_u32",
                                       header: cHeader.}
proc mpd_qfma*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; c: ptr mpd_t;
              ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qfma", header: cHeader.}
proc mpd_qdiv*(q: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qdiv",
                                   header: cHeader.}
proc mpd_qdiv_ssize*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_ssize_t;
                    ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qdiv_ssize", header: cHeader.}
proc mpd_qdiv_i32*(result: ptr mpd_t; a: ptr mpd_t; b: int32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qdiv_i32",
                                       header: cHeader.}
proc mpd_qdiv_uint*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_uint_t;
                   ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qdiv_uint", header: cHeader.}
proc mpd_qdiv_u32*(result: ptr mpd_t; a: ptr mpd_t; b: uint32; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qdiv_u32",
                                       header: cHeader.}
proc mpd_qdivint*(q: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                 status: ptr uint32) {.cdecl, importc: "mpd_qdivint",
                                      header: cHeader.}
proc mpd_qrem*(r: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qrem",
                                   header: cHeader.}
proc mpd_qrem_near*(r: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t;
                   status: ptr uint32) {.cdecl, importc: "mpd_qrem_near",
                                        header: cHeader.}
proc mpd_qdivmod*(q: ptr mpd_t; r: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t;
                 ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qdivmod", header: cHeader.}
proc mpd_qpow*(result: ptr mpd_t; base: ptr mpd_t; exp: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qpow",
                                   header: cHeader.}
proc mpd_qpowmod*(result: ptr mpd_t; base: ptr mpd_t; exp: ptr mpd_t; `mod`: ptr mpd_t;
                 ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qpowmod", header: cHeader.}
proc mpd_qexp*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
              status: ptr uint32) {.cdecl, importc: "mpd_qexp",
                                   header: cHeader.}
proc mpd_qln10*(result: ptr mpd_t; prec: mpd_ssize_t; status: ptr uint32) {.cdecl,
    importc: "mpd_qln10", header: cHeader.}
proc mpd_qln*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
             status: ptr uint32) {.cdecl, importc: "mpd_qln",
                                  header: cHeader.}
proc mpd_qlog10*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                status: ptr uint32) {.cdecl, importc: "mpd_qlog10",
                                     header: cHeader.}
proc mpd_qsqrt*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
               status: ptr uint32) {.cdecl, importc: "mpd_qsqrt",
                                    header: cHeader.}
proc mpd_qinvroot*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t;
                  status: ptr uint32) {.cdecl, importc: "mpd_qinvroot",
                                       header: cHeader.}
when not defined(LEGACY_COMPILER):
  proc mpd_qadd_i64*(result: ptr mpd_t; a: ptr mpd_t; b: int64; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qadd_i64",
      header: cHeader.}
  proc mpd_qadd_u64*(result: ptr mpd_t; a: ptr mpd_t; b: uint64;
                    ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
      importc: "mpd_qadd_u64", header: cHeader.}
  proc mpd_qsub_i64*(result: ptr mpd_t; a: ptr mpd_t; b: int64; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qsub_i64",
      header: cHeader.}
  proc mpd_qsub_u64*(result: ptr mpd_t; a: ptr mpd_t; b: uint64;
                    ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
      importc: "mpd_qsub_u64", header: cHeader.}
  proc mpd_qmul_i64*(result: ptr mpd_t; a: ptr mpd_t; b: int64; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qmul_i64",
      header: cHeader.}
  proc mpd_qmul_u64*(result: ptr mpd_t; a: ptr mpd_t; b: uint64;
                    ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
      importc: "mpd_qmul_u64", header: cHeader.}
  proc mpd_qdiv_i64*(result: ptr mpd_t; a: ptr mpd_t; b: int64; ctx: ptr mpd_context_t;
                    status: ptr uint32) {.cdecl, importc: "mpd_qdiv_i64",
      header: cHeader.}
  proc mpd_qdiv_u64*(result: ptr mpd_t; a: ptr mpd_t; b: uint64;
                    ctx: ptr mpd_context_t; status: ptr uint32) {.cdecl,
      importc: "mpd_qdiv_u64", header: cHeader.}
proc mpd_sizeinbase*(a: ptr mpd_t; base: uint32): csize {.cdecl,
    importc: "mpd_sizeinbase", header: cHeader.}
proc mpd_qimport_u16*(result: ptr mpd_t; srcdata: ptr uint16; srclen: csize;
                     srcsign: uint8; srcbase: uint32; ctx: ptr mpd_context_t;
                     status: ptr uint32) {.cdecl, importc: "mpd_qimport_u16",
    header: cHeader.}
proc mpd_qimport_u32*(result: ptr mpd_t; srcdata: ptr uint32; srclen: csize;
                     srcsign: uint8; srcbase: uint32; ctx: ptr mpd_context_t;
                     status: ptr uint32) {.cdecl, importc: "mpd_qimport_u32",
    header: cHeader.}
proc mpd_qexport_u16*(rdata: ptr ptr uint16; rlen: csize; base: uint32;
                     src: ptr mpd_t; status: ptr uint32): csize {.cdecl,
    importc: "mpd_qexport_u16", header: cHeader.}
proc mpd_qexport_u32*(rdata: ptr ptr uint32; rlen: csize; base: uint32;
                     src: ptr mpd_t; status: ptr uint32): csize {.cdecl,
    importc: "mpd_qexport_u32", header: cHeader.}
## ****************************************************************************
##                            Signalling functions
## ****************************************************************************

proc mpd_format*(dec: ptr mpd_t; fmt: cstring; ctx: ptr mpd_context_t): cstring {.cdecl,
    importc: "mpd_format", header: cHeader.}
proc mpd_import_u16*(result: ptr mpd_t; srcdata: ptr uint16; srclen: csize;
                    srcsign: uint8; base: uint32; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_import_u16", header: cHeader.}
proc mpd_import_u32*(result: ptr mpd_t; srcdata: ptr uint32; srclen: csize;
                    srcsign: uint8; base: uint32; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_import_u32", header: cHeader.}
proc mpd_export_u16*(rdata: ptr ptr uint16; rlen: csize; base: uint32;
                    src: ptr mpd_t; ctx: ptr mpd_context_t): csize {.cdecl,
    importc: "mpd_export_u16", header: cHeader.}
proc mpd_export_u32*(rdata: ptr ptr uint32; rlen: csize; base: uint32;
                    src: ptr mpd_t; ctx: ptr mpd_context_t): csize {.cdecl,
    importc: "mpd_export_u32", header: cHeader.}
proc mpd_finalize*(result: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_finalize", header: cHeader.}
proc mpd_check_nan*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t): cint {.cdecl,
    importc: "mpd_check_nan", header: cHeader.}
proc mpd_check_nans*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t): cint {.
    cdecl, importc: "mpd_check_nans", header: cHeader.}
proc mpd_set_string*(result: ptr mpd_t; s: cstring; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_set_string", header: cHeader.}
proc mpd_maxcoeff*(result: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_maxcoeff", header: cHeader.}
proc mpd_sset_ssize*(result: ptr mpd_t; a: mpd_ssize_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_sset_ssize", header: cHeader.}
proc mpd_sset_i32*(result: ptr mpd_t; a: int32; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_sset_i32", header: cHeader.}
proc mpd_sset_uint*(result: ptr mpd_t; a: mpd_uint_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_sset_uint", header: cHeader.}
proc mpd_sset_u32*(result: ptr mpd_t; a: uint32; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_sset_u32", header: cHeader.}
proc mpd_set_ssize*(result: ptr mpd_t; a: mpd_ssize_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_set_ssize", header: cHeader.}
proc mpd_set_i32*(result: ptr mpd_t; a: int32; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_set_i32", header: cHeader.}
proc mpd_set_uint*(result: ptr mpd_t; a: mpd_uint_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_set_uint", header: cHeader.}
proc mpd_set_u32*(result: ptr mpd_t; a: uint32; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_set_u32", header: cHeader.}
when not defined(LEGACY_COMPILER):
  proc mpd_set_i64*(result: ptr mpd_t; a: int64; ctx: ptr mpd_context_t) {.cdecl,
      importc: "mpd_set_i64", header: cHeader.}
  proc mpd_set_u64*(result: ptr mpd_t; a: uint64; ctx: ptr mpd_context_t) {.cdecl,
      importc: "mpd_set_u64", header: cHeader.}
proc mpd_get_ssize*(a: ptr mpd_t; ctx: ptr mpd_context_t): mpd_ssize_t {.cdecl,
    importc: "mpd_get_ssize", header: cHeader.}
proc mpd_get_uint*(a: ptr mpd_t; ctx: ptr mpd_context_t): mpd_uint_t {.cdecl,
    importc: "mpd_get_uint", header: cHeader.}
proc mpd_abs_uint*(a: ptr mpd_t; ctx: ptr mpd_context_t): mpd_uint_t {.cdecl,
    importc: "mpd_abs_uint", header: cHeader.}
proc mpd_get_i32*(a: ptr mpd_t; ctx: ptr mpd_context_t): int32 {.cdecl,
    importc: "mpd_get_i32", header: cHeader.}
proc mpd_get_u32*(a: ptr mpd_t; ctx: ptr mpd_context_t): uint32 {.cdecl,
    importc: "mpd_get_u32", header: cHeader.}
when not defined(LEGACY_COMPILER):
  proc mpd_get_i64*(a: ptr mpd_t; ctx: ptr mpd_context_t): int64 {.cdecl,
      importc: "mpd_get_i64", header: cHeader.}
  proc mpd_get_u64*(a: ptr mpd_t; ctx: ptr mpd_context_t): uint64 {.cdecl,
      importc: "mpd_get_u64", header: cHeader.}
proc mpd_and*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_and", header: cHeader.}
proc mpd_copy*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_copy", header: cHeader.}
proc mpd_canonical*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_canonical", header: cHeader.}
proc mpd_copy_abs*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_copy_abs", header: cHeader.}
proc mpd_copy_negate*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_copy_negate", header: cHeader.}
proc mpd_copy_sign*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_copy_sign", header: cHeader.}
proc mpd_invert*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_invert", header: cHeader.}
proc mpd_logb*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_logb", header: cHeader.}
proc mpd_or*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_or", header: cHeader.}
proc mpd_rotate*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_rotate", header: cHeader.}
proc mpd_scaleb*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_scaleb", header: cHeader.}
proc mpd_shiftl*(result: ptr mpd_t; a: ptr mpd_t; n: mpd_ssize_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_shiftl", header: cHeader.}
proc mpd_shiftr*(result: ptr mpd_t; a: ptr mpd_t; n: mpd_ssize_t; ctx: ptr mpd_context_t): mpd_uint_t {.
    cdecl, importc: "mpd_shiftr", header: cHeader.}
proc mpd_shiftn*(result: ptr mpd_t; a: ptr mpd_t; n: mpd_ssize_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_shiftn", header: cHeader.}
proc mpd_shift*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_shift", header: cHeader.}
proc mpd_xor*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_xor", header: cHeader.}
proc mpd_abs*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_abs", header: cHeader.}
proc mpd_cmp*(a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t): cint {.cdecl,
    importc: "mpd_cmp", header: cHeader.}
proc mpd_compare*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t): cint {.
    cdecl, importc: "mpd_compare", header: cHeader.}
proc mpd_compare_signal*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t;
                        ctx: ptr mpd_context_t): cint {.cdecl,
    importc: "mpd_compare_signal", header: cHeader.}
proc mpd_add*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_add", header: cHeader.}
proc mpd_add_ssize*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_ssize_t;
                   ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_add_ssize",
    header: cHeader.}
proc mpd_add_i32*(result: ptr mpd_t; a: ptr mpd_t; b: int32; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_add_i32", header: cHeader.}
proc mpd_add_uint*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_uint_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_add_uint", header: cHeader.}
proc mpd_add_u32*(result: ptr mpd_t; a: ptr mpd_t; b: uint32; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_add_u32", header: cHeader.}
proc mpd_sub*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_sub", header: cHeader.}
proc mpd_sub_ssize*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_ssize_t;
                   ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_sub_ssize",
    header: cHeader.}
proc mpd_sub_i32*(result: ptr mpd_t; a: ptr mpd_t; b: int32; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_sub_i32", header: cHeader.}
proc mpd_sub_uint*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_uint_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_sub_uint", header: cHeader.}
proc mpd_sub_u32*(result: ptr mpd_t; a: ptr mpd_t; b: uint32; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_sub_u32", header: cHeader.}
proc mpd_div*(q: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_div", header: cHeader.}
proc mpd_div_ssize*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_ssize_t;
                   ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_div_ssize",
    header: cHeader.}
proc mpd_div_i32*(result: ptr mpd_t; a: ptr mpd_t; b: int32; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_div_i32", header: cHeader.}
proc mpd_div_uint*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_uint_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_div_uint", header: cHeader.}
proc mpd_div_u32*(result: ptr mpd_t; a: ptr mpd_t; b: uint32; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_div_u32", header: cHeader.}
proc mpd_divmod*(q: ptr mpd_t; r: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t;
                ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_divmod",
                                       header: cHeader.}
proc mpd_divint*(q: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_divint", header: cHeader.}
proc mpd_exp*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_exp", header: cHeader.}
proc mpd_fma*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; c: ptr mpd_t;
             ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_fma",
                                    header: cHeader.}
proc mpd_ln*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_ln", header: cHeader.}
proc mpd_log10*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_log10", header: cHeader.}
proc mpd_max*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_max", header: cHeader.}
proc mpd_max_mag*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_max_mag", header: cHeader.}
proc mpd_min*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_min", header: cHeader.}
proc mpd_min_mag*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_min_mag", header: cHeader.}
proc mpd_minus*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_minus", header: cHeader.}
proc mpd_mul*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_mul", header: cHeader.}
proc mpd_mul_ssize*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_ssize_t;
                   ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_mul_ssize",
    header: cHeader.}
proc mpd_mul_i32*(result: ptr mpd_t; a: ptr mpd_t; b: int32; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_mul_i32", header: cHeader.}
proc mpd_mul_uint*(result: ptr mpd_t; a: ptr mpd_t; b: mpd_uint_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_mul_uint", header: cHeader.}
proc mpd_mul_u32*(result: ptr mpd_t; a: ptr mpd_t; b: uint32; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_mul_u32", header: cHeader.}
proc mpd_next_minus*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_next_minus", header: cHeader.}
proc mpd_next_plus*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_next_plus", header: cHeader.}
proc mpd_next_toward*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t;
                     ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_next_toward",
    header: cHeader.}
proc mpd_plus*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_plus", header: cHeader.}
proc mpd_pow*(result: ptr mpd_t; base: ptr mpd_t; exp: ptr mpd_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_pow", header: cHeader.}
proc mpd_powmod*(result: ptr mpd_t; base: ptr mpd_t; exp: ptr mpd_t; `mod`: ptr mpd_t;
                ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_powmod",
                                       header: cHeader.}
proc mpd_quantize*(result: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.
    cdecl, importc: "mpd_quantize", header: cHeader.}
proc mpd_rescale*(result: ptr mpd_t; a: ptr mpd_t; exp: mpd_ssize_t;
                 ctx: ptr mpd_context_t) {.cdecl, importc: "mpd_rescale",
                                        header: cHeader.}
proc mpd_reduce*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_reduce", header: cHeader.}
proc mpd_rem*(r: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_rem", header: cHeader.}
proc mpd_rem_near*(r: ptr mpd_t; a: ptr mpd_t; b: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_rem_near", header: cHeader.}
proc mpd_round_to_intx*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_round_to_intx", header: cHeader.}
proc mpd_round_to_int*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_round_to_int", header: cHeader.}
proc mpd_trunc*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_trunc", header: cHeader.}
proc mpd_floor*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_floor", header: cHeader.}
proc mpd_ceil*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_ceil", header: cHeader.}
proc mpd_sqrt*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_sqrt", header: cHeader.}
proc mpd_invroot*(result: ptr mpd_t; a: ptr mpd_t; ctx: ptr mpd_context_t) {.cdecl,
    importc: "mpd_invroot", header: cHeader.}
when not defined(LEGACY_COMPILER):
  proc mpd_add_i64*(result: ptr mpd_t; a: ptr mpd_t; b: int64; ctx: ptr mpd_context_t) {.
      cdecl, importc: "mpd_add_i64", header: cHeader.}
  proc mpd_add_u64*(result: ptr mpd_t; a: ptr mpd_t; b: uint64; ctx: ptr mpd_context_t) {.
      cdecl, importc: "mpd_add_u64", header: cHeader.}
  proc mpd_sub_i64*(result: ptr mpd_t; a: ptr mpd_t; b: int64; ctx: ptr mpd_context_t) {.
      cdecl, importc: "mpd_sub_i64", header: cHeader.}
  proc mpd_sub_u64*(result: ptr mpd_t; a: ptr mpd_t; b: uint64; ctx: ptr mpd_context_t) {.
      cdecl, importc: "mpd_sub_u64", header: cHeader.}
  proc mpd_div_i64*(result: ptr mpd_t; a: ptr mpd_t; b: int64; ctx: ptr mpd_context_t) {.
      cdecl, importc: "mpd_div_i64", header: cHeader.}
  proc mpd_div_u64*(result: ptr mpd_t; a: ptr mpd_t; b: uint64; ctx: ptr mpd_context_t) {.
      cdecl, importc: "mpd_div_u64", header: cHeader.}
  proc mpd_mul_i64*(result: ptr mpd_t; a: ptr mpd_t; b: int64; ctx: ptr mpd_context_t) {.
      cdecl, importc: "mpd_mul_i64", header: cHeader.}
  proc mpd_mul_u64*(result: ptr mpd_t; a: ptr mpd_t; b: uint64; ctx: ptr mpd_context_t) {.
      cdecl, importc: "mpd_mul_u64", header: cHeader.}
## ****************************************************************************
##                           Configuration specific
## ****************************************************************************

when defined(CONFIG_64):
  proc mpd_qsset_i64*(result: ptr mpd_t; a: int64; ctx: ptr mpd_context_t;
                     status: ptr uint32) {.cdecl, importc: "mpd_qsset_i64",
      header: cHeader.}
  proc mpd_qsset_u64*(result: ptr mpd_t; a: uint64; ctx: ptr mpd_context_t;
                     status: ptr uint32) {.cdecl, importc: "mpd_qsset_u64",
      header: cHeader.}
  proc mpd_sset_i64*(result: ptr mpd_t; a: int64; ctx: ptr mpd_context_t) {.cdecl,
      importc: "mpd_sset_i64", header: cHeader.}
  proc mpd_sset_u64*(result: ptr mpd_t; a: uint64; ctx: ptr mpd_context_t) {.cdecl,
      importc: "mpd_sset_u64", header: cHeader.}
## ****************************************************************************
##                        Get attributes of a decimal
## ****************************************************************************

proc mpd_adjexp*(dec: ptr mpd_t): mpd_ssize_t {.cdecl, importc: "mpd_adjexp",
    header: cHeader.}
proc mpd_etiny*(ctx: ptr mpd_context_t): mpd_ssize_t {.cdecl, importc: "mpd_etiny",
    header: cHeader.}
proc mpd_etop*(ctx: ptr mpd_context_t): mpd_ssize_t {.cdecl, importc: "mpd_etop",
    header: cHeader.}
proc mpd_msword*(dec: ptr mpd_t): mpd_uint_t {.cdecl, importc: "mpd_msword",
    header: cHeader.}
proc mpd_word_digits*(word: mpd_uint_t): cint {.cdecl, importc: "mpd_word_digits",
    header: cHeader.}
##  most significant digit of a word

proc mpd_msd*(word: mpd_uint_t): mpd_uint_t {.cdecl, importc: "mpd_msd",
    header: cHeader.}
##  least significant digit of a word

proc mpd_lsd*(word: mpd_uint_t): mpd_uint_t {.cdecl, importc: "mpd_lsd",
    header: cHeader.}
##  coefficient size needed to store 'digits'

proc mpd_digits_to_size*(digits: mpd_ssize_t): mpd_ssize_t {.cdecl,
    importc: "mpd_digits_to_size", header: cHeader.}
##  number of digits in the exponent, undefined for MPD_SSIZE_MIN

proc mpd_exp_digits*(exp: mpd_ssize_t): cint {.cdecl, importc: "mpd_exp_digits",
    header: cHeader.}
proc mpd_iscanonical*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_iscanonical",
    header: cHeader.}
proc mpd_isfinite*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isfinite",
                                      header: cHeader.}
proc mpd_isinfinite*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isinfinite",
                                        header: cHeader.}
proc mpd_isinteger*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isinteger",
                                       header: cHeader.}
proc mpd_isnan*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isnan",
                                   header: cHeader.}
proc mpd_isnegative*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isnegative",
                                        header: cHeader.}
proc mpd_ispositive*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_ispositive",
                                        header: cHeader.}
proc mpd_isqnan*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isqnan",
                                    header: cHeader.}
proc mpd_issigned*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_issigned",
                                      header: cHeader.}
proc mpd_issnan*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_issnan",
                                    header: cHeader.}
proc mpd_isspecial*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isspecial",
                                       header: cHeader.}
proc mpd_iszero*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_iszero",
                                    header: cHeader.}
##  undefined for special numbers

proc mpd_iszerocoeff*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_iszerocoeff",
    header: cHeader.}
proc mpd_isnormal*(dec: ptr mpd_t; ctx: ptr mpd_context_t): cint {.cdecl,
    importc: "mpd_isnormal", header: cHeader.}
proc mpd_issubnormal*(dec: ptr mpd_t; ctx: ptr mpd_context_t): cint {.cdecl,
    importc: "mpd_issubnormal", header: cHeader.}
##  odd word

proc mpd_isoddword*(word: mpd_uint_t): cint {.cdecl, importc: "mpd_isoddword",
    header: cHeader.}
##  odd coefficient

proc mpd_isoddcoeff*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isoddcoeff",
                                        header: cHeader.}
##  odd decimal, only defined for integers

proc mpd_isodd*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isodd",
                                   header: cHeader.}
##  even decimal, only defined for integers

proc mpd_iseven*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_iseven",
                                    header: cHeader.}
##  0 if dec is positive, 1 if dec is negative

proc mpd_sign*(dec: ptr mpd_t): uint8 {.cdecl, importc: "mpd_sign",
                                     header: cHeader.}
##  1 if dec is positive, -1 if dec is negative

proc mpd_arith_sign*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_arith_sign",
                                        header: cHeader.}
proc mpd_radix*(): clong {.cdecl, importc: "mpd_radix", header: cHeader.}
proc mpd_isdynamic*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isdynamic",
                                       header: cHeader.}
proc mpd_isstatic*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isstatic",
                                      header: cHeader.}
proc mpd_isdynamic_data*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isdynamic_data",
    header: cHeader.}
proc mpd_isstatic_data*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isstatic_data",
    header: cHeader.}
proc mpd_isshared_data*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isshared_data",
    header: cHeader.}
proc mpd_isconst_data*(dec: ptr mpd_t): cint {.cdecl, importc: "mpd_isconst_data",
    header: cHeader.}
proc mpd_trail_zeros*(dec: ptr mpd_t): mpd_ssize_t {.cdecl,
    importc: "mpd_trail_zeros", header: cHeader.}
## ****************************************************************************
##                        Set attributes of a decimal
## ****************************************************************************
##  set number of decimal digits in the coefficient

proc mpd_setdigits*(result: ptr mpd_t) {.cdecl, importc: "mpd_setdigits",
                                     header: cHeader.}
proc mpd_set_sign*(result: ptr mpd_t; sign: uint8) {.cdecl, importc: "mpd_set_sign",
    header: cHeader.}
##  copy sign from another decimal

proc mpd_signcpy*(result: ptr mpd_t; a: ptr mpd_t) {.cdecl, importc: "mpd_signcpy",
    header: cHeader.}
proc mpd_set_infinity*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_infinity",
                                        header: cHeader.}
proc mpd_set_qnan*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_qnan",
                                    header: cHeader.}
proc mpd_set_snan*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_snan",
                                    header: cHeader.}
proc mpd_set_negative*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_negative",
                                        header: cHeader.}
proc mpd_set_positive*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_positive",
                                        header: cHeader.}
proc mpd_set_dynamic*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_dynamic",
                                       header: cHeader.}
proc mpd_set_static*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_static",
                                      header: cHeader.}
proc mpd_set_dynamic_data*(result: ptr mpd_t) {.cdecl,
    importc: "mpd_set_dynamic_data", header: cHeader.}
proc mpd_set_static_data*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_static_data",
    header: cHeader.}
proc mpd_set_shared_data*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_shared_data",
    header: cHeader.}
proc mpd_set_const_data*(result: ptr mpd_t) {.cdecl, importc: "mpd_set_const_data",
    header: cHeader.}
proc mpd_clear_flags*(result: ptr mpd_t) {.cdecl, importc: "mpd_clear_flags",
                                       header: cHeader.}
proc mpd_set_flags*(result: ptr mpd_t; flags: uint8) {.cdecl,
    importc: "mpd_set_flags", header: cHeader.}
proc mpd_copy_flags*(result: ptr mpd_t; a: ptr mpd_t) {.cdecl,
    importc: "mpd_copy_flags", header: cHeader.}
## ****************************************************************************
##                             Memory handling
## ****************************************************************************

var mpd_mallocfunc*: proc (size: csize): pointer {.cdecl.}

var mpd_callocfunc*: proc (nmemb: csize; size: csize): pointer {.cdecl.}

var mpd_reallocfunc*: proc (`ptr`: pointer; size: csize): pointer {.cdecl.}

var mpd_free*: proc (`ptr`: pointer) {.cdecl.}

proc mpd_callocfunc_em*(nmemb: csize; size: csize): pointer {.cdecl,
    importc: "mpd_callocfunc_em", header: cHeader.}
proc mpd_alloc*(nmemb: mpd_size_t; size: mpd_size_t): pointer {.cdecl,
    importc: "mpd_alloc", header: cHeader.}
proc mpd_calloc*(nmemb: mpd_size_t; size: mpd_size_t): pointer {.cdecl,
    importc: "mpd_calloc", header: cHeader.}
proc mpd_realloc*(`ptr`: pointer; nmemb: mpd_size_t; size: mpd_size_t; err: ptr uint8): pointer {.
    cdecl, importc: "mpd_realloc", header: cHeader.}
proc mpd_sh_alloc*(struct_size: mpd_size_t; nmemb: mpd_size_t; size: mpd_size_t): pointer {.
    cdecl, importc: "mpd_sh_alloc", header: cHeader.}
proc mpd_qnew*(): ptr mpd_t {.cdecl, importc: "mpd_qnew", header: cHeader.}
proc mpd_new*(ctx: ptr mpd_context_t): ptr mpd_t {.cdecl, importc: "mpd_new",
    header: cHeader.}
proc mpd_qnew_size*(size: mpd_ssize_t): ptr mpd_t {.cdecl, importc: "mpd_qnew_size",
    header: cHeader.}
proc mpd_del*(dec: ptr mpd_t) {.cdecl, importc: "mpd_del", header: cHeader.}
proc mpd_uint_zero*(dest: ptr mpd_uint_t; len: mpd_size_t) {.cdecl,
    importc: "mpd_uint_zero", header: cHeader.}
proc mpd_qresize*(result: ptr mpd_t; size: mpd_ssize_t; status: ptr uint32): cint {.
    cdecl, importc: "mpd_qresize", header: cHeader.}
proc mpd_qresize_zero*(result: ptr mpd_t; size: mpd_ssize_t; status: ptr uint32): cint {.
    cdecl, importc: "mpd_qresize_zero", header: cHeader.}
proc mpd_minalloc*(result: ptr mpd_t) {.cdecl, importc: "mpd_minalloc",
                                    header: cHeader.}
proc mpd_resize*(result: ptr mpd_t; size: mpd_ssize_t; ctx: ptr mpd_context_t): cint {.
    cdecl, importc: "mpd_resize", header: cHeader.}
proc mpd_resize_zero*(result: ptr mpd_t; size: mpd_ssize_t; ctx: ptr mpd_context_t): cint {.
    cdecl, importc: "mpd_resize_zero", header: cHeader.}

type
  DecimalType* = ref[ptr mpd_t]

proc deleteDecimal(x: DecimalType) =
  if not x.isNil:          # Managed by Nim
    assert(not(x[].isNil)) # Managed by MpDecimal
    mpd_del(x[])

proc newDecimal*(): DecimalType =
  ## Initialize a empty DecimalType
  new result, deleteDecimal
  result[] = mpd_qnew()
