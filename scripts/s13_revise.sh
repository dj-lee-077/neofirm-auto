#!/usr/bin/env bash
# S13 슬라이드 1장 수정(최대 1회) 후 재다운로드.  사용법: s13_revise.sh <0부터 슬라이드번호> "<수정 지시>"
source "$(dirname "$0")/lib.sh"
[ -f state/S13r.done ] && { log "수정은 1회만 허용"; exit 0; }
N=$(NB); TID=$(cat state/slides_task)
notebooklm generate revise-slide "$2" -a "$TID" --slide "$1" -n "$N" --wait --timeout 600 || die "revise-slide 실패"
nlm download slide-deck output/slides.pdf -a "$TID" -n "$N" --force
nlm download slide-deck output/slides.pptx -a "$TID" -n "$N" --format pptx --force
touch state/S13r.done
