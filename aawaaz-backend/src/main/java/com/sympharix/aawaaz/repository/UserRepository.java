package com.sympharix.aawaaz.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.sympharix.aawaaz.domain.User;
import com.sympharix.aawaaz.domain.UserType;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByUsernameIgnoreCase(String username);

    boolean existsByUsernameIgnoreCase(String username);

    /** The manager whose language is the translation target (V2 has one). */
    Optional<User> findFirstByUserType(UserType userType);
}
