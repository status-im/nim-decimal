# Decimal
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# Note, we do not use nimscript because:
#   - potential data loss due to nimsuggest: https://github.com/pragmagic/vscode-nim/issues/84
#   - copydir feature request: https://github.com/nim-lang/Nim/issues/7393
#     - several other features are missing like concatenation of files
#
# Bash is not ideal though for portability and testing on Windows especially
# Alternatives include:
#   - Deactivating nimsuggest for .nims files
#   - Never have global `exec` statement, always wrapped in a proc that must be manually executed
#   - Use a .nim file instead, that must be compiled then run.

# $$ is replaced by the pid of the process in bash

#!/bin/sh

set -e # Error kills the script

THIS_DIR=$(dirname "$0")
SRCDIR="${THIS_DIR}"/mpdecimal_sources
WORKDIR="${THIS_DIR}"/mpdecimal_temp.$$
LIBMPDECDIR="${WORKDIR}"/libmpdec
MPDECIMAL_HEADER="${LIBMPDECDIR}"/mpdecimal.h
TMP_MPDECIMAL_HEADER="${LIBMPDECDIR}"/mpdecimal.h.tmp.$$
DESTDIR="${THIS_DIR}"/generated

mpdec_header="
/*
 *
 * mpdecimal.h
 * Auto generated for https://github.com/status-im/nim-decimal
 * This file is platform dependant, make sure you run 'nim e genSources.sh'
 * to get the best support for your platform.
 *
 */

"

# 1. Create a workspace directory
cp -r "${SRCDIR}" "${WORKDIR}"
cd "${WORKDIR}"

# 2. Run .configure and go back to current working dir
./configure
cd -

# 3. We prepend config.h to mpdecimal.h and also add the header
cat <(echo "${mpdec_header}") "${WORKDIR}"/config.h <(echo "${mpdec_header}") "${MPDECIMAL_HEADER}" > "${TMP_MPDECIMAL_HEADER}"
mv "${TMP_MPDECIMAL_HEADER}" "${MPDECIMAL_HEADER}"

# 4. Copy the C sources to the destination folder
mkdir -p "${DESTDIR}"
cp "${LIBMPDECDIR}"/*.{c,h} "${DESTDIR}"

# 5. Delete the working dir
rm -r "${WORKDIR}"
