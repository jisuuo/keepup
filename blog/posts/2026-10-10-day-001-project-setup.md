---
title: "[DAY 001] 프로젝트 세팅과 헬스체크 첫 응답"
date: 2026-10-10
series: keepup
day: 1
week: 1
phase: 0            # 계획표 단계 0~6
type: daily         # daily | weekly-review | experiment | incident | adr
checklist: []       # 오늘은 질문을 따라가기 전 "길을 까는" 날
data_structures: []
tags: [spring-boot, mysql, docker-compose, actuator, curl, adr]
related: [ROADMAP.md, README.md, CLAUDE.md, docs/adr/001-tech-stack.md]
commits: [a8ce233, 518bfac]
status: draft       # draft → ready (파이프라인은 ready만 발행)
---

> Claude 초안입니다. `TODO` 표시는 직접 채우고, 문장은 내 말로 고친 뒤 `status: ready`로 바꿉니다.

## 1. 오늘의 목표
- Spring Boot + MySQL 프로젝트를 만들고, 로컬 Docker Compose로 DB를 띄워 헬스체크가 `UP`으로 나오게 한다.
- 헬스체크 응답을 어디까지 밖에 보여줄지 정한다.
- 1주차 문서·도구를 마련한다: README, ADR-001(스택 선택), 프로젝트 `CLAUDE.md` 학습 규칙, `/today`·`/wrap` 명령어, 블로그·docs 템플릿.

## 2. 따라간 요청
오늘은 요청 하나를 끝까지 따라가는 단계가 아니라 "따라갈 길을 까는" 날이다. 그래도 헬스체크 요청 하나가 어디를 지나는지는 확인했다.

```
curl → 톰캣(8080) → Actuator health → DB 커넥션 검사(isValid) → 응답
```

`curl -w`로 잰 값은 구간의 길이가 아니라 **요청 시작부터의 누적 시각**이다. 구간별 소요는 뺄셈으로 구한다.

```
0ms ─ connect ─ 요청 전송 ─ [서버 처리] ─ starttransfer ─ 본문 수신 ─ total
```

| 지점 | 누적 시각 | 구간 소요 | 의미 |
|---|---|---|---|
| connect | 0.22ms | 0.22ms | TCP 연결 완료 |
| starttransfer | 2.98ms | 약 2.76ms | 요청 전송 + 서버 처리 (첫 바이트 도착, TTFB) |
| total | 3.24ms | 약 0.26ms | 본문 수신 완료 |

- 약 2.76ms는 톰캣이 요청을 받아 Actuator가 DB 연결을 검사하고 응답을 쓰기 시작할 때까지의 시간이다. 이후 쿼리나 로직이 붙으면 늘어나는 곳이 이 구간이고, 요청 따라가기의 분해 대상도 여기다.
- 로컬 HTTP라서 DNS 조회(`time_namelookup`)와 TLS(`time_appconnect`)는 거의 0이다. 5주차에 HTTPS로 배포하면 이 둘이 보이기 시작한다.
- 한 번 잰 값이라 기준선으로는 약하다. 2주차 측정 스크립트에서 여러 번 재서 중앙값으로 바꾼다.

## 3. 측정값

### 응답 시간
위 표 참고. 한 번 잰 값이므로 실행마다 달라진다.

### 정상일 때와 DB가 죽었을 때
| 상황 | HTTP | 응답 |
|---|---|---|
| 정상 | 200 | `{"groups":["liveness","readiness"],"status":"UP"}` |
| MySQL 컨테이너 중지 | 503 | `{"groups":["liveness","readiness"],"status":"DOWN"}` |

- DB를 내린 직후의 요청은 한참 걸린 뒤에 503이 왔다. 걸린 시간은 직접 재지 못해서 숫자로 적지 않는다.
- 2주차에 같은 상황을 `curl -w`로 재서 정확한 값을 남긴다.

### 직접 다시 확인하는 방법
```bash
docker compose up -d --wait
./gradlew bootRun                  # 이 터미널은 서버가 차지함

# 다른 터미널
curl -s -o /dev/null -w "connect=%{time_connect}s starttransfer=%{time_starttransfer}s total=%{time_total}s\n" localhost:8080/actuator/health
curl -s -i localhost:8080/actuator/health | head -1      # 200
docker stop keepup-mysql
curl -s -i localhost:8080/actuator/health | head -1      # 503 (한참 걸림)
docker start keepup-mysql
```
끌 때는 서버 터미널에서 `Ctrl+C`, DB는 `docker compose stop`(데이터는 `docker/mysql/data/`에 남는다).

## 4. 배운 것: 한 층 아래

### 헬스 응답은 판단과 표시가 따로다
`show-details=always`로 두었을 때와 기본값(`never`)의 차이:

```
[always]  {"components":{"db":{"details":{"database":"MySQL", ...}},
           "diskSpace":{"details":{"total":494384795648,"free":35066077184,
             "path":"<서버의 폴더 경로>", ...}}, ...},
           "status":"UP"}

[never]   {"groups":["liveness","readiness"],"status":"UP"}
```

- `always`에서는 DB 종류, 디스크 용량, 서버의 폴더 경로까지 밖으로 나간다. 로컬에서는 문제가 없지만 배포하면 공격자에게 서버 구조를 알려주는 응답이 된다.
- `show-details=never`는 검사를 끄는 설정이 아니라 결과를 보여주는 양만 줄이는 설정이다.

| 부분 | 내용 | `show-details`의 영향 |
|---|---|---|
| 판단 | 앱이 매 요청마다 DB·디스크 등을 검사해 전체 상태를 계산하고, `UP`이면 200, `DOWN`이면 503 | 없음 |
| 표시 | 응답 본문에 항목별 상세(`components`)를 보여줄지 | 여기만 숨김 |

```
DB 살아있음:  DB 검사 UP   → 전체 UP   → 200 {"status":"UP"}
DB 죽음:      DB 검사 DOWN → 전체 DOWN → 503 {"status":"DOWN"}   (어느 항목 때문인지는 본문에 안 나옴)
```

- 로드밸런서나 모니터링은 본문을 읽지 않고 상태 코드만 보고 "이 서버로 트래픽을 보내도 되나"를 판단한다. 그래서 본문이 `status`뿐이어도 문제를 알 수 있고, 서버 경로나 DB 종류는 밖에 노출하지 않아도 된다.
- 대신 어떤 항목 때문에 `DOWN`인지는 본문으로 알 수 없다. 원인은 서버 로그나 내부 경로(관리 포트 분리)로 봐야 한다.
- `/actuator/health/liveness`(프로세스가 살아있나)와 `/actuator/health/readiness`(트래픽 받을 준비가 됐나)는 상세를 숨겨도 그대로 쓸 수 있다.

### 상세 정보를 보려면 (이미 HTTP API다)
| 방법 | 내용 | 비고 |
|---|---|---|
| A. 관리 포트 분리 | `management.server.port=8081` + `management.server.address=127.0.0.1` 후 `show-details=always` | 서버 안에서만 `curl localhost:8081/...`로 보인다. 외부 8080에서는 계속 숨겨진다. 추가 의존성 없음 |
| B. 인증 후 공개 | `show-details=when-authorized` + Spring Security | 로그인 기능이 필요하다. 3주차 GitHub OAuth와 같이 하는 게 자연스럽다 |
| C. 그냥 켜기 | `show-details=always` | 위 이유로 비추천 |

- 6주차 이후 Prometheus + Grafana와 Discord 알림도 관리 포트에서 지표를 가져오게 하면 구조가 깔끔하다. 그래서 A가 유력하고, 5주차 배포 때 결정한다.
- 내 기준: 사용자에게는 쓸모없고 공격자에게는 쓸모 있는 정보(경로, DB 종류)는 숨기고, 내 서버를 판단하기 위한 정보만 남긴다.

### DB 비밀번호
파일에 적지 않고 `${DB_PASSWORD:keepup}`처럼 환경 변수로 받고, 없을 때만 로컬 기본값을 쓴다. 저장소가 공개라서 `.env`와 `application-local.*`는 `.gitignore`에 넣어 두었다.

### 스택을 고른 기준 (ADR-001)
Java 21 + Spring Boot + MySQL 8.4를 골랐고, 기준은 "Q2~Q4의 대상(스레드 풀, 커넥션 풀, 락, 인덱스)을 기본 설정 그대로 관찰할 수 있는가"였다. 자세한 대안 비교는 [ADR-001](../../docs/adr/001-tech-stack.md).
- 내 이유: Java와 Spring은 써 본 적이 있지만 깊게 파는 것은 이번이 처음이다. 어느 정도 익숙하니 언어·프레임워크 학습량이 줄어, 그만큼 Q1~Q5 공부에 시간을 쓸 수 있을 것이라고 기대한다. (기대일 뿐, 실제로 줄었는지는 2주차 이후에 돌아본다.)
- 확인 중: 이 스택이 목표 회사군에서 흔한지는 아직 공고를 찾아보는 중이다.

## 5. 막힌 것 / 다음에 볼 것
- DB를 내렸을 때 응답이 오래 걸리는 원인이 HikariCP의 커넥션 획득 타임아웃(기본 30초)인지 확인하지 못했다. → 2주차 Q2에서 풀 설정을 확인하며 검증.
- 방법 A(관리 포트 분리)를 5주차 배포 때 적용할지 결정한다.
- 기준선은 한 번 잰 값이다. → 2주차 curl 측정 스크립트로 반복 측정.
- `/today`, `/wrap` 명령어는 만들기만 했고 실제로 실행해 보지 않았다. → DAY 002 시작 때 `/today`로 확인.

## 6. 관련 커밋·문서
- `a8ce233` feat: scaffold Spring Boot project with MySQL via Docker Compose
- `518bfac` docs: add README, ADR-001, learning rules, templates and /today /wrap commands
- [ROADMAP.md](../../ROADMAP.md) 1주차 · [README.md](../../README.md) · [CLAUDE.md](../../CLAUDE.md)
