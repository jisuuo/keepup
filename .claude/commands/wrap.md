---
description: 하루 마감 — 오늘 세션 기반 블로그 초안(status: draft)과 LEARNING_LOG 한 줄 작성
---

하루 마감 산출물을 만든다.

1. `date +%F`로 오늘 날짜를 구한다. DAY 번호는 `LEARNING_LOG.md` 마지막 DAY + 1(날짜와 무관한 회차 번호), 주차는 2026-10-10(토) 시작 기준으로 날짜에서 계산한다.
2. `git log --since=midnight --oneline`과 `git diff --stat`로 오늘 한 일을 확인하고, 이 대화에서 실제로 실행·측정한 내용만 근거로 삼는다.
3. `blog/_templates/daily.md`를 바탕으로 `blog/posts/YYYY-MM-DD-day-NNN-<slug>.md`를 만든다. 금요일이면 `blog/_templates/weekly-review.md`를 쓴다.
   - `status: draft`로 두고, 맨 위에 "Claude 초안" 안내를 넣는다.
   - 재지 않은 숫자나 사용자가 말하지 않은 판단은 쓰지 말고 `TODO`로 남긴다.
   - 서버 IP, 키, 개인정보는 넣지 않는다.
4. `LEARNING_LOG.md` 표에 한 줄을 추가한다(날짜 / 질문 / 한 줄 요약 / 블로그 링크). 질문이 없으면 `–`.
5. 사용자가 직접 채워야 할 `TODO` 목록과 `status`를 `ready`로 바꾸는 방법을 마지막에 알려준다. 커밋은 사용자가 요청할 때만 한다.
