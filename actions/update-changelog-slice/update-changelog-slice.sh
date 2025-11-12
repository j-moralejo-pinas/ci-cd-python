#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
# - PAT_TOKEN: token for GitHub CLI auth
# - PRS: space-separated list of PR numbers
# - VERSION: tag for the new changelog entry (e.g., vX.Y.Z)
# - CHANGELOG_PATH: path to changelog (default CHANGELOG.rst)

PAT_TOKEN="${PAT_TOKEN:-}"
PRS="${PRS:-}"
VERSION="${VERSION:-}"
CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.rst}"

if [[ -z "${PRS// /}" ]]; then
  echo "No PR numbers provided; using last commit message." >&2
  # Get last commit message and keep only '- <Word>:' lines
  CHANGELOG_WORDS="$(git log -1 --pretty=%B | awk '/^- [[:alpha:]]+: /')"
  
  echo "Collected lines from commit message:"
  printf '%s\n' "$CHANGELOG_WORDS"
else
  # 1) Get PR bodies and keep only '- <Word>:' lines
  CHANGELOG_WORDS="$({
    # Convert space-separated PR numbers to array and process each
    for n in ${PRS}; do
      [[ -z "$n" ]] && continue
      gh pr view "$n" --json body --jq '.body // ""'
    done \
    | awk '/^- [[:alpha:]]+: /'
  })"

  echo "Collected lines from PR bodies:"
  printf '%s\n' "$CHANGELOG_WORDS"
fi

# 2) Format grouped changelog in RST format
CHANGELOG_RST="$({
  awk '
    match($0,/^-[[:space:]]+([A-Za-z]+):[[:space:]]*(.*)$/,m){
      w=m[1]; t=m[2]
      sub(/^[[:space:]]+|[[:space:]]+$/,"",t)
      if(!(w in seen)){ seen[w]=1; ord[++n]=w }
      if(length(t)) items[w]=items[w] "- " t ORS
    }
    END{
      for(i=1;i<=n;i++){
        w=ord[i]
        printf "%s\n", w
        underline=w
        gsub(/./, "-", underline)
        printf "%s\n", underline
        printf "%s\n", items[w]
      }
    }
  ' <<< "$CHANGELOG_WORDS"
})"

printf '%s\n' "$CHANGELOG_RST"

# 3) Prepend entry to CHANGELOG
DATE="$(date -u +%Y-%m-%d)"
# Create RST-style header with underline
HEADER="${VERSION} - ${DATE}"
HEADER_UNDERLINE=$(printf '%*s' ${#HEADER} | tr ' ' '=')
VERSION_HEADER="${HEADER}"$'\n'"${HEADER_UNDERLINE}"

# Always write changelog entry, even if no content
if [[ -z "${CHANGELOG_RST// }" ]]; then
  echo "No changelog content found. Writing version header only."
  CHANGELOG_CONTENT="${VERSION_HEADER}"
else
  CHANGELOG_CONTENT="${VERSION_HEADER}"$'\n\n'"${CHANGELOG_RST}"
fi

# Define the standard changelog header
CHANGELOG_HEADER="=========
Changelog
=========

Sources to write the changelog:

- https://keepachangelog.com/en/1.0.0/
- https://semver.org/"

if [[ -f "${CHANGELOG_PATH}" ]]; then
  # Find the first semver line (vX.Y.Z format) and get everything from that point onward
  EXISTING_VERSIONS=$(awk '/^v[0-9]+(\.[0-9]+)?(\.[0-9]+)?([[:space:]]+.*)?$/{print NR; exit}' "${CHANGELOG_PATH}" || echo "")

  if [[ -n "$EXISTING_VERSIONS" ]]; then
    # Extract content from the first semver line onward
    EXISTING_CONTENT=$(tail -n +${EXISTING_VERSIONS} "${CHANGELOG_PATH}")
    # Create new file with header, new content, and existing versions
    { printf '%s\n\n\n' "$CHANGELOG_HEADER"
      printf '%s\n\n' "$CHANGELOG_CONTENT"
      printf '%s\n' "$EXISTING_CONTENT"; } > "${CHANGELOG_PATH}.new"
  else
    # No existing versions found, just add header and new content
    { printf '%s\n\n\n' "$CHANGELOG_HEADER"
      printf '%s\n\n' "$CHANGELOG_CONTENT"; } > "${CHANGELOG_PATH}.new"
  fi
else
  # File doesn't exist, create with header and content
  { printf '%s\n\n\n' "$CHANGELOG_HEADER"
    printf '%s\n\n' "$CHANGELOG_CONTENT"; } > "${CHANGELOG_PATH}.new"
fi

mv "${CHANGELOG_PATH}.new" "${CHANGELOG_PATH}"
