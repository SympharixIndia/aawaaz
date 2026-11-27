package com.sympharix.aawaaz.web.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

public record SetPriorityRequest(
        @NotNull @PositiveOrZero Integer priority) {
}
