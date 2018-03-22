#!/bin/sh


./gettests.sh || exit 1

printf "\n# ========================================================================\n"
printf "#                             static library\n"
printf "# ========================================================================\n\n"

printf "Running official tests with allocation failures ...\n\n"

if  ! ./runtest_alloc official.decTest
then
    printf "\nFAIL\n\n\n"
    exit 1
fi

printf "Running additional tests with allocation failures ...\n\n"

if ! ./runtest_alloc additional.decTest
then
    printf "\nFAIL\n\n\n"
    exit 1
fi


printf "\n# ========================================================================\n"
printf "#                             shared library\n"
printf "# ========================================================================\n\n"

printf "Running official tests with allocation failures ...\n\n"

if  ! LD_LIBRARY_PATH=../libmpdec ./runtest_alloc_shared official.decTest
then
    printf "\nFAIL\n\n\n"
    exit 1
fi

printf "Running additional tests with allocation failures ...\n\n"

if ! LD_LIBRARY_PATH=../libmpdec ./runtest_alloc_shared additional.decTest
then
    printf "\nFAIL\n\n\n"
    exit 1
fi



