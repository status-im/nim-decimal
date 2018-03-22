# Decimal
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import strutils, macros
from os import DirSep, walkFiles

const csourcesPath = currentSourcePath.rsplit(DirSep, 1)[0] & "/mpdecimal_wrapper/generated"
{.passC: "-I" & csourcesPath .}
{.passC: "-DHAVE_CONFIG_H".}

# {.deadCodeElim: on.}
{.pragma: decimal, importc, cdecl.}

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

compileFilesFromDir("mpdecimal_wrapper/generated/"):
  "mpdecimal.c"
  "mpsignal.c"
  "context.c"
  "io.c"
  "memory.c"

when isMainModule:
  type
    mpd_context_t {.importc.} = object
    mpd_t {.importc.} = object
    mpd_ssize_t {.importc.} = int # TODO: check size on 32-bit

  proc mpd_init(ctx: ptr mpd_context_t, prec: mpd_ssize_t){.importc.}


  # var ctx: mpd_context_t

