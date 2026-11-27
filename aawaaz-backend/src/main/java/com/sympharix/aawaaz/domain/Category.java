package com.sympharix.aawaaz.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** A request category. Static set (seeded); only {@code priority} is mutable. */
@Entity
@Table(name = "categories")
public class Category {

    @Id
    @Column(name = "category_key")
    private String categoryKey;

    @Column(nullable = false)
    private String label;

    @Column(nullable = false)
    private int priority;

    @Column(name = "is_safety_critical", nullable = false)
    private boolean safetyCritical;

    public String getCategoryKey() {
        return categoryKey;
    }

    public void setCategoryKey(String categoryKey) {
        this.categoryKey = categoryKey;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public int getPriority() {
        return priority;
    }

    public void setPriority(int priority) {
        this.priority = priority;
    }

    public boolean isSafetyCritical() {
        return safetyCritical;
    }

    public void setSafetyCritical(boolean safetyCritical) {
        this.safetyCritical = safetyCritical;
    }
}
