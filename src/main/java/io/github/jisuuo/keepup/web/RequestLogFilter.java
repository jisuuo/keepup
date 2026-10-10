package io.github.jisuuo.keepup.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/**
 * 요청마다 requestId를 만들어 MDC에 넣고, 끝날 때 상태 코드와 걸린 시간을 한 줄로 남긴다.
 * 측정 구간: 이 필터가 요청을 받은 시점 ~ 필터 체인이 끝난 시점 (톰캣 큐 대기·네트워크는 포함 안 됨).
 */
@Component
public class RequestLogFilter extends OncePerRequestFilter {

	static final String REQUEST_ID = "requestId";
	private static final Logger log = LoggerFactory.getLogger(RequestLogFilter.class);

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
			throws ServletException, IOException {
		String requestId = UUID.randomUUID().toString().substring(0, 8);
		MDC.put(REQUEST_ID, requestId);
		response.setHeader("X-Request-Id", requestId);

		long start = System.nanoTime();
		try {
			chain.doFilter(request, response);
		} finally {
			long elapsedMs = (System.nanoTime() - start) / 1_000_000;
			log.info("{} {} -> {} {}ms", request.getMethod(), request.getRequestURI(), response.getStatus(), elapsedMs);
			MDC.remove(REQUEST_ID);
		}
	}
}
