#!/usr/bin/env bash
set -euo pipefail

PROJECT="Maze 100.xcodeproj"
SCHEME="Maze 100 UITests"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$(pwd)/.codex-derived-data/ui-tests}"

resolve_destination() {
  if [[ $# -ge 1 && -n "${1:-}" ]]; then
    printf '%s\n' "$1"
    return
  fi

  if [[ -n "${IOS_UI_TEST_DESTINATION:-}" ]]; then
    printf '%s\n' "$IOS_UI_TEST_DESTINATION"
    return
  fi

  local simulator_id
  simulator_id="$(
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null \
      | grep 'platform:iOS Simulator' \
      | grep -v 'placeholder' \
      | grep 'arch:arm64' \
      | awk -F'id:|, OS:|, name:' '{
          id=$2; os=$3;
          gsub(/^[ \t]+|[ \t]+$/, "", id);
          gsub(/^[ \t]+|[ \t]+$/, "", os);
          if (id != "" && os != "") print os " " id;
        }' \
      | sort -Vr \
      | awk 'NR==1 { print $2 }'
  )"

  if [[ -z "$simulator_id" ]]; then
    echo "Unable to auto-detect an iOS Simulator destination for UI tests." >&2
    exit 1
  fi

  printf 'id=%s\n' "$simulator_id"
}

DESTINATION="$(resolve_destination "${1:-}")"
echo "Running UI smoke tests with destination: $DESTINATION"

SMOKE_TESTS=(
  "-only-testing:Maze 100UITests/Maze_100UITests/testSettingsSheetOpensAndCloses"
  "-only-testing:Maze 100UITests/Maze_100UITests/testLevelOneLaunchPauseAndResume"
)

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -parallel-testing-enabled NO \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -parallel-testing-enabled NO \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  "${SMOKE_TESTS[@]}" \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
