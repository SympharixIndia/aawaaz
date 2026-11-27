package com.sympharix.aawaaz.web.dto;

import java.time.Instant;

import com.sympharix.aawaaz.domain.Request;
import com.sympharix.aawaaz.domain.RequestStatus;
import com.sympharix.aawaaz.domain.Urgency;

/** Public view of a request — carries both the verbatim and manager-language text. */
public record RequestResponse(
        Long id,
        Long workerId,
        String workerName,
        String originalText,
        String originalLanguage,
        String translatedText,
        String translatedLanguage,
        String categoryKey,
        Urgency urgency,
        RequestStatus status,
        String managerComment,
        String managerCommentLanguage,
        Instant commentedAt,
        Instant createdAt,
        Instant updatedAt) {

    public static RequestResponse from(Request r, String workerName) {
        return new RequestResponse(
                r.getId(), r.getWorkerId(), workerName,
                r.getOriginalText(), r.getOriginalLanguage(),
                r.getTranslatedText(), r.getTranslatedLanguage(),
                r.getCategoryKey(), r.getUrgency(), r.getStatus(),
                r.getManagerComment(), r.getManagerCommentLanguage(),
                r.getCommentedAt(), r.getCreatedAt(), r.getUpdatedAt());
    }
}
