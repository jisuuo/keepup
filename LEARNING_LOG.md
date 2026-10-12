# LEARNING_LOG

블로그 글의 색인. 하루 한 줄. 질문은 Q1 네트워크 / Q2 스레드 / Q3 DB / Q4 동시성 / Q5 자료구조 (없으면 `–`).

| 날짜 | 질문 | 한 줄 요약 | 블로그 |
|---|---|---|---|
| 2026-10-10 (DAY 001) | – | Spring Boot + MySQL(Docker) 세팅. `/actuator/health` 200 `UP`(DB 포함), DB 중지 시 503 확인, 헬스 상세는 숨겨도 상태 판단은 그대로. 1주차 문서·도구(README, ADR-001, 학습 규칙, `/today`·`/wrap`, 템플릿) 마련 | [DAY 001](blog/posts/2026-10-10-day-001-project-setup.md) · [발행본](https://jisuuo.github.io/blog/keepup-day-001-project-setup/) |
| 2026-10-10 (DAY 002) | Q2 | requestId(MDC)·요청 시간 로그 필터 추가. HikariCP 기본값 10/10/30s, 기동 후 약 0.5초 동안 백그라운드로 채움 확인. 재기동 직후 첫 요청은 110ms 중 필터 밖이 약 61ms — DB 커넥션 생성은 주된 원인으로 보이지 않았고(`liveness`가 첫 요청이면 느리고 두 번째면 빨랐음), 첫 요청에서 클래스가 대량 로드되는 것이 관찰됨(시간 점유는 미확인) | [DAY 002](blog/posts/2026-10-10-day-002-request-id-and-first-request.md) · [발행본](https://jisuuo.github.io/blog/keepup-day-002-request-id-and-first-request/) |
| 2026-10-11 (DAY 003) | Q2, Q5 | 톰캣 기본값 확인(threads.max 200, min-spare 10, max-connections 8192, accept-count 100, max-queue-capacity 21억). 스레드가 다 바쁘면 작업 큐에 서고, 실제 한도는 max-connections. 축소판 실험(1회)에서 accept-count 줄의 요청은 connect가 즉시 끝났고, 그 줄까지 찬 요청은 거절 없이 연결이 2.2~6.1초 지연됨 | [DAY 003](blog/posts/2026-10-11-day-003-tomcat-queues.md) · [발행본](https://jisuuo.github.io/blog/keepup-day-003-tomcat-queues/) |
| 2026-10-12 (DAY 004) | Q1 | curl 구간 측정 스크립트 작성. 재기동 직후 첫 요청은 curl wait 181ms 중 서버 필터 안 86ms, 필터 밖 약 95ms(tcp는 0.23ms로 원인 아님). 이후 약 2.5ms로 안정. TCP handshake는 OS가 하고 톰캣은 accept()부터 → accept 큐가 차면 `tcp`, 그 뒤가 막히면 `wait`가 늘어남. `localhost`는 `::1`(IPv6)로 연결됐고 `127.0.0.1`과 속도 차이는 없었음 | [DAY 004](blog/posts/2026-10-12-day-004-curl-timing.md) · [발행본](https://jisuuo.github.io/blog/keepup-day-004-curl-timing/) |
