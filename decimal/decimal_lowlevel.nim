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
{.pragma: Pdecimal, importc, cdecl.}
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


type
  mpd_context_t {.Tdecimal.} = object
  mpd_t {.Tdecimal.} = object
  mpd_ssize_t {.Tdecimal.} = int # TODO: check size on 32-bit

proc mpd_init(ctx: ptr mpd_context_t, prec: mpd_ssize_t){.Pdecimal.}

when isMainModule:

  var ctx: mpd_context_t

  mpd_init(addr ctx, 48)

  echo "yes"
