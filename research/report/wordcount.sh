#!/usr/bin/env bash
set -euo pipefail

count=$(texcount -merge report.tex) 

main=$(echo "${count}" \
    | grep "Words in text:" \
    | tail -1 \
    | cut -d : -f2 \
    | sed 's/ //g')

headings=$(echo "${count}" \
    | grep "Words in headers:" \
    | tail -1 \
    | cut -d : -f2 \
    | sed 's/ //g')

captions=$(echo "${count}"\
    | grep "Words outside text (captions, etc.):" \
    | tail -1 \
    | cut -d : -f2 \
    | sed 's/ //g')

echo `expr $main + $headings + $captions `
