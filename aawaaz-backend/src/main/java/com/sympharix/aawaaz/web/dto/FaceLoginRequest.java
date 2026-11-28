package com.sympharix.aawaaz.web.dto;

import jakarta.validation.constraints.NotBlank;

public record FaceLoginRequest(
        @NotBlank String photoBase64) {
}
