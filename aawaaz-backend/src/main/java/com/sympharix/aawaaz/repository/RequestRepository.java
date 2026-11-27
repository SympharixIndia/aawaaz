package com.sympharix.aawaaz.repository;

import java.time.Instant;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.sympharix.aawaaz.domain.Request;

public interface RequestRepository extends JpaRepository<Request, Long> {

    /** A worker's own requests, newest first (the app's "My requests"). */
    List<Request> findByWorkerIdOrderByCreatedAtDesc(Long workerId);

    /** Requests filed within [start, end) — a half-open day window for the daily listing. */
    List<Request> findByCreatedAtGreaterThanEqualAndCreatedAtLessThan(Instant start, Instant end);
}
