package com.sympharix.aawaaz.domain;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

/** A request a worker filed. Maps to the {@code requests} table. */
@Entity
@Table(name = "requests")
public class Request {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Column(name = "original_text", nullable = false)
    private String originalText;

    @Column(name = "original_language", nullable = false)
    private String originalLanguage;

    @Column(name = "translated_text")
    private String translatedText;

    @Column(name = "translated_language")
    private String translatedLanguage;

    @Column(name = "category_key", nullable = false)
    private String categoryKey = "other";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Urgency urgency = Urgency.NORMAL;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RequestStatus status = RequestStatus.OPEN;

    @Column(name = "manager_comment")
    private String managerComment;

    @Column(name = "manager_comment_language")
    private String managerCommentLanguage;

    @Column(name = "manager_comment_translated")
    private String managerCommentTranslated;

    @Column(name = "manager_comment_translated_language")
    private String managerCommentTranslatedLanguage;

    @Column(name = "commented_at")
    private Instant commentedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getWorkerId() {
        return workerId;
    }

    public void setWorkerId(Long workerId) {
        this.workerId = workerId;
    }

    public String getOriginalText() {
        return originalText;
    }

    public void setOriginalText(String originalText) {
        this.originalText = originalText;
    }

    public String getOriginalLanguage() {
        return originalLanguage;
    }

    public void setOriginalLanguage(String originalLanguage) {
        this.originalLanguage = originalLanguage;
    }

    public String getTranslatedText() {
        return translatedText;
    }

    public void setTranslatedText(String translatedText) {
        this.translatedText = translatedText;
    }

    public String getTranslatedLanguage() {
        return translatedLanguage;
    }

    public void setTranslatedLanguage(String translatedLanguage) {
        this.translatedLanguage = translatedLanguage;
    }

    public String getCategoryKey() {
        return categoryKey;
    }

    public void setCategoryKey(String categoryKey) {
        this.categoryKey = categoryKey;
    }

    public Urgency getUrgency() {
        return urgency;
    }

    public void setUrgency(Urgency urgency) {
        this.urgency = urgency;
    }

    public RequestStatus getStatus() {
        return status;
    }

    public void setStatus(RequestStatus status) {
        this.status = status;
    }

    public String getManagerComment() {
        return managerComment;
    }

    public void setManagerComment(String managerComment) {
        this.managerComment = managerComment;
    }

    public String getManagerCommentLanguage() {
        return managerCommentLanguage;
    }

    public void setManagerCommentLanguage(String managerCommentLanguage) {
        this.managerCommentLanguage = managerCommentLanguage;
    }

    public String getManagerCommentTranslated() {
        return managerCommentTranslated;
    }

    public void setManagerCommentTranslated(String managerCommentTranslated) {
        this.managerCommentTranslated = managerCommentTranslated;
    }

    public String getManagerCommentTranslatedLanguage() {
        return managerCommentTranslatedLanguage;
    }

    public void setManagerCommentTranslatedLanguage(String managerCommentTranslatedLanguage) {
        this.managerCommentTranslatedLanguage = managerCommentTranslatedLanguage;
    }

    public Instant getCommentedAt() {
        return commentedAt;
    }

    public void setCommentedAt(Instant commentedAt) {
        this.commentedAt = commentedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
