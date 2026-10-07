#!/usr/bin/env bash
# SessionStart 훅: 클라우드 세션에서만 notebooklm-py 설치. 로컬에서는 아무것도 안 함.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
command -v notebooklm >/dev/null 2>&1 && exit 0
pip install --quiet --break-system-packages -r "$CLAUDE_PROJECT_DIR/requirements.txt" >/dev/null 2>&1 \
  || pip install --quiet -r "$CLAUDE_PROJECT_DIR/requirements.txt" >/dev/null 2>&1 || true
exit 0
