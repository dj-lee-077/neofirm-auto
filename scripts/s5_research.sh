#!/usr/bin/env bash
# S5 웹 리서치 (NotebookLM 서버에서 실행됨, 10~25분). 백그라운드 실행 권장:
#   bash scripts/s5_research.sh > logs/s5.out 2>&1 &
source "$(dirname "$0")/lib.sh"
is_done S5 && exit 0
N=$(NB)
[ -s state/research_deep.txt ] && [ -s state/research_fast.txt ] || die "S4 산출물(state/research_*.txt) 없음"

log "딥리서치 시작"
nlm source add-research --prompt-file state/research_deep.txt --mode deep --no-wait -n "$N"
notebooklm research wait -n "$N" --timeout 1500 --interval 15 --import-all --cited-only --json > state/research_deep.json \
  || log "딥리서치 대기 실패/시간초과 — fast로 보완"

log "규제 fast 리서치"
nlm source add-research --prompt-file state/research_fast.txt --mode fast --import-all --cited-only -n "$N" || true

notebooklm source clean -y -n "$N" || true
notebooklm source list -n "$N" --json > state/sources.json
CNT=$(jq '[(.sources // .)[]?] | length' state/sources.json 2>/dev/null || echo 0)
log "소스 수: $CNT"
if [ "$CNT" -lt 5 ]; then
  log "소스 부족 → fast 1회 추가"
  nlm source add-research --prompt-file state/research_deep.txt --mode fast --import-all -n "$N" || true
  notebooklm source list -n "$N" --json > state/sources.json
  CNT=$(jq '[(.sources // .)[]?] | length' state/sources.json 2>/dev/null || echo 0)
fi
[ "$CNT" -ge 3 ] || die "소스가 3개 미만 ($CNT)"
done_mark S5
