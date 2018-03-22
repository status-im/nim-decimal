# Decimal
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import strutils, macros, ospaths
from os import DirSep, walkFiles

const csourcesPath = currentSourcePath.rsplit(DirSep, 1)[0] & "/mpdecimal_wrapper/generated"
{.passC: "-I" & csourcesPath .}
{.passC: "-DHAVE_CONFIG_H".}

# {.deadCodeElim: on.}
{.pragma: decimal, importc, cdecl.}

when isMainModule:
  type
    mpd_context_t {.importc.} = object
    mpd_t {.importc.} = object
    mpd_ssize_t {.importc.} = int # TODO: check size on 32-bit

  proc mpd_init(ctx: ptr mpd_context_t, prec: mpd_ssize_t){.importc.}


  # var ctx: mpd_context_t

  echo "yes"
