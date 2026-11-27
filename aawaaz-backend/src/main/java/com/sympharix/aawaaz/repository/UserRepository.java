package com.sympharix.aawaaz.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.sympharix.aawaaz.domain.User;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByUsernameIgnoreCase(String username);

    boolean existsByUsernameIgnoreCase(String username);
}
