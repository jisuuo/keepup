# LEARNING_LOG

블로그 글의 색인. 하루 한 줄. 질문은 Q1 네트워크 / Q2 스레드 / Q3 DB / Q4 동시성 / Q5 자료구조 (없으면 `–`).

| 날짜 | 질문 | 한 줄 요약 | 블로그 |
|---|---|---|---|
| 2026-10-10 (DAY 001) | – | Spring Boot + MySQL(Docker) 세팅. `/actuator/health` 200 `UP`(DB 포함), DB 중지 시 503 확인, 헬스 상세는 숨겨도 상태 판단은 그대로. 1주차 문서·도구(README, ADR-001, 학습 규칙, `/today`·`/wrap`, 템플릿) 마련 | [DAY 001](blog/posts/2026-10-10-day-001-project-setup.md) · [발행본](https://jisuuo.github.io/blog/keepup-day-001-project-setup/) |
| 2026-10-10 (DAY 002) | Q2 | requestId(MDC)·요청 시간 로그 필터 추가. HikariCP 기본값 10/10/30s, 기동 후 약 0.5초 동안 백그라운드로 채움 확인. 재기동 직후 첫 요청은 110ms 중 필터 밖이 약 61ms — DB 커넥션 생성은 주된 원인으로 보이지 않았고(`liveness`가 첫 요청이면 느리고 두 번째면 빨랐음), 첫 요청에서 클래스가 대량 로드되는 것이 관찰됨(시간 점유는 미확인) | [DAY 002](blog/posts/2026-10-10-day-002-request-id-and-first-request.md) · [발행본](https://jisuuo.github.io/blog/keepup-day-002-request-id-and-first-request/) |
