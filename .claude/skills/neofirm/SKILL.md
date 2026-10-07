---
name: neofirm
description: 몰입캠프 NeoFirm 과제를 NotebookLM CLI 자료조사 → 서브에이전트 토론 → 한국어 슬라이드까지 사람 개입 없이 실행한다. /neofirm [분야|auto|smoke] 로 실행.
---

# NeoFirm 완전 자동 파이프라인

인자: `smoke`(스모크 테스트만), `auto`(분야 자동 선정, 기본), 또는 분야명(예: `기업 계약`).
**사람에게 묻지 않는다.** 판단이 필요하면 합리적인 쪽을 고르고 `logs/decisions.md`에 한 줄 남긴다.
각 단계 시작 전 `state/S<번호>.done`이 있으면 건너뛴다. 스크립트가 0이 아닌 코드로 끝나면 `logs/ERROR.md`를 읽고, 원인이 일시적(네트워크·rate limit)이면 그 스크립트만 1회 다시 실행, 아니면 멈추고 보고한다.
진행 상황은 TaskCreate로 S0~S14 목록을 만들어 체크한다.

## S0 스모크 (state/S0.done 없을 때만)
`bash scripts/s0_smoke.sh` → `logs/smoke.md`에서 JSON 키 확인. "키 못 찾음"이 있으면 `scripts/lib.sh`의 `*_KEYS` 배열에 실제 키를 앞에 추가하고 다시 실행. 인자가 `smoke`면 여기서 종료.

## A. 자료조사
1. **S1~S3** `bash scripts/s1_s3_init.sh` (최대 10분)
2. **S4 주제 선정** — 직접 수행. `research/F0.md`만 읽고:
   - `topic.md`: 첫 줄 `분야: <분야명>` (반드시 이 형식), 첫 표준화 업무 1개, 대상 고객, 선정 이유, 인자가 auto면 F0의 유망 분야들을 6개 판별기준으로 1~5점 채점한 표
   - `state/research_deep.txt`: "한국 <분야> 시장 규모, 업무 프로세스, 가격, 경쟁사, AI 도입 사례" 수준의 리서치 질의 1개
   - `state/research_fast.txt`: 해당 분야 자격사법·업무범위·광고 규제 질의 1개
   - `touch state/S4.done`
3. **S5 웹 리서치** — `bash scripts/s5_research.sh > logs/s5.out 2>&1` 를 **백그라운드**로 실행하고 끝날 때까지 기다린다(최대 30분). 기다리는 동안 다른 단계를 진행하지 않는다.
4. **S6 질의** `bash scripts/s6_ask.sh` (백그라운드 권장, 5~10분)
5. **S7 브리프** — 직접 수행. `topic.md`, `research/[A-CR]*.md`를 읽고
   - `research/brief.md` (2,000~6,000자): 가치사슬 / 업무배분 4칸 / 시장·가격 / 책임·규제 / 데이터 / 위험. 수치마다 `[A2]`처럼 출처 파일 ID
   - `research/gaps.md`: 근거가 약하거나 없는 항목 목록
   - `touch state/S7.done`

## B. AI 에이전트 토론 (S8~S10)
서브에이전트에게는 **역할·라운드·읽을 파일·쓸 파일 경로만** 넘긴다(내용을 붙여넣지 않는다).
1. **R1** 순차: `neofirm-founder` → `debate/r1_founder.md`, `neofirm-vc` → `debate/r1_vc.md`(r1_founder 읽기), `neofirm-regulator` → `debate/r1_regulator.md`(r1_* 읽기)
2. **R2** 병렬 3개 호출: 각자 `debate/r1_*.md` 전부 읽고 `debate/r2_<역할>.md`
3. **R3** 병렬 3개 호출: 각자 `r1_*, r2_*` 읽고 `debate/r3_<역할>.md`
4. 9개 파일이 다 있고 각 200자 이상인지 확인. 없는 것만 1회 재호출. `touch state/S8.done`
5. **S9 판정** `cat debate/r1_founder.md debate/r1_vc.md debate/r1_regulator.md debate/r2_*.md debate/r3_*.md > debate/debate.md` 후 `neofirm-judge` 호출. `tail -1 debate/verdict.md`의 TOTAL이 15 미만이면 founder R4(`debate/r4_founder.md`) → debate.md에 append → judge 재판정 **1회만**. `touch state/S9.done`
6. **S10 팩트체크** verdict.md의 수치·법령 주장을 최대 10개 `state/claims.txt`에 번호 목록으로 뽑고 `bash scripts/s10_factcheck.sh`

## C. 발표자료 (S11~S14)
1. **S11 작성** — 직접 수행. verdict.md, factcheck.md, brief.md를 읽고
   - `output/memo.md`: 1페이지 투자메모 7항목(시장 규모·현재 지출 / 첫 업무 / 결과 단위·가격 / 전문가 개입률·품질지표 / 책임·보험·규제 / 100건 후 데이터 / SaaS보다 직접 서비스인 이유) + 리포트 템플릿 문제정의문 한 문장. 팩트체크 '근거 없음' 주장은 삭제하거나 "가정"으로.
   - `output/script_2min.md`: 6장, 장당 약 20초 원고
   - `state/slides_prompt.txt`: 아래 6장 구성을 그대로 지시(제목·핵심 문장 명시, 한국어, 텍스트 최소, 장당 메시지 1개)
     1 문제정의 / 2 가치사슬과 업무 배분(자동화·AI보조·전문가·금지) / 3 비즈니스 모델(결과 단위·가격·책임·데이터 해자) / 4 AI 토론 결과(가장 치열한 반론, 수정안, 심사 점수 /25) / 5 자동화 파이프라인(NotebookLM 조사 → 에이전트 3인+심사 → 슬라이드) / 6 숫자로 본 자동화(소요시간, 사람 개입 0회, 소스 수)
   - `touch state/S11.done`
2. **S12 슬라이드** `EXTRA=0 bash scripts/s12_slides.sh > logs/s12.out 2>&1` 백그라운드, 완료 대기(최대 25분)
3. **S13 검수** — `output/review.md`: 평가기준 5개가 memo·슬라이드 어디 반영됐는지 표, 출처 누락, 빠진 항목. 슬라이드에 치명적 누락이 있으면 `bash scripts/s13_revise.sh <번호> "<지시>"` 1회.
4. **S14 마무리**
   - `logs/summary.md`: 분야, judge 점수, 소스 수, 파일 목록, 각 단계 시작·종료 시각(`logs/run.log` 기준)
   - `git add -A && git commit -m "NeoFirm run: <분야>" && git push` (현재 브랜치)
   - 마지막 메시지: 결과 파일 목록, 점수, 그리고 사람이 직접 할 일 — NotebookLM 노트북 공유는 사용자가 직접(`notebooklm share public --enable -n <ID>`를 안내만, 실행하지 않음)
