#!/usr/bin/env bash
#
# Auto-tag dev / test / prod merges.
#
set -euo pipefail

# ── opt-in gate ───────────────────────────────────────────────────────────────
# Tagging runs ONLY when `git config release.autoTag` is true.
enabled=$(git config --bool --get release.autoTag || echo "false")
[[ $enabled == true ]] || exit 0    # silently skip if opt-in is off

# ── helpers ───────────────────────────────────────────────────────────────────
die() { echo "🔥  $*" >&2; exit 1; }

latest_tag() {                 # $1 pattern, $2 "merged" (0/1)
  git tag ${2:+--merged HEAD} --list "$1" --sort=-creatordate | head -n1
}

parse_semver() {               # vX.Y.Z →  X Y Z
  [[ $1 =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+) ]] \
    || die "bad SemVer: $1"
  echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
}

bump_semver() {                # M m p bumpKind
  local M=$1 m=$2 p=$3
  case $4 in
    major) ((M++, m=0, p=0));;
    minor) ((m++, p=0));;
    patch) ((p++));;
  esac; echo "$M.$m.$p"
}

next_build() {                 # semver suffix date
  local latest=$(latest_tag "v$1-$2.$3.*" 0)
  [[ -z $latest ]] && echo 1 || echo $(( ${latest##*.} + 1 ))
}

new_tag() {                    # tag message
  git tag -a "$1" -m "$2"
  git push origin "$1"
  echo "✅  created tag $1"
}

# ── main logic ────────────────────────────────────────────────────────────────
branch=$(git symbolic-ref --quiet --short HEAD) \
  || die "cannot detect branch"
[[ $branch =~ ^(dev|test|prod)$ ]] || exit 0

today=$(date -u +'%y%m%d')

if [[ $branch == dev ]]; then
  base=$(latest_tag 'v*' 0 | grep -v '\-dev\.')
  if [[ -z $base ]]; then
      # first ever dev tag → ask if TTY, else 0.1.0
      if [[ -t 0 ]]; then
        read -rp "Initial SemVer (e.g. 0.1.0): " semver
      else
        semver="0.1.0"
      fi
  else
      read M m p <<<"$(parse_semver "$base")"
      if [[ -t 0 ]]; then
        read -rp \
          "Bump [major/minor/patch] from $M.$m.$p (default patch): " part || true
        part=${part:-patch}
      else
        part="patch"
      fi
      semver=$(bump_semver "$M" "$m" "$p" "$part")
  fi
  build=$(next_build "$semver" dev "$today")
  tag="v$semver-dev.$today.$build"
  new_tag "$tag" "auto-tag: dev merge"

elif [[ $branch == test ]]; then
  dev_tag=$(latest_tag 'v*-dev.*' 1) \
    || die "no dev tag merged into test"
  semver=$(sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+)-dev.*/\1/' <<<"$dev_tag")
  build=$(next_build "$semver" rc "$today")
  tag="v$semver-rc.$today.$build"
  new_tag "$tag" "auto-tag: rc"

else  # prod
  rc_tag=$(latest_tag 'v*-rc.*' 1) \
    || die "no rc tag merged into prod"
  semver=$(sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+)-rc.*/\1/' <<<"$rc_tag")
  tag="v$semver"
  new_tag "$tag" "auto-tag: prod release"
fi
