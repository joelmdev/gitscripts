#!/usr/bin/env bash
#
# Auto-tag dev / test / prod merges.
#
set -euo pipefail

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

version_lt() {                 # v1 v2 → true if v1 < v2
  local v1=$1 v2=$2
  read M1 m1 p1 <<<"$(parse_semver "$v1")"
  read M2 m2 p2 <<<"$(parse_semver "$v2")"
  [[ $M1 -lt $M2 ]] || [[ $M1 -eq $M2 && $m1 -lt $m2 ]] || [[ $M1 -eq $M2 && $m1 -eq $m2 && $p1 -le $p2 ]]
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
  || die "Failed to read current branch"

[[ $branch =~ ^(dev|test|prod)$ ]] || exit 0
echo "Auto-tagging $branch"

today=$(date -u +'%y%m%d')

if [[ $branch == dev ]]; then
  # Get the latest dev tag
  base=$(latest_tag 'v*-dev.*' 0)
  echo "Latest dev tag is $base"
  
  # Get latest rc and release tags for comparison
  latest_rc=$(latest_tag 'v*-rc.*' 0)
  latest_release=$(latest_tag '^v[0-9]*.[0-9]*.[0-9]*$' 0)
  
  if [[ -z $base ]]; then
      # Check if we have any rc or release tags to base version on
      if [[ -n $latest_rc ]]; then
          base=$latest_rc
          echo "Using latest rc tag as base: $base"
      elif [[ -n $latest_release ]]; then
          base=$latest_release
          echo "Using latest release tag as base: $base"
      else
          # first ever tag → ask if TTY, else 0.1.0
          if [[ -t 0 ]]; then
            read -rp "Initial SemVer (e.g. 0.1.0): " semver
          else
            semver="0.1.0"
          fi
          build=1
          tag="v$semver-dev.$today.$build"
          new_tag "$tag" "auto-tag: dev merge"
          exit 0
      fi
  fi

  # If we have a base tag, parse it and ensure we bump appropriately
  if [[ -n $base ]]; then
      read M m p <<<"$(parse_semver "$base")"
      
      # Check if any rc or release tags are greater than our dev tag
      if [[ -n $latest_rc ]]; then
          if version_lt "$base" "$latest_rc"; then
              die "Found rc tag ($latest_rc) greater than dev tag ($base). This may indicate an invalid repository state."
          fi
      fi
      
      if [[ -n $latest_release ]]; then
          if version_lt "$base" "$latest_release"; then
              die "Found release tag ($latest_release) greater than dev tag ($base). This may indicate an invalid repository state."
          fi
      fi
      
      if [[ -t 0 ]]; then
          read -rp \
            "Bump [major/minor/patch/build] from $M.$m.$p (default patch): " part || true
          part=${part:-patch}
      else
          part="patch"
      fi
      if [[ $part == "build" ]]; then
          semver="$M.$m.$p"
      else
          semver=$(bump_semver "$M" "$m" "$p" "$part")
      fi
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
  new_tag "$tag" "auto-tag: release candidate"

elif [[ $branch == prod ]]; then
  rc_tag=$(latest_tag 'v*-rc.*' 1) \
    || die "no rc tag merged into prod"
  semver=$(sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+)-rc.*/\1/' <<<"$rc_tag")
  tag="v$semver"
  new_tag "$tag" "auto-tag: production release"

else
  echo "auto-tag - Invalid branch: $branch"
  exit 1

fi
