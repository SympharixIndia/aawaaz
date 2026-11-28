package com.sympharix.aawaaz.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.sympharix.aawaaz.domain.User;
import com.sympharix.aawaaz.domain.UserType;
import com.sympharix.aawaaz.repository.UserRepository;
import com.sympharix.aawaaz.web.dto.WorkerRegistrationRequest;

/** Registration and login (password + face) for workers and managers. */
@Service
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final FaceService faceService;
    private final double faceThreshold;

    public UserService(UserRepository users, PasswordEncoder passwordEncoder,
            FaceService faceService,
            @Value("${face.match-threshold:0.40}") double faceThreshold) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.faceService = faceService;
        this.faceThreshold = faceThreshold;
    }

    /** Registers a new worker. 409 if the username is taken. Enrols a face if a photo is given. */
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

        if (req.photoBase64() != null && !req.photoBase64().isBlank()) {
            worker.setFaceEmbedding(FaceService.toCsv(enrolFace(req.photoBase64())));
        }
        return users.save(worker);
    }

    /**
     * Embeds a registration photo. A bad photo (no/multiple faces → 400) is surfaced so the
     * worker retakes it; if the face server is merely unreachable, registration still proceeds
     * without a face (PIN-only) rather than failing.
     */
    private double[] enrolFace(String photoBase64) {
        try {
            return faceService.embed(photoBase64);
        } catch (ResponseStatusException e) {
            if (e.getStatusCode() == HttpStatus.BAD_REQUEST) {
                throw e; // bad photo → client retakes
            }
            log.warn("Face enrolment skipped (service unavailable): {}", e.getReason());
            return new double[0];
        }
    }

    /** Validates credentials; returns the user (manager or worker) or 401. */
    public User authenticate(String username, String rawPassword) {
        return users.findByUsernameIgnoreCase(username.trim())
                .filter(u -> passwordEncoder.matches(rawPassword, u.getPasswordHash()))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Invalid username or password"));
    }

    /** Identifies a worker by face (1:N). 400 bad photo / 503 service down / 401 no match. */
    public User authenticateByFace(String photoBase64) {
        double[] probe = faceService.embed(photoBase64);

        User best = null;
        double bestSim = -1;
        for (User u : users.findAll()) {
            if (u.getFaceEmbedding() == null || u.getFaceEmbedding().isBlank()) {
                continue;
            }
            double sim = FaceService.similarity(probe, FaceService.fromCsv(u.getFaceEmbedding()));
            if (sim > bestSim) {
                bestSim = sim;
                best = u;
            }
        }
        if (best != null && bestSim >= faceThreshold) {
            return best;
        }
        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Face not recognised");
    }
}
