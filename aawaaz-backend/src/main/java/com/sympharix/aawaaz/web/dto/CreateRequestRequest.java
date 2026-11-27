package com.sympharix.aawaaz.web.dto;

import com.sympharix.aawaaz.domain.Urgency;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/** Payload to file a request. The app already classifies, so it sends category + urgency. */
public record CreateRequestRequest(
        @NotNull Long workerId,
        @NotBlank String originalText,
        @NotBlank String originalLanguage,
        @NotBlank String categoryKey,
        @NotNull Urgency urgency) {
}
