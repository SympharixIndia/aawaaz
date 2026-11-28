package com.sympharix.aawaaz.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.sympharix.aawaaz.domain.Category;
import com.sympharix.aawaaz.domain.Request;
import com.sympharix.aawaaz.domain.RequestStatus;
import com.sympharix.aawaaz.domain.User;
import com.sympharix.aawaaz.domain.UserType;
import com.sympharix.aawaaz.repository.CategoryRepository;
import com.sympharix.aawaaz.repository.RequestRepository;
import com.sympharix.aawaaz.repository.UserRepository;
import com.sympharix.aawaaz.web.dto.CreateRequestRequest;
import com.sympharix.aawaaz.web.dto.UpdateRequestRequest;

@Service
public class RequestService {

    private final RequestRepository requests;
    private final UserRepository users;
    private final CategoryRepository categories;
    private final TranslationService translation;
    private final ZoneId zone = ZoneId.systemDefault();

    public RequestService(RequestRepository requests, UserRepository users,
            CategoryRepository categories, TranslationService translation) {
        this.requests = requests;
        this.users = users;
        this.categories = categories;
        this.translation = translation;
    }

    private static final String ENGLISH = "en-IN";

    /** Files a request: stores it verbatim and a canonical English translation (§3.1). */
    public Request create(CreateRequestRequest req) {
        if (!users.existsById(req.workerId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Worker not found");
        }
        if (!categories.existsById(req.categoryKey())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unknown category");
        }

        Request r = new Request();
        r.setWorkerId(req.workerId());
        r.setOriginalText(req.originalText());
        r.setOriginalLanguage(req.originalLanguage());
        r.setCategoryKey(req.categoryKey());
        r.setUrgency(req.urgency());
        r.setStatus(RequestStatus.OPEN);

        // Always translate to English (canonical) — the manager dashboard shows this.
        r.setTranslatedLanguage(ENGLISH);
        r.setTranslatedText(
                translation.translate(req.originalText(), req.originalLanguage(), ENGLISH));

        return requests.save(r);
    }

    /** A worker's own requests, newest first. */
    public List<Request> forWorker(Long workerId) {
        return requests.findByWorkerIdOrderByCreatedAtDesc(workerId);
    }

    /** One request by its id (= ticket number). 404 if absent. */
    public Request get(Long id) {
        return requests.findById(id).orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Request not found"));
    }

    /**
     * Manager listing: optionally filtered by day/status/category, sorted by category
     * priority (safety/health first) then newest first.
     */
    public List<Request> list(LocalDate date, RequestStatus status, String categoryKey) {
        List<Request> base;
        if (date != null) {
            Instant start = date.atStartOfDay(zone).toInstant();
            Instant end = date.plusDays(1).atStartOfDay(zone).toInstant();
            base = requests.findByCreatedAtGreaterThanEqualAndCreatedAtLessThan(start, end);
        } else {
            base = requests.findAll();
        }

        Map<String, Integer> priority = categories.findAll().stream()
                .collect(Collectors.toMap(Category::getCategoryKey, Category::getPriority));

        return base.stream()
                .filter(r -> status == null || r.getStatus() == status)
                .filter(r -> categoryKey == null || categoryKey.equals(r.getCategoryKey()))
                .sorted(Comparator
                        .comparingInt((Request r) -> priority.getOrDefault(r.getCategoryKey(), 0))
                        .reversed()
                        .thenComparing(Request::getCreatedAt, Comparator.reverseOrder()))
                .toList();
    }

    /** Manager update: status and/or comment. 404 if the request doesn't exist. */
    public Request update(Long id, UpdateRequestRequest req) {
        Request r = requests.findById(id).orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Request not found"));

        if (req.status() != null) {
            r.setStatus(req.status());
        }
        if (req.managerComment() != null) {
            String managerLang = Optional.ofNullable(req.managerCommentLanguage())
                    .orElseGet(this::managerLanguage);
            r.setManagerComment(req.managerComment());
            r.setManagerCommentLanguage(managerLang);

            // Translate the reply into the worker's language for playback (§3.2).
            String workerLang = users.findById(r.getWorkerId())
                    .map(User::getLanguageCode)
                    .orElse(managerLang);
            r.setManagerCommentTranslatedLanguage(workerLang);
            r.setManagerCommentTranslated(
                    translation.translate(req.managerComment(), managerLang, workerLang));

            r.setCommentedAt(Instant.now());
        }
        r.setUpdatedAt(Instant.now());
        return requests.save(r);
    }

    private String managerLanguage() {
        return users.findFirstByUserType(UserType.MANAGER)
                .map(User::getLanguageCode).orElse("en-IN");
    }
}
