#!/usr/bin/env bash
set -euo pipefail

texcount -merge report.tex  \
    | grep "Words in text:" \
    | tail -1 \
    | cut -d : -f2 \
    | sed 's/ //g'

