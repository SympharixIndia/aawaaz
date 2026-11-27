package com.sympharix.aawaaz.web;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.sympharix.aawaaz.service.UserService;
import com.sympharix.aawaaz.web.dto.UserResponse;
import com.sympharix.aawaaz.web.dto.WorkerRegistrationRequest;

import jakarta.validation.Valid;

/** Worker registration. */
@RestController
@RequestMapping("/api/workers")
public class WorkerController {

    private final UserService userService;

    public WorkerController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse register(@Valid @RequestBody WorkerRegistrationRequest request) {
        return UserResponse.from(userService.registerWorker(request));
    }
}
