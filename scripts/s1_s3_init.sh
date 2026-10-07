#!/usr/bin/env bash
# S1 사전점검 · S2 노트북 · S3 리포트 업로드 + 분석틀 추출
source "$(dirname "$0")/lib.sh"

# S1
if ! is_done S1; then
  [ -s input/report.pdf ] || die "input/report.pdf 없음 (NeoFirm Report를 PDF로 커밋)"
  notebooklm auth check --test >/dev/null || die "NotebookLM 인증 실패 (README 2단계로 쿠키 갱신)"
  done_mark S1
fi

# S2
if ! is_done S2; then
  if [ -s state/notebook_id ] && notebooklm metadata -n "$(cat state/notebook_id)" --json >/dev/null 2>&1; then
    log "기존 노트북 재사용: $(cat state/notebook_id)"
  else
    nlm create "NeoFirm-$(date +%m%d-%H%M)" --json > state/create.json
    jget state/create.json "${ID_KEYS[@]}" > state/notebook_id || die "노트북 ID 파싱 실패"
  fi
  done_mark S2
fi

# S3
if ! is_done S3; then
  N=$(NB)
  if [ ! -s state/src_report ]; then
    nlm source add input/report.pdf -n "$N" --title "NeoFirm Report" --json > state/src_report.json
    jget state/src_report.json "${ID_KEYS[@]}" > state/src_report || die "리포트 소스 ID 파싱 실패"
  fi
  notebooklm source wait "$(cat state/src_report)" -n "$N" --timeout 600 || die "리포트 처리 대기 실패"
  nlm ask --prompt-file questions/F0.txt -n "$N" --json --request-timeout 240 > research/F0.json
  ask_to_md research/F0.json research/F0.md "F0 리포트 분석틀"
  [ "$(wc -m < research/F0.md)" -ge 800 ] || die "F0 답변이 너무 짧음"
  done_mark S3
fi
