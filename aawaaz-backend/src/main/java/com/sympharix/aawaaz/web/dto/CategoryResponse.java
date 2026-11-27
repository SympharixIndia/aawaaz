package com.sympharix.aawaaz.web.dto;

import com.sympharix.aawaaz.domain.Category;

public record CategoryResponse(
        String categoryKey,
        String label,
        int priority,
        boolean safetyCritical) {

    public static CategoryResponse from(Category c) {
        return new CategoryResponse(
                c.getCategoryKey(), c.getLabel(), c.getPriority(), c.isSafetyCritical());
    }
}
