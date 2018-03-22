#!/bin/sh


./gettests.sh || exit 1

printf "\n# ========================================================================\n"
printf "#                             static library\n"
printf "# ========================================================================\n\n"

printf "Running official tests ...\n\n"

if  ! ./runtest official.decTest
then
    printf "\nFAIL\n\n\n"
    exit 1
fi

printf "Running additional tests ...\n\n"

if ! ./runtest additional.decTest
then
    printf "\nFAIL\n\n\n"
    exit 1
fi


printf "\n# ========================================================================\n"
printf "#                             shared library\n"
printf "# ========================================================================\n\n"

printf "Running official tests ...\n\n"

if  ! LD_LIBRARY_PATH=../libmpdec ./runtest_shared official.decTest
then
    printf "\nFAIL\n\n\n"
    exit 1
fi

printf "Running additional tests ...\n\n"

if ! LD_LIBRARY_PATH=../libmpdec ./runtest_shared additional.decTest
then
    printf "\nFAIL\n\n\n"
    exit 1
fi



