#!/usr/bin/env bash
set -euo pipefail

texcount -merge report.tex chapters/abstract.tex chapters/background.tex chapters/classical_approach.tex chapters/conclusion.tex chapters/evaluation.tex chapters/introduction.tex chapters/literature_review.tex \
    | grep "Words in text:" \
    | tail -1 \
    | cut -d : -f2 \
    | sed 's/ //g'

