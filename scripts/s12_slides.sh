#!/usr/bin/env bash
# S12 결과 문서 업로드 → 한국어 슬라이드 생성 → PDF/PPTX 다운로드 (5~20분). 백그라운드 실행 권장.
source "$(dirname "$0")/lib.sh"
is_done S12 && exit 0
N=$(NB)
for f in output/memo.md debate/debate.md debate/verdict.md state/slides_prompt.txt; do [ -s "$f" ] || die "$f 없음"; done

SRC=(-s "$(cat state/src_report)")
for f in output/memo.md debate/debate.md debate/verdict.md; do
  key=state/src_$(basename "$f" .md)
  if [ ! -s "$key" ]; then
    nlm source add "$f" -n "$N" --json > "$key.json"
    jget "$key.json" "${ID_KEYS[@]}" > "$key" || die "$f 소스 ID 파싱 실패"
  fi
  notebooklm source wait "$(cat "$key")" -n "$N" --timeout 300
  SRC+=(-s "$(cat "$key")")
done

if [ ! -s state/slides_task ]; then
  notebooklm generate slide-deck --prompt-file state/slides_prompt.txt --format detailed --length short \
    --language ko "${SRC[@]}" -n "$N" --json --retry 3 > state/slides_task.json
  jget state/slides_task.json "${TASK_KEYS[@]}" > state/slides_task || die "슬라이드 task_id 파싱 실패"
fi
TID=$(cat state/slides_task)
log "슬라이드 생성 대기: $TID"

retried=0
for i in $(seq 1 80); do   # 15초 × 80 = 20분
  notebooklm artifact poll "$TID" -n "$N" --json > state/slides_poll.json 2>/dev/null || true
  st=$(jget state/slides_poll.json '.status' '.state' '.artifact.status' || echo unknown)
  case "$st" in
    completed|COMPLETED|done|ready) break;;
    failed|FAILED|error)
      [ $retried = 1 ] && die "슬라이드 생성 2회 실패"
      log "생성 실패 → retry"; notebooklm artifact retry "$TID" -n "$N" --wait --timeout 900 || true; retried=1;;
  esac
  sleep 15
done

nlm download slide-deck output/slides.pdf -a "$TID" -n "$N" --force
nlm download slide-deck output/slides.pptx -a "$TID" -n "$N" --format pptx --force
for f in output/slides.pdf output/slides.pptx; do
  [ "$(stat -c%s "$f" 2>/dev/null || echo 0)" -ge 50000 ] || die "$f 가 없거나 너무 작음"
done

if [ "${EXTRA:-0}" = 1 ]; then
  log "토론 오디오 생성(선택)"
  notebooklm generate audio "창업자·VC·규제전문가 토론의 핵심 쟁점" --format debate --length short --language ko \
    "${SRC[@]}" -n "$N" --wait --timeout 1500 && notebooklm download audio output/debate_audio.mp3 -n "$N" --force || log "오디오 실패(무시)"
fi
done_mark S12
