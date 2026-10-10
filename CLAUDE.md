# keepup 학습 규칙

보증금 스터디 챌린지를 만들며 백엔드 CS를 "내 요청 하나를 따라가며" 공부하는 프로젝트. 계획은 `ROADMAP.md`가 기준이다. (전역 `~/.claude/CLAUDE.md`의 규칙에 이어서 적용)

## 날짜·주차 계산
- DAY 1 = 2026-10-10(토). 주말 포함 매일 진행. DAY N = 10/10 + (N-1)일, 주차 = ceil(N/7), 한 주는 토~금.
- 금요일(DAY 7, 14, …)은 `weekly-review` 글을 쓴다.

## 코치 모드 (구현 중)
- 보일러플레이트와 초안은 Claude가 만든다. **핵심 로직(원장·정산·동시성 제어·상태 전이)은 사용자가 직접 작성**하고 Claude는 리뷰만 한다.
- 체크리스트 질문(Q1~Q5)은 **하루 1개**. 답을 바로 주지 말고 질문으로 유도하고, 마지막에 검증한다.
- 측정값 없이 결론 내리지 않는다. 이틀 이상 막히면 "다음에 볼 것"에 적고 넘어간다.
- 실험 보고서의 **"내 판단"은 사용자가 먼저** 쓰고, Claude 피드백은 그 뒤에 붙인다.

## 산출물 규칙
- 매일 마감: `blog/posts/YYYY-MM-DD-day-NNN-<slug>.md` + `LEARNING_LOG.md` 한 줄. 형식은 `blog/_templates/daily.md`와 ROADMAP의 「블로그 시리즈 규칙」을 따른다.
- Claude가 쓴 블로그 글은 항상 `status: draft`. 사용자가 자기 말로 고친 뒤에만 `ready`로 바꾼다. 사용자가 직접 겪지 않은 일, 재지 않은 숫자는 적지 않는다(모르면 `TODO`).
- 설계를 고르면 `docs/adr/`, 실험은 `docs/experiments/`, 장애는 `docs/incidents/`, 요청 분해는 `docs/request-trace/`. 각 폴더의 `TEMPLATE.md`를 복사해 쓴다.
- 공개 저장소다. 키·비밀번호·서버 IP·사용자 개인정보(GitHub 아이디 포함)는 글, 로그, 캡처에 넣지 않는다.

## 명령어
- `/today` — 오늘이 DAY 몇 번인지, 어제 기록, 오늘 목표 1개와 질문 1개를 제안
- `/wrap` — 하루 마감: 오늘 세션을 근거로 블로그 초안과 LEARNING_LOG 한 줄 작성

## 실행
```bash
docker compose up -d --wait
./gradlew bootRun
curl -s localhost:8080/actuator/health
```

## 커밋
- 형식: `type: 설명` (feat / fix / docs / chore / test), 영어 소문자 시작.
- 블로그 글의 `commits:` 필드에는 그날의 관련 커밋 해시를 적는다.
