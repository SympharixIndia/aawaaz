package com.sympharix.aawaaz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

/** Verifies Flyway created the schema and seeded the default data on startup. */
@SpringBootTest
class SchemaSeedTest {

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void seedsDefaultManager() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM users WHERE username = 'admin' AND user_type = 'MANAGER'",
                Integer.class);
        assertEquals(1, count);
    }

    @Test
    void seedsSixCategories() {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM categories", Integer.class);
        assertEquals(6, count);
    }

    @Test
    void safetyIsHighestPriorityAndSafetyCritical() {
        Integer priority = jdbc.queryForObject(
                "SELECT priority FROM categories WHERE category_key = 'safety'", Integer.class);
        Boolean critical = jdbc.queryForObject(
                "SELECT is_safety_critical FROM categories WHERE category_key = 'safety'",
                Boolean.class);
        Integer maxPriority = jdbc.queryForObject("SELECT MAX(priority) FROM categories", Integer.class);
        assertEquals(priority, maxPriority);
        assertTrue(Boolean.TRUE.equals(critical));
    }

    @Test
    void requestsTableExists() {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM requests", Integer.class);
        assertEquals(0, count);
    }
}
