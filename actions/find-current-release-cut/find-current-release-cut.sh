#!/usr/bin/env bash
set -euo pipefail

DEV_BRANCH="${DEV_BRANCH:-dev}"

git fetch origin --prune --tags

# Current release cut from dev
CUR_CUT=$(git merge-base --fork-point "origin/${DEV_BRANCH}" HEAD || git merge-base "origin/${DEV_BRANCH}" HEAD)

echo "cur_cut=${CUR_CUT}" >> "${GITHUB_OUTPUT}"
echo "Current cut: ${CUR_CUT}"