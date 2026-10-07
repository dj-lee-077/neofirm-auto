#!/usr/bin/env bash
# 공통 함수. 모든 단계 스크립트가 source 한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p state research debate output logs

log()  { echo "[$(date +%H:%M:%S)] $*" | tee -a logs/run.log >&2; }
die()  { echo "## $(date '+%F %T') $*" >> logs/ERROR.md; log "실패: $*"; exit 1; }
done_mark() { touch "state/$1.done"; log "$1 완료"; }
is_done()   { [ -f "state/$1.done" ]; }

NB() { [ -s state/notebook_id ] || die "state/notebook_id 없음 (S2 먼저)"; cat state/notebook_id; }

# JSON에서 첫 번째로 비어있지 않은 키를 꺼낸다. 키 이름이 버전마다 달라도 버티도록 후보를 여러 개 둔다.
jget() { # jget file '.a' '.b' ...
  local f="$1"; shift; local v
  for k in "$@"; do v=$(jq -r "$k // empty" "$f" 2>/dev/null | head -1); [ -n "$v" ] && { echo "$v"; return 0; }; done
  return 1
}
ID_KEYS=('.id' '.notebook_id' '.notebook.id' '.source_id' '.source.id' '.data.id')
TASK_KEYS=('.task_id' '.artifact_id' '.id' '.artifact.id')
ANSWER_KEYS=('.answer' '.response' '.text' '.content')

# notebooklm 호출 래퍼: 실패 시 30초 후 1회 재시도
nlm() {
  if notebooklm "$@"; then return 0; fi
  log "재시도: notebooklm $*"; sleep 30
  notebooklm "$@"
}

# ask 결과 JSON -> 본문 + 인용 마크다운
ask_to_md() { # ask_to_md in.json out.md title
  { echo "# $3"; echo
    jget "$1" "${ANSWER_KEYS[@]}" || jq -r '.' "$1"
    echo; echo "## 인용"
    jq -r '(.references // .citations // .sources // [])[]? | "- [\(.citation_number // .index // "-")] \(.title // .source_title // .source_id // "")"' "$1" 2>/dev/null || true
  } > "$2"
}
