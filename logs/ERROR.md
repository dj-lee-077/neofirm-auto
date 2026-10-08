# ERROR
S0: NOTEBOOKLM_AUTH_JSON 가 유효한 JSON이 아님 (길이 32). input/report.pdf 도 없음.
## 2026-10-08 01:37:27 인증 실패: 쿠키 만료 또는 notebooklm.google.com 도메인 미허용 (README 1·2단계)
## 2026-10-08 01:39:22 인증 실패: 쿠키 만료 또는 notebooklm.google.com 도메인 미허용 (README 1·2단계)
## 2026-10-08 04:17:27 F0 답변이 너무 짧음
## 2026-10-08 05:04 S12 중단: NotebookLM 세션 쿠키 무효화 (CSRF token not found). 05:04 이후 source add 전부 실패. 쿠키 재발급 후 새 세션에서 /neofirm auto 실행 시 S12부터 재개 (S0~S11 .done).
## 2026-10-08 05:56 S12 재시도 실패: source add RPCError rpc_code=3 (인증 쿠키 여전히 무효). 쿠키 재발급(README 1·2단계) 후 /neofirm auto 재실행 필요.
## 2026-10-08 06:02 S12 원인 정정: 쿠키는 유효, 노트북 소스 50개 한도로 source add 실패. 소스 일부 삭제 후 S12 재개 필요.
## 2026-10-08 06:14 S12: 웹 UI는 소스 45개, CLI는 50개(삭제한 4개 그대로 보임) — 쓰기는 rpc_code=9(FAILED_PRECONDITION). 계정/세션 불일치 의심.
## 2026-10-08 06:21 S12: 사용자가 14개 삭제 후에도 CLI는 소스 50개 → CLI 쿠키 계정이 브라우저와 다름. 쿠키 재발급 필요.
