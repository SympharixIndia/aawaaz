package com.sympharix.aawaaz.web.dto;

import com.sympharix.aawaaz.domain.RequestStatus;

/** Manager update to a request — any subset may be provided. */
public record UpdateRequestRequest(
        RequestStatus status,
        String managerComment,
        String managerCommentLanguage) {
}
