package com.sympharix.aawaaz.web;

import java.time.LocalDate;
import java.util.List;

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

import com.sympharix.aawaaz.domain.RequestStatus;
import com.sympharix.aawaaz.service.RequestService;
import com.sympharix.aawaaz.web.dto.CreateRequestRequest;
import com.sympharix.aawaaz.web.dto.RequestResponse;
import com.sympharix.aawaaz.web.dto.UpdateRequestRequest;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/requests")
public class RequestController {

    private final RequestService requestService;

    public RequestController(RequestService requestService) {
        this.requestService = requestService;
    }

    /** File a request. */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RequestResponse create(@Valid @RequestBody CreateRequestRequest request) {
        return RequestResponse.from(requestService.create(request));
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
        return result.stream().map(RequestResponse::from).toList();
    }

    /** Manager update: status and/or comment. */
    @PatchMapping("/{id}")
    public RequestResponse update(
            @PathVariable Long id, @RequestBody UpdateRequestRequest request) {
        return RequestResponse.from(requestService.update(id, request));
    }
}
