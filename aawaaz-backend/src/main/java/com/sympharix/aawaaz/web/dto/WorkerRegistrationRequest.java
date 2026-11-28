package com.sympharix.aawaaz.web.dto;

import jakarta.validation.constraints.NotBlank;

public record WorkerRegistrationRequest(
        @NotBlank String username,
        @NotBlank String name,
        @NotBlank String password,
        String profession,
        @NotBlank String languageCode,
        String photoBase64) {
}
