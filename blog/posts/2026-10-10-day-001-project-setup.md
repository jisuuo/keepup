---
title: "[DAY 001] 프로젝트 세팅과 헬스체크 첫 응답"
date: 2026-10-10
series: keepup
day: 1
week: 1
phase: 0
type: daily
checklist: []
data_structures: []
tags: [spring-boot, mysql, docker-compose, actuator]
related: [ROADMAP.md]
commits: [a8ce233]
status: draft
---

> Claude 초안입니다. 「내 판단」 칸과 `TODO` 표시는 직접 채우고, 문장은 내 말로 고친 뒤 `status: ready`로 바꿉니다.

## 1. 오늘의 목표
- Spring Boot + MySQL 프로젝트를 만들고, 로컬 Docker Compose로 DB를 띄워 헬스체크가 `UP`으로 나오게 한다.

## 2. 따라간 요청
오늘은 요청 하나를 끝까지 따라가는 단계가 아니라 "따라갈 길을 까는" 날이다. 그래도 헬스체크 요청 하나가 어디를 지나는지는 확인했다.

```
curl → 톰캣(8080) → Actuator health → DB 커넥션 검사(isValid) → 응답
```

| 구간 | 시간 |
|---|---|
| 연결(connect) | 0.2ms |
| 첫 바이트(starttransfer) | 3.0ms |
| 전체(total) | 3.2ms |

로컬 루프백이라 네트워크 구간은 의미가 없다. 배포(5주차) 뒤에 같은 명령으로 다시 재서 비교할 기준선으로 남긴다.

## 3. 측정값
| 상황 | HTTP | 응답 |
|---|---|---|
| 정상 | 200 | `{"status":"UP", ...}` |
| MySQL 컨테이너 중지 | 503 | `{"status":"DOWN", ...}` |

- DB를 내린 뒤 503이 오기까지 약 30초가 걸렸다. (스톱워치로 잰 값이 아니라 로그 시각으로 본 대략치다. 2주차에 제대로 잰다.)

## 4. 배운 것: 한 층 아래
- **헬스 상세 정보 노출:** `show-details=always`로 두면 DB 종류, 디스크 용량, 서버의 폴더 경로까지 응답에 나온다. 기본값(`never`)으로 되돌리니 `status`만 남았다.
- **그래도 상태 코드는 유지된다:** 상세를 숨겨도 DB가 죽으면 200 → 503으로 바뀐다. 로드밸런서나 모니터링은 이 코드만으로 판단할 수 있다.
- **DB 비밀번호:** 파일에 적지 않고 `${DB_PASSWORD:keepup}`처럼 환경 변수로 받고, 없을 때만 로컬 기본값을 쓴다.
- TODO: 내 말로 한 줄 — 헬스체크 응답에 무엇을 보여주고 무엇을 숨길지, 나는 어떤 기준으로 정했나?

## 5. 막힌 것 / 다음에 볼 것
- 30초 지연의 원인이 HikariCP의 커넥션 획득 타임아웃(기본 30초)인지 아직 확인하지 못했다. → 2주차 Q2에서 풀 설정을 확인하며 검증.
- 상세 헬스 정보를 운영 중에 볼 방법: 관리 포트 분리(`management.server.port`, 로컬 바인딩)를 5주차 배포 때 결정한다.

## 6. 관련 커밋·문서
- `a8ce233` feat: scaffold Spring Boot project with MySQL via Docker Compose
- [ROADMAP.md](../../ROADMAP.md) 1주차
