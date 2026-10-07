# NeoFirm 자동화 — 과제 #6-2 (Claude Code 클라우드 세션 + NotebookLM CLI)

몰입캠프 2일차 NeoFirm 과제의 **자료조사 → AI 에이전트 토론 → 최종 발표자료**를 사람 개입 없이 만든다.
클라우드 세션에서 `/neofirm auto` 한 줄로 끝까지 돈다. 결과는 이 저장소 브랜치에 커밋·푸시된다.

- NotebookLM CLI: [teng-lin/notebooklm-py](https://github.com/teng-lin/notebooklm-py) (비공식, 브라우저 UI 사용 안 함)
- 토론: `.claude/agents/` 서브에이전트 4개 (창업자 · VC · 규제전문가 · 심사위원)
- 파이프라인 정의: `.claude/skills/neofirm/SKILL.md`

```
S1~S3 노트북+리포트 → S4 주제 → S5 딥리서치 → S6 질문 13개 → S7 브리프
→ S8 토론 R1~R3 (서브에이전트) → S9 심사 → S10 팩트체크
→ S11 메모·원고 → S12 NotebookLM 슬라이드(PDF/PPTX) → S13 검수 → S14 커밋·푸시
```

---

## 준비 (1회, 약 15분)

### 1. 클라우드 환경 만들기
claude.ai/code → 메시지창 위 구름 아이콘 → **Add cloud environment** (기존 Default는 건드리지 않기)

- **Name**: `neofirm`
- **Network access**: **Custom**, *Also include default list* 체크, Allowed domains:
  ```
  notebooklm.google.com
  *.google.com
  *.googleusercontent.com
  *.gstatic.com
  ```
- **Environment variables** (3단계에서 쿠키를 채움):
  ```
  BASH_DEFAULT_TIMEOUT_MS=600000
  BASH_MAX_TIMEOUT_MS=1800000
  NOTEBOOKLM_HL=ko
  NOTEBOOKLM_AUTH_JSON='여기에 3단계 결과 한 줄'
  ```
- **Setup script**:
  ```bash
  #!/bin/bash
  pip install --break-system-packages notebooklm-py || pip install notebooklm-py || true
  ```

### 2. 왜 쿠키를 환경변수로?
클라우드 VM에서는 구글 로그인 창을 띄울 수 없다. 그래서 **내 컴퓨터에서 한 번 로그인**하고 그 쿠키를 `NOTEBOOKLM_AUTH_JSON`으로 넘긴다(notebooklm-py가 CI용으로 공식 지원하는 방식).

> ⚠️ 이 값은 **구글 계정 전체 접근 권한**이다. 환경변수는 그 환경을 쓰는 사람에게 보이므로 **개인 환경에만** 넣고, 과제가 끝나면(10/13 이후) 환경변수를 지우고 `notebooklm auth logout`을 실행할 것. 가능하면 과제용 구글 계정을 쓰자.

### 3. 내 컴퓨터에서 쿠키 뽑기 (Windows는 WSL 또는 PowerShell, Mac은 터미널)
```bash
pip install "notebooklm-py[browser]"
notebooklm login                       # 구글 로그인 창 → 로그인 완료되면 자동 저장
notebooklm auth check --test           # 통과 확인
notebooklm status --paths              # Storage State 경로 확인
jq -c . "<위에서 나온 storage_state.json 경로>"   # 한 줄 JSON 출력 → 복사
```
복사한 한 줄을 1단계 `NOTEBOOKLM_AUTH_JSON='...'`의 따옴표 안에 붙여넣고 저장.
(jq가 없으면 `python -c "import json,sys;print(json.dumps(json.load(open(sys.argv[1]))))" <경로>`)

### 4. 리포트 넣기
NeoFirm Report를 PDF로 받아 `input/report.pdf` 로 커밋·푸시.

---

## 실행

claude.ai/code → 저장소 `neofirm-auto` · 환경 `neofirm` 선택 → 새 세션

1. `/model sonnet`
2. `/neofirm smoke` — 인증·네트워크·JSON 키 확인 (2~3분). 실패 메시지대로 1~3단계 수정
3. `/neofirm auto` (분야를 정하려면 `/neofirm 기업 계약`) — 40~70분, 대부분 NotebookLM 대기
4. 끝나면 세션이 결과를 브랜치에 푸시함 → `output/slides.pdf`를 과제 #6 스레드에 제출

중간에 멈추면: 원인 해결 후 같은 세션(또는 새 세션)에서 `/neofirm auto` 다시 입력 → `state/*.done`이 있는 단계는 건너뛴다.
새 세션에서 이어가려면 이전 세션 브랜치를 main에 머지한 뒤 시작한다(`state/notebook_id`가 있어야 같은 노트북을 재사용).

## 결과물
| 파일 | 내용 |
|---|---|
| `output/slides.pdf`, `slides.pptx` | NotebookLM이 만든 한국어 발표 슬라이드 6장 |
| `output/memo.md` | 1페이지 투자메모 (과제 C 7항목) |
| `output/script_2min.md` | 2분 발표 원고 |
| `debate/debate.md`, `verdict.md`, `factcheck.md` | 토론 전 과정, 심사 채점(/25), 팩트체크 |
| `research/*.md`, `brief.md` | NotebookLM 답변(인용 포함), 조사 요약 |
| `logs/summary.md`, `run.log` | 단계별 시각, 소스 수, 점수 |

## 자주 나는 오류
| 증상 | 해결 |
|---|---|
| `인증 실패` | 쿠키 만료 → 3단계 다시 → 환경변수 갱신 → **새 세션** 시작 |
| `ConnectError`/403 on google | 1단계 Allowed domains 확인 |
| `notebooklm: command not found` | 세션에서 `pip install -r requirements.txt` |
| JSON 키를 못 찾음 | `/neofirm smoke` 결과대로 `scripts/lib.sh`의 `*_KEYS` 수정 |
| 슬라이드가 영어 | `NOTEBOOKLM_HL=ko` 확인 (스크립트는 `--language ko`도 붙임) |
