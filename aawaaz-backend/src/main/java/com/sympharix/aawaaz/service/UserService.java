package com.sympharix.aawaaz.service;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.sympharix.aawaaz.domain.User;
import com.sympharix.aawaaz.domain.UserType;
import com.sympharix.aawaaz.repository.UserRepository;
import com.sympharix.aawaaz.web.dto.WorkerRegistrationRequest;

/** Registration and login for both workers and managers. */
@Service
public class UserService {

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository users, PasswordEncoder passwordEncoder) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    /** Registers a new worker. 409 if the username is taken. */
    public User registerWorker(WorkerRegistrationRequest req) {
        if (users.existsByUsernameIgnoreCase(req.username().trim())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username already exists");
        }
        User worker = new User();
        worker.setUsername(req.username().trim());
        worker.setName(req.name().trim());
        worker.setPasswordHash(passwordEncoder.encode(req.password()));
        worker.setUserType(UserType.WORKER);
        worker.setProfession(req.profession() == null ? null : req.profession().trim());
        worker.setLanguageCode(req.languageCode());
        return users.save(worker);
    }

    /** Validates credentials; returns the user (manager or worker) or 401. */
    public User authenticate(String username, String rawPassword) {
        User user = users.findByUsernameIgnoreCase(username.trim())
                .filter(u -> passwordEncoder.matches(rawPassword, u.getPasswordHash()))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Invalid username or password"));
        return user;
    }
}
