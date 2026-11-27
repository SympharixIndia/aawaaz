package com.sympharix.aawaaz.web;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sympharix.aawaaz.service.UserService;
import com.sympharix.aawaaz.web.dto.LoginRequest;
import com.sympharix.aawaaz.web.dto.UserResponse;

import jakarta.validation.Valid;

/** Login for both managers and workers (no tokens in V2). */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/login")
    public UserResponse login(@Valid @RequestBody LoginRequest request) {
        return UserResponse.from(
                userService.authenticate(request.username(), request.password()));
    }
}
