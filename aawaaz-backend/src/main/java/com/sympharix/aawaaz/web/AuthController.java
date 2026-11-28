package com.sympharix.aawaaz.web;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sympharix.aawaaz.service.UserService;
import com.sympharix.aawaaz.web.dto.FaceLoginRequest;
import com.sympharix.aawaaz.web.dto.LoginRequest;
import com.sympharix.aawaaz.web.dto.UserResponse;

import jakarta.validation.Valid;

/** Login for both managers and workers (no tokens). Password or face (workers). */
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

    /** Identify a worker by face photo (1:N). 400 bad photo / 503 service down / 401 no match. */
    @PostMapping("/face")
    public UserResponse faceLogin(@Valid @RequestBody FaceLoginRequest request) {
        return UserResponse.from(userService.authenticateByFace(request.photoBase64()));
    }
}
