# keepup

매일 공부를 인증하고, 보증금으로 꾸준함을 거는 **스터디 챌린지 서비스**. 동시에 백엔드 CS를 "내가 만든 요청 하나를 따라가며" 공부하는 6개월(26주) 운영 프로젝트.

> 상태: 1주차 (2026-10-10 시작). 계획은 [ROADMAP.md](ROADMAP.md).

## 만들고 있는 것
보증금 결제 → 매일 인증 → 종료 정산 → 부분취소 환급. 매주 정해진 시각에 기수 선착순 모집을 열어 실제 동시 요청을 만든다. 처음에는 **무상 포인트**로 돈 흐름 전체를 운영하고, 22~25주에 결제 구현체만 토스페이먼츠로 교체한다.

## 스택
Java 21 · Spring Boot · MySQL 8.4 · Docker Compose · Gradle ([ADR-001](docs/adr/001-tech-stack.md))

## 로컬 실행
```bash
docker compose up -d --wait     # MySQL
./gradlew bootRun               # 서버 (8080)
curl -s localhost:8080/actuator/health
```
환경 변수(`DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`)가 없으면 `compose.yaml`과 같은 로컬 기본값을 쓴다.

## 아키텍처
```
클라이언트 → Spring Boot (톰캣) → MySQL
```
단계가 진행되면 이 그림을 갱신한다.

## 핵심 성과 숫자
아직 없음. 26주차에 실사용자 수, 기수 오픈 최대 동시 요청 수, 결제 UNKNOWN 발생·해결 건수, 대사 불일치 건수, 중복 결제·환급 0건 여부를 채운다.

## 문서
| 문서 | 위치 |
|---|---|
| 계획표 | [ROADMAP.md](ROADMAP.md) |
| 학습 로그 | [LEARNING_LOG.md](LEARNING_LOG.md) |
| 블로그 기술 문서 | [blog/posts/](blog/posts/) |
| 설계 결정(ADR) | [docs/adr/](docs/adr/) |
| 실험 보고서 | [docs/experiments/](docs/experiments/) |
| 요청 따라가기 | [docs/request-trace/](docs/request-trace/) |
| 장애 회고 | [docs/incidents/](docs/incidents/) |
| 학습 규칙 | [CLAUDE.md](CLAUDE.md) |
