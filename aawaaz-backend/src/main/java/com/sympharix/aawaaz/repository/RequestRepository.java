package com.sympharix.aawaaz.repository;

import java.time.Instant;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.sympharix.aawaaz.domain.Request;

public interface RequestRepository extends JpaRepository<Request, Long> {

    /** A worker's own requests, newest first (the app's "My requests"). */
    List<Request> findByWorkerIdOrderByCreatedAtDesc(Long workerId);

    /** Requests filed within a time window (used by the manager's daily listing). */
    List<Request> findByCreatedAtBetween(Instant start, Instant end);
}
