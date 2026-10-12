#!/usr/bin/env bash
# 요청 하나를 curl 구간으로 나눠 ms로 출력한다. 서버 로그와는 requestId로 맞춘다.
# 사용법: scripts/curl-timing.sh [URL] [횟수]
#   예: scripts/curl-timing.sh http://localhost:8080/actuator/health 10
#
# curl 시간 변수는 모두 시작 시점부터의 누적값이라 뺄셈으로 구간을 만든다.
#   dns    = namelookup
#   tcp    = connect - namelookup
#   tls    = appconnect - connect            (http면 0)
#   wait   = starttransfer - pretransfer     (요청 전송 + 서버 안 전체 + 첫 바이트 도착) ← 서버 로그 ms와 비교
#   body   = total - starttransfer
set -euo pipefail

url="${1:-http://localhost:8080/actuator/health}"
count="${2:-1}"

fmt='%{time_namelookup} %{time_connect} %{time_appconnect} %{time_pretransfer} %{time_starttransfer} %{time_total} %{http_code} %{remote_ip} %header{x-request-id}\n'

printf '%-3s %-8s %-4s %-15s %7s %7s %7s %7s %7s %7s\n' '#' requestId code ip dns tcp tls wait body total
for i in $(seq 1 "$count"); do
	curl -s -o /dev/null -w "$fmt" "$url" | awk -v i="$i" '{
		ms = 1000
		dns = $1; tcp = $2 - $1
		tls = ($3 > 0) ? $3 - $2 : 0
		wait = $5 - $4; body = $6 - $5
		printf "%-3s %-8s %-4s %-15s %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f\n", i, $9, $7, $8, dns*ms, tcp*ms, tls*ms, wait*ms, body*ms, $6*ms
	}'
done
