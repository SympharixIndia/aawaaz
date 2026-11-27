package com.sympharix.aawaaz.web.dto;

import com.sympharix.aawaaz.domain.User;
import com.sympharix.aawaaz.domain.UserType;

/** Public view of a user — never exposes the password hash. */
public record UserResponse(
        Long id,
        String username,
        String name,
        UserType userType,
        String profession,
        String languageCode) {

    public static UserResponse from(User u) {
        return new UserResponse(
                u.getId(), u.getUsername(), u.getName(),
                u.getUserType(), u.getProfession(), u.getLanguageCode());
    }
}
