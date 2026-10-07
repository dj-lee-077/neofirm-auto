#!/usr/bin/env bash
# S6 고정 질문 13개 질의 → research/<ID>.md   (약 5~10분)
source "$(dirname "$0")/lib.sh"
is_done S6 && exit 0
N=$(NB)
TOPIC=$(grep -m1 '^분야:' topic.md | sed 's/^분야:[[:space:]]*//') || die "topic.md에 '분야:' 줄 없음"
[ -n "$TOPIC" ] || die "분야 비어 있음"
first=1
for q in questions/A*.txt questions/B*.txt questions/C*.txt questions/R*.txt; do
  id=$(basename "$q" .txt)
  [ -s "research/$id.md" ] && continue
  sed "s/{{TOPIC}}/$TOPIC/g" "$q" > "state/q_$id.txt"
  extra=(); [ $first = 1 ] && extra=(--new -y); first=0
  nlm ask --prompt-file "state/q_$id.txt" -n "$N" --json --request-timeout 180 "${extra[@]}" > "research/$id.json" \
    || { log "$id 실패(건너뜀)"; continue; }
  ask_to_md "research/$id.json" "research/$id.md" "$id $(head -1 "$q")"
  sleep 3
done
miss=0; for q in questions/[ABCR]*.txt; do id=$(basename "$q" .txt); [ "$(wc -m < research/$id.md 2>/dev/null || echo 0)" -ge 200 ] || { log "부족: $id"; miss=$((miss+1)); }; done
[ $miss -le 2 ] || die "질의 결과 부족 $miss 개"
done_mark S6
