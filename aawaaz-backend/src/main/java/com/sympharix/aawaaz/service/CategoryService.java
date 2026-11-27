package com.sympharix.aawaaz.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.sympharix.aawaaz.domain.Category;
import com.sympharix.aawaaz.repository.CategoryRepository;

/** Categories are static (seeded); only priority is mutable. */
@Service
public class CategoryService {

    private final CategoryRepository categories;

    public CategoryService(CategoryRepository categories) {
        this.categories = categories;
    }

    public List<Category> listByPriority() {
        return categories.findAllByOrderByPriorityDesc();
    }

    public Category setPriority(String key, int priority) {
        Category category = categories.findById(key).orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown category"));
        category.setPriority(priority);
        return categories.save(category);
    }
}
