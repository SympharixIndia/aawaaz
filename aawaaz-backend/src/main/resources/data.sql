-- Seed data, run after schema.sql on every startup (in-memory H2).
-- MERGE makes re-runs within the same JVM idempotent.

-- Default manager: username 'admin', password 'admin123' (BCrypt hashed).
-- No explicit id — let IDENTITY assign it so API-inserted users never collide.
MERGE INTO users (username, name, password_hash, user_type, language_code) KEY (username) VALUES
    ('admin', 'Manager', '$2b$10$.cgEOnMR8ko9v5KB6hxlQe7SNgNH2Ej7X7jA9i8sDSmccm5MckSES', 'MANAGER', 'en-IN');

-- Categories (mirrors the mobile app's defaults).
MERGE INTO categories (category_key, label, priority, is_safety_critical) KEY (category_key) VALUES
    ('safety',     'Safety',         100, TRUE),
    ('health',     'Health',          90, TRUE),
    ('early_exit', 'Early exit',      60, FALSE),
    ('leave',      'Leave',           50, FALSE),
    ('advance',    'Salary advance',  40, FALSE),
    ('other',      'Other',           10, FALSE);
