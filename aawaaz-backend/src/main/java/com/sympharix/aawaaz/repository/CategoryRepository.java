package com.sympharix.aawaaz.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.sympharix.aawaaz.domain.Category;

public interface CategoryRepository extends JpaRepository<Category, String> {

    List<Category> findAllByOrderByPriorityDesc();
}
