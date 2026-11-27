package com.sympharix.aawaaz.domain;

/** Request lifecycle. Stored as its name in {@code requests.status}. */
public enum RequestStatus {
    OPEN,
    IN_PROGRESS,
    RESOLVED
}
