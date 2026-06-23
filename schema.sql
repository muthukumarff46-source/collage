-- ============================================================
-- TNEA College Predictor - Authentication Database Schema
-- Single Login Page → Role-based redirect (admin / user)
-- ============================================================

CREATE DATABASE IF NOT EXISTS tnea_db;
USE tnea_db;

-- ============================================================
-- TABLE: users  (Single table for BOTH admin and student)
-- role = 'admin'  → goes to Admin Dashboard
-- role = 'user'   → goes to Prediction Page
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100)  NOT NULL,
    email         VARCHAR(150)  UNIQUE NOT NULL,
    password      VARCHAR(255)  NOT NULL,       -- store hashed (werkzeug)
    role          ENUM('admin','user') NOT NULL DEFAULT 'user',
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    last_login    TIMESTAMP     NULL
);

-- ============================================================
-- DEFAULT ACCOUNTS  (password stored as plain for demo;
--  in real app use generate_password_hash from werkzeug)
-- admin  → email: admin@tnea.com   password: Admin@123
-- user   → email: student@tnea.com password: Student@123
-- ============================================================

-- NOTE: In app.py we use check_password_hash / generate_password_hash
-- So insert hashed values here. For demo we insert plain and let
-- the seed script hash them.  See seed_users.py below.

-- Plain-text seed (only for quick demo; replace with hashed in prod):
INSERT IGNORE INTO users (full_name, email, password, role) VALUES
('Admin User',   'admin@tnea.com',   'Admin@123',   'admin'),
('Test Student', 'student@tnea.com', 'Student@123', 'user');

-- ============================================================
-- TABLE: colleges
-- ============================================================
CREATE TABLE IF NOT EXISTS colleges (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    college_name  VARCHAR(200) NOT NULL,
    location      VARCHAR(100) NOT NULL,
    district      VARCHAR(100) NOT NULL,
    type          ENUM('Government','Government Aided','Private') NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TABLE: cutoffs
-- ============================================================
CREATE TABLE IF NOT EXISTS cutoffs (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    college_id    INT NOT NULL,
    branch        VARCHAR(50)  NOT NULL,
    community     ENUM('OC','BC','BCM','MBC','SC','ST') NOT NULL,
    cutoff        DECIMAL(5,2) NOT NULL,
    year          INT          DEFAULT 2024,
    FOREIGN KEY (college_id) REFERENCES colleges(id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: prediction_logs  (track who searched what)
-- ============================================================
CREATE TABLE IF NOT EXISTS prediction_logs (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT          NULL,
    cutoff_mark   DECIMAL(5,2) NOT NULL,
    community     VARCHAR(10)  NOT NULL,
    branch        VARCHAR(50)  NOT NULL,
    district      VARCHAR(100) NOT NULL,
    result_count  INT          DEFAULT 0,
    searched_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

SELECT 'Schema created successfully!' AS status;
