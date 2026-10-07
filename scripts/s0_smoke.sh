#!/usr/bin/env bash
# S0 스모크 테스트 (최초 1회): 인증·네트워크·JSON 키 이름 확인 → logs/smoke.md
source "$(dirname "$0")/lib.sh"
command -v notebooklm >/dev/null || die "notebooklm 미설치. 'pip install -r requirements.txt' 실행"
[ -n "${NOTEBOOKLM_AUTH_JSON:-}" ] || die "환경변수 NOTEBOOKLM_AUTH_JSON 없음 (README 2단계)"
notebooklm --version | tee logs/smoke.md
notebooklm auth check --test || die "인증 실패: 쿠키 만료 또는 notebooklm.google.com 도메인 미허용 (README 1·2단계)"

T=state/smoke; mkdir -p "$T"
notebooklm create "smoke-test" --json > "$T/c.json"
SNB=$(jget "$T/c.json" "${ID_KEYS[@]}") || die "노트북 ID 키를 못 찾음: $(cat $T/c.json)"
echo "NeoFirm은 AI로 결과물을 판매하는 전문서비스 기업이다." > "$T/t.md"
notebooklm source add "$T/t.md" -n "$SNB" --json > "$T/s.json"
SID=$(jget "$T/s.json" "${ID_KEYS[@]}") || die "소스 ID 키를 못 찾음: $(cat $T/s.json)"
notebooklm source wait "$SID" -n "$SNB" --timeout 180
notebooklm ask "NeoFirm이 뭐야? 한 문장으로" -n "$SNB" --json > "$T/a.json"

{ echo; echo "## create"; jq -c 'keys' "$T/c.json"
  echo "## source add"; jq -c 'keys' "$T/s.json"
  echo "## ask"; jq -c 'keys' "$T/a.json"; jget "$T/a.json" "${ANSWER_KEYS[@]}" || echo "(답변 키 못 찾음 — lib.sh ANSWER_KEYS 수정 필요)"
  echo; echo "smoke 노트북 ID: $SNB (NotebookLM에서 직접 삭제해도 됨)"; } >> logs/smoke.md
cat logs/smoke.md
done_mark S0
