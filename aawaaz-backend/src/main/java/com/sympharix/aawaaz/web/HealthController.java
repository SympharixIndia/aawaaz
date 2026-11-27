package com.sympharix.aawaaz.web;

import java.time.Instant;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Minimal landing/health endpoint so the service has something to hit.
 * Real request/worker/manager APIs come in later increments.
 */
@RestController
public class HealthController {

    @GetMapping("/")
    public Map<String, Object> root() {
        return Map.of(
                "service", "aawaaz-backend",
                "status", "ok",
                "time", Instant.now().toString());
    }

    @GetMapping("/api/ping")
    public Map<String, String> ping() {
        return Map.of("message", "pong");
    }
}
