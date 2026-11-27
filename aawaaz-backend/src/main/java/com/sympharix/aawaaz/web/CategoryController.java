package com.sympharix.aawaaz.web;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sympharix.aawaaz.service.CategoryService;
import com.sympharix.aawaaz.web.dto.CategoryResponse;
import com.sympharix.aawaaz.web.dto.SetPriorityRequest;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/categories")
public class CategoryController {

    private final CategoryService categoryService;

    public CategoryController(CategoryService categoryService) {
        this.categoryService = categoryService;
    }

    /** List categories, highest priority first. */
    @GetMapping
    public List<CategoryResponse> list() {
        return categoryService.listByPriority().stream().map(CategoryResponse::from).toList();
    }

    /** Set a category's priority (the only mutation allowed on categories). */
    @PutMapping("/{key}/priority")
    public CategoryResponse setPriority(
            @PathVariable String key, @Valid @RequestBody SetPriorityRequest request) {
        return CategoryResponse.from(categoryService.setPriority(key, request.priority()));
    }
}
