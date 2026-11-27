package com.sympharix.aawaaz.web;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.sympharix.aawaaz.domain.Request;
import com.sympharix.aawaaz.domain.RequestStatus;
import com.sympharix.aawaaz.domain.User;
import com.sympharix.aawaaz.repository.UserRepository;
import com.sympharix.aawaaz.service.RequestService;
import com.sympharix.aawaaz.web.dto.CreateRequestRequest;
import com.sympharix.aawaaz.web.dto.RequestResponse;
import com.sympharix.aawaaz.web.dto.UpdateRequestRequest;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/requests")
public class RequestController {

    private final RequestService requestService;
    private final UserRepository users;

    public RequestController(RequestService requestService, UserRepository users) {
        this.requestService = requestService;
        this.users = users;
    }

    /** File a request. */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RequestResponse create(@Valid @RequestBody CreateRequestRequest request) {
        return toDto(requestService.create(request));
    }

    /**
     * List requests. With {@code workerId} → that worker's own requests (newest first).
     * Otherwise the manager view: optional {@code date}/{@code status}/{@code categoryKey},
     * sorted by category priority then newest first.
     */
    @GetMapping
    public List<RequestResponse> list(
            @RequestParam(required = false) Long workerId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) RequestStatus status,
            @RequestParam(required = false) String categoryKey) {
        var result = (workerId != null)
                ? requestService.forWorker(workerId)
                : requestService.list(date, status, categoryKey);
        return toDtos(result);
    }

    /** One request by its id (= ticket number) — the worker's status-by-ticket lookup. */
    @GetMapping("/{id}")
    public RequestResponse getById(@PathVariable Long id) {
        return toDto(requestService.get(id));
    }

    /** Manager update: status and/or comment. */
    @PatchMapping("/{id}")
    public RequestResponse update(
            @PathVariable Long id, @RequestBody UpdateRequestRequest request) {
        return toDto(requestService.update(id, request));
    }

    // --- DTO mapping with worker-name resolution ---

    private RequestResponse toDto(Request r) {
        final String name = users.findById(r.getWorkerId()).map(User::getName).orElse(null);
        return RequestResponse.from(r, name);
    }

    /** Batches the worker-name lookup to avoid N+1 for the listing. */
    private List<RequestResponse> toDtos(List<Request> requests) {
        final List<Long> workerIds =
                requests.stream().map(Request::getWorkerId).distinct().toList();
        final Map<Long, String> names = users.findAllById(workerIds).stream()
                .collect(Collectors.toMap(User::getId, User::getName));
        return requests.stream()
                .map(r -> RequestResponse.from(r, names.get(r.getWorkerId())))
                .toList();
    }
}
