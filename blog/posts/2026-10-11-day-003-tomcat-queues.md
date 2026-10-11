---
title: "[DAY 003] 톰캣의 대기 줄은 몇 개일까: 기본값 확인과 축소판 실험"
date: 2026-10-11
series: keepup
day: 3
week: 1
phase: 0            # 계획표 단계 0~6
type: daily         # daily | weekly-review | experiment | incident | adr
checklist: [Q2, Q5] # 오늘 따라간 질문 Q1~Q5 (없으면 [])
data_structures: [queue] # 오늘 확인한 자료구조 (없으면 [])
tags: [spring-boot, tomcat, thread-pool, tcp, actuator, curl]
related: [ROADMAP.md]
commits: []
status: ready       # draft → ready (파이프라인은 ready만 발행)
---

## 1. 오늘의 목표

내 서버의 톰캣 스레드 풀·대기 줄 기본값을 숫자로 확인한다. DAY 002에서 "톰캣의 대기 줄 3종(`threads.max`, `max-connections`, `accept-count`)이 각각 어떤 줄인지"를 다음에 볼 것으로 남겼고, 그걸 이어서 했다(Q2, 자료구조 체크 맵의 큐).

실제로 요청이 들어올 때부터 톰캣이 스레드를 배정하고 컨트롤러까지 가는 길이 궁금했다.

## 2. 따라간 요청

요청 하나가 톰캣에 도착해서 내 필터에 닿기까지 서는 줄을 순서대로 정리했다. 근거는 이 프로젝트가 쓰는 소스(Spring Boot 4.1.1의 `TomcatServerProperties`, Tomcat 11.0.24의 `NioEndpoint`·`Acceptor`·`TaskQueue`)다.

```
클라이언트
  │ TCP 3-way handshake
  ▼
[OS 커널 대기열]            ← accept-count (100)
  │ 톰캣 Acceptor가 accept()로 꺼냄 — 단, 연결 수가 max-connections 미만일 때만
  ▼
[톰캣이 관리하는 연결들]     ← max-connections (8192)
  │ 연결로 요청 데이터가 들어오면 작업을 만듦
  ▼
[스레드 풀] 쉬는 스레드에 넘김 → 없으면 200개까지 새로 만듦 → 다 바쁘면 ↓
  ▼
[스레드 풀 작업 큐]          ← max-queue-capacity (2147483647)
  ▼
스레드가 꺼내서 실행 → 필터 → 컨트롤러
```

내가 정리한 흐름:

> 클라이언트 TCP 연결 3-way를 지나고서 OS 커널에서 먼저 대기열(accept-count)에 넣고 톰캣이 가져간다. 단 max-connections가 남아 있을 때. 그리고 스레드 풀로 넘어가는데, 스레드 풀이 다 작동 중이면 작업 큐(max-queue-capacity)에서 기다린다. 그리고 스레드가 꺼내서 필터를 지나 컨트롤러로 간다.

보탤 점: 톰캣이 연결을 가져간 직후가 아니라, **그 연결로 요청 데이터가 도착했을 때** 스레드 풀로 일을 넘긴다. 그래서 요청 없이 유지되는 keep-alive 연결은 연결 수는 차지해도 스레드는 잡지 않는다(소스 구조로 이해한 것이고 따로 재지는 않았다).

## 3. 측정값

### A. 기본값 (설정 파일 변경 없이, 실행 옵션으로만 Actuator `configprops`·`metrics`를 열어서 확인)

| 항목 | Spring 설정값 (`configprops`) | 톰캣이 보고하는 값 (`metrics`) |
|---|---|---|
| `threads.max` | 200 | `tomcat.threads.config.max` = 200 |
| `threads.min-spare` | 10 | `tomcat.threads.current` = 10 |
| `max-connections` | 8192 | `tomcat.connections.config.max` = 8192 |
| `accept-count` | 100 | 해당 metric 없음 |
| `threads.max-queue-capacity` | 2147483647 | 해당 metric 없음 |

두 출처의 값이 일치했다. Boot 4에서는 톰캣 설정이 `ServerProperties`가 아니라 `TomcatServerProperties`(`@ConfigurationProperties("server.tomcat")`)라는 별도 빈에 들어 있어서, 처음에 `server` prefix 빈을 뒤졌을 때는 값이 하나도 안 나왔다.

### B. 축소판 실험 (11:18, 1회)

- 설정: `threads.max=2`, `threads.min-spare=2`, `max-connections=4`, `accept-count=2` (실행 옵션)
- 3초 sleep하는 실험용 `/debug/slow` 엔드포인트(실험 후 삭제)에 curl 10개를 0.1초 간격으로 동시에 보냄
- 환경: macOS 로컬

| 요청 | connect | total | 해석 |
|---|---|---|---|
| 1, 2 | 0.0003s | 3.0s | 스레드가 바로 처리 |
| 3, 4 | 0.0003s / 0.001s | 5.8s | 작업 큐에서 약 3초 대기 |
| 5, 6 | 0.0003s | 8.6s | accept-count 줄 (연결은 즉시 됨) |
| 9, 10 | 2.2s | 11.2s | 연결 자체가 지연 |
| 7, 8 | 6.1s | 14.4s | 연결 자체가 지연 |

- 10개 모두 200, 실패 없음.
- 서버 로그의 스레드는 `exec-1`, `exec-2` 둘뿐이고 3초마다 두 개씩 처리했다.

## 4. 배운 것: 한 층 아래

- **작업 큐가 21억 칸이어도 실제 한도는 `max-connections`다.** 큐에서 기다리는 요청도 응답을 받아야 하니 연결을 잡고 있다. 그래서 큐에 동시에 쌓일 수 있는 건 많아야 8192 − 200개쯤이다.
- **"연결됐다"는 "서버가 내 요청을 받았다"가 아니다.** 5, 6번은 accept-count 줄에 있었는데도 connect가 1, 2번과 같은 0.0003초였다. OS 커널이 handshake를 끝내 두고 톰캣이 가져가기를 기다리는 줄이라서, 클라이언트 쪽에서는 연결된 것으로 보인다.
- **설명문과 코드가 달랐다.** Spring의 accept-count 설명은 "when all possible request processing threads are in use"인데, 실제로 이 값은 서버 소켓의 backlog로 OS에 넘어간다(`serverSock.bind(addr, getAcceptCount())`). 스레드가 다 바쁠 때 요청이 서는 곳은 작업 큐였다.
- **자료구조(큐):** 톰캣 스레드 풀의 작업 큐는 `TaskQueue`(`LinkedBlockingQueue`를 상속)다. `offer()`가 스레드 수가 최대보다 적으면 큐에 넣지 않고 `false`를 돌려줘서 새 스레드를 먼저 만들게 한다. 
  - 큐는 작업을 만드는 쪽(Poller)과 처리하는 쪽(워커 스레드)의 속도 차이를 완충하려고 쓴다.
  - 표준 `ThreadPoolExecutor`에 무한 큐를 붙이면 작업이 전부 큐로 가서 스레드가 기본 개수에서 늘어나지 않는다. TaskQueue는 스레드를 최대치까지 먼저 늘린 뒤 큐에 쌓으려고 쓴다. (소스로 확인. 오늘 실험은 `min-spare`와 `max`를 둘 다 2로 둬서 스레드가 늘어나는 장면은 재지 않았다.)
  - `max-connections`가 막아 주니 무한 큐여도 괜찮다. 큐에 있는 작업도 연결을 하나씩 잡고 있어서, 큐 길이는 연결 수 한도를 넘지 못한다.

내 추측과 실제:
- 추측 1 "스레드 200개가 다 바쁠 때 201번째 요청은 accept-count 줄에 선다" → 틀림. 작업 큐에 선다. 그 연결은 이미 `accept()`된 상태다.
- 추측 2 "줄이 꽉 차면 거절, 프록시가 있다면 먼저 오류를 반환" → 작업 큐는 꽉 차기 전에 연결 수 한도가 먼저 닿는다. 연결 수 한도를 넘은 요청은 accept-count로 간다. 그 줄까지 찬 7~10번은 이 실험에서 거절되지 않고 연결이 지연됐다. 프록시는 아직 없어서 확인하지 못했다.

오늘 가장 기억에 남는 것: 요청이 스레드에 배정되고 실제 컨트롤러까지 가는 흐름.

## 5. 막힌 것 / 다음에 볼 것

- **9, 10번이 먼저 보낸 7, 8번보다 먼저 연결된 이유 (가설, 미확인)**
  - 가설: accept-count까지 찬 상태에서 macOS가 SYN을 거절(RST)하지 않고 버렸고, 클라이언트가 각자 재시도했다. 자리가 난 순간에 재시도 SYN이 도착한 쪽이 먼저 들어갔다.
  - 근거: 9번은 0.8초 + connect 2.2초 = 약 3.0초에 연결됐고, 1, 2번이 끝난 시점(약 3.0초)과 맞는다. 재시도 간격이 같다면 7번의 같은 차례 재시도는 약 2.8초로, 자리가 나기 직전이다.
  - 확인 방법: `tcpdump`로 SYN 버림·재전송을 직접 본다.
- 큐에 수천 개가 쌓였을 때 뒤쪽 요청이 얼마나 기다리는지, 클라이언트 타임아웃이 먼저 나는지는 재지 않았다.
- 스레드가 `min-spare`에서 `max`까지 늘어나는 순서(스레드 먼저, 그다음 큐)를 측정으로는 확인하지 않았다.
- OS마다 backlog가 찼을 때의 반응이 다를 수 있다. Linux에서는 다시 재야 한다.
- DAY 002에서 남긴 "요청마다 스레드가 바뀌는 이유", "필터 앞 약 50ms", "`connectionTimeout` 30초 실험"은 오늘 보지 않았다.

결론은 이 환경(macOS, Boot 4.1.1, Tomcat 11.0.24)에서 한 번 재서 "이렇게 관찰됐다"까지다.

## 6. 관련 커밋·문서

- 커밋: 없음 (설정·코드 변경 없이 실행 옵션과 실험용 컨트롤러로만 확인, 컨트롤러는 삭제)
- [ROADMAP.md](../../ROADMAP.md) 2주차, 자료구조 체크 맵 「톰캣 스레드 풀, HikariCP — 큐」
