# NeoFirm 자동화 (과제 #6-2) — Claude Code 클라우드 세션용

몰입캠프 2일차 NeoFirm 과제를 **자료조사 → AI 에이전트 토론 → 발표자료**까지 사람 개입 없이 만든다.
실행: 세션에서 `/neofirm auto` (또는 `/neofirm 기업 계약` 처럼 분야 지정).

## 역할 분담 (반드시 지킬 것)
- **NotebookLM 호출은 `scripts/` 의 셸 스크립트로만 한다.** `notebooklm` 명령을 직접 지어내지 않는다. 필요한 명령은 이미 스크립트에 있다.
- **무거운 읽기는 NotebookLM이 한다.** `input/report.pdf` 와 웹 원문을 직접 Read 하지 않는다. NotebookLM 답변(`research/*.md`)만 읽는다.
- **토론은 서브에이전트가 한다.** `neofirm-founder`, `neofirm-vc`, `neofirm-regulator`, `neofirm-judge`. 각자 자기 파일 하나만 쓴다.
- 단계 간 전달은 파일로만 한다. 대화에 긴 내용을 붙여넣지 않는다.

## 금지
- `notebooklm language set` (계정 전체 설정이 바뀜) — 생성 시 `--language ko` 사용
- `notebooklm delete`, `auth logout`, `share` (공유는 사람이 직접)
- notebooklm-py 업그레이드
- NotebookLM 명령 병렬 실행 (비공식 API, rate limit)

## 상태
- `state/notebook_id` 가 있으면 그 노트북을 재사용한다.
- `state/S<번호>.done` 이 있는 단계는 건너뛴다. 실패하면 원인을 `logs/ERROR.md` 에 쓰고 멈춘다.
- 대기가 긴 스크립트(S5, S12)는 백그라운드로 실행하고 완료를 기다린다.

## 수치·사실
모든 수치에 출처 ID(`[A2]` 등 research 파일명)를 붙인다. 출처 없는 것은 "가정:"으로 쓴다.
