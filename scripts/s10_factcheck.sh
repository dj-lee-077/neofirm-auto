#!/usr/bin/env bash
# S10 팩트체크: state/claims.txt 의 주장을 NotebookLM 소스로 판정 → debate/factcheck.md
source "$(dirname "$0")/lib.sh"
is_done S10 && exit 0
[ -s state/claims.txt ] || die "state/claims.txt 없음"
{ echo "아래 각 주장을 노트북 소스에 근거해 '근거 있음 / 근거 없음 / 모순' 중 하나로 판정하고, 근거 있음이면 인용 번호를 붙여라. 표로 답하라."; echo; cat state/claims.txt; } > state/q_fc.txt
nlm ask --prompt-file state/q_fc.txt -n "$(NB)" --json --request-timeout 240 > debate/factcheck.json
ask_to_md debate/factcheck.json debate/factcheck.md "팩트체크"
done_mark S10
