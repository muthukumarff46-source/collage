-- ============================================================
-- TNEA College Predictor - Authentication Database Schema
-- Single Login Page → Role-based redirect (admin / user)
-- ============================================================

-- ============================================================
CREATE TABLE IF NOT EXISTS colleges (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    college_name VARCHAR(200) NOT NULL,
    location     VARCHAR(100) NOT NULL,
    district     VARCHAR(100) NOT NULL,
    type         ENUM('Government', 'Government Aided', 'Private') NOT NULL,
    website      VARCHAR(255),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================================
-- TABLE 2: cutoffs
-- Stores branch-wise, community-wise cutoff marks
-- Each college can have many rows (one per branch+community combo)
-- ============================================================
CREATE TABLE IF NOT EXISTS cutoffs (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    college_id  INT NOT NULL,
    branch      VARCHAR(10) NOT NULL,   -- e.g. CSE, IT, ECE
    community   VARCHAR(10) NOT NULL,   -- OC, BC, BCM, MBC, SC, ST
    cutoff      DECIMAL(5,2) NOT NULL,  -- cutoff mark out of 200
    year        INT DEFAULT 2024,       -- counselling year
    FOREIGN KEY (college_id) REFERENCES colleges(id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE 3: admin_users
-- Simple admin login table
-- ============================================================
CREATE TABLE IF NOT EXISTS admin_users (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL   -- store hashed password in production!
);

-- Default admin: username=admin, password=admin123
INSERT INTO admin_users (username, password)
VALUES ('admin', 'admin123')
ON DUPLICATE KEY UPDATE username = username;


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


-- ============================================================
-- SAMPLE COLLEGE DATA (20 colleges across TN)
-- ============================================================
INSERT INTO colleges (college_name, location, district, type, website) VALUES
-- Government Colleges
('Anna University, CEG Campus',          'Chennai',      'Chennai',      'Government', 'https://www.annauniv.edu'),
('Government College of Technology',     'Coimbatore',   'Coimbatore',   'Government', 'https://www.gct.ac.in'),
('Thiagarajar College of Engineering',   'Madurai',      'Madurai',      'Government Aided', 'https://www.thiagarajar.edu.in'),
('Coimbatore Institute of Technology',   'Coimbatore',   'Coimbatore',   'Government Aided', 'https://www.cit.ac.in'),
('PSG College of Technology',            'Coimbatore',   'Coimbatore',   'Government Aided', 'https://www.psgtech.edu'),
('Madurai Institute of Engineering',     'Madurai',      'Madurai',      'Government Aided', 'https://www.mie.ac.in'),
('Government College of Engineering',    'Tirunelveli',  'Tirunelveli',  'Government', 'https://www.gce.org.in'),
('Government College of Engineering',    'Salem',        'Salem',        'Government', 'https://www.gce.org.in'),
('Government College of Engineering',    'Thanjavur',    'Thanjavur',    'Government', 'https://www.gce.org.in'),
('Kumaraguru College of Technology',     'Coimbatore',   'Coimbatore',   'Private', 'https://www.kgcollege.edu.in'),
-- Private Colleges
('Sri Venkateswara College of Engg',     'Chennai',      'Chennai',      'Private', 'https://www.svce.edu.in'),
('Sathyabama Institute of Sci & Tech',   'Chennai',      'Chennai',      'Private', 'https://www.sathyabama.edu.in'),
('Vel Tech University',                  'Chennai',      'Chennai',      'Private', 'https://www.veltech.edu.in'),
('KCG College of Technology',            'Chennai',      'Chennai',      'Private', 'https://www.kcgtech.edu.in'),
('Bannari Amman Institute of Tech',      'Erode',        'Erode',        'Private', 'https://www.banasthali.edu.in'),
('Sri Krishna College of Engineering',   'Coimbatore',   'Coimbatore',   'Private', 'https://www.skce.edu.in'),
('KSR College of Engineering',           'Namakkal',     'Namakkal',     'Private', 'https://www.ksrce.edu.in'),
('Lieu Iyer College of Engineering',     'Madurai',      'Madurai',      'Private', 'https://www.liueyer.edu.in'),
('Mepco Schlenk Engineering College',   'Virudhunagar', 'Virudhunagar', 'Government Aided', 'https://www.mepco.edu.in'),
('National Engineering College',         'Kovilpatti',   'Kovilpatti',   'Government Aided', 'https://www.nec.edu.in');

-- ============================================================
-- SAMPLE CUTOFF DATA
-- Format: (college_id, branch, community, cutoff, year)
-- Cutoffs are out of 200
-- ============================================================

-- ---- Anna University CEG (id=1) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(1, 'CSE', 'OC',  198.75, 2024),
(1, 'CSE', 'BC',  197.50, 2024),
(1, 'CSE', 'MBC', 196.25, 2024),
(1, 'CSE', 'SC',  192.00, 2024),
(1, 'CSE', 'ST',  185.00, 2024),
(1, 'IT',  'OC',  197.50, 2024),
(1, 'IT',  'BC',  196.00, 2024),
(1, 'IT',  'MBC', 194.75, 2024),
(1, 'IT',  'SC',  190.00, 2024),
(1, 'ECE', 'OC',  197.00, 2024),
(1, 'ECE', 'BC',  195.75, 2024),
(1, 'ECE', 'MBC', 193.50, 2024),
(1, 'ECE', 'SC',  188.00, 2024);

-- ---- GCT Coimbatore (id=2) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(2, 'CSE', 'OC',  196.50, 2024),
(2, 'CSE', 'BC',  194.75, 2024),
(2, 'CSE', 'MBC', 193.00, 2024),
(2, 'CSE', 'SC',  187.50, 2024),
(2, 'CSE', 'ST',  178.00, 2024),
(2, 'IT',  'OC',  195.25, 2024),
(2, 'IT',  'BC',  193.00, 2024),
(2, 'IT',  'MBC', 191.50, 2024),
(2, 'IT',  'SC',  185.00, 2024),
(2, 'ECE', 'OC',  195.75, 2024),
(2, 'ECE', 'BC',  193.50, 2024),
(2, 'ECE', 'MBC', 192.00, 2024),
(2, 'ECE', 'SC',  186.25, 2024);

-- ---- Thiagarajar College of Engineering (id=3) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(3, 'CSE', 'OC',  195.75, 2024),
(3, 'CSE', 'BC',  193.50, 2024),
(3, 'CSE', 'MBC', 191.25, 2024),
(3, 'CSE', 'SC',  185.75, 2024),
(3, 'IT',  'OC',  194.50, 2024),
(3, 'IT',  'BC',  192.00, 2024),
(3, 'IT',  'MBC', 190.00, 2024),
(3, 'IT',  'SC',  184.00, 2024),
(3, 'ECE', 'OC',  194.75, 2024),
(3, 'ECE', 'BC',  192.25, 2024),
(3, 'ECE', 'MBC', 190.50, 2024),
(3, 'ECE', 'SC',  183.75, 2024);

-- ---- CIT Coimbatore (id=4) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(4, 'CSE', 'OC',  194.25, 2024),
(4, 'CSE', 'BC',  192.00, 2024),
(4, 'CSE', 'MBC', 189.75, 2024),
(4, 'CSE', 'SC',  183.50, 2024),
(4, 'IT',  'OC',  193.00, 2024),
(4, 'IT',  'BC',  190.50, 2024),
(4, 'IT',  'MBC', 188.25, 2024),
(4, 'IT',  'SC',  182.00, 2024),
(4, 'ECE', 'OC',  193.50, 2024),
(4, 'ECE', 'BC',  191.00, 2024),
(4, 'ECE', 'MBC', 188.75, 2024),
(4, 'ECE', 'SC',  182.50, 2024);

-- ---- PSG College of Technology (id=5) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(5, 'CSE', 'OC',  196.00, 2024),
(5, 'CSE', 'BC',  194.25, 2024),
(5, 'CSE', 'MBC', 192.50, 2024),
(5, 'CSE', 'SC',  186.75, 2024),
(5, 'IT',  'OC',  195.00, 2024),
(5, 'IT',  'BC',  193.00, 2024),
(5, 'IT',  'MBC', 191.25, 2024),
(5, 'IT',  'SC',  185.50, 2024),
(5, 'ECE', 'OC',  195.50, 2024),
(5, 'ECE', 'BC',  193.75, 2024),
(5, 'ECE', 'MBC', 191.50, 2024),
(5, 'ECE', 'SC',  186.00, 2024);

-- ---- Madurai Institute of Engineering (id=6) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(6, 'CSE', 'OC',  188.50, 2024),
(6, 'CSE', 'BC',  185.75, 2024),
(6, 'CSE', 'MBC', 183.00, 2024),
(6, 'CSE', 'SC',  176.25, 2024),
(6, 'IT',  'OC',  187.25, 2024),
(6, 'IT',  'BC',  184.50, 2024),
(6, 'IT',  'MBC', 181.75, 2024),
(6, 'ECE', 'OC',  187.75, 2024),
(6, 'ECE', 'BC',  185.00, 2024),
(6, 'ECE', 'MBC', 182.25, 2024),
(6, 'ECE', 'SC',  175.50, 2024);

-- ---- GCE Tirunelveli (id=7) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(7, 'CSE', 'OC',  191.25, 2024),
(7, 'CSE', 'BC',  189.00, 2024),
(7, 'CSE', 'MBC', 186.75, 2024),
(7, 'CSE', 'SC',  180.00, 2024),
(7, 'ECE', 'OC',  190.50, 2024),
(7, 'ECE', 'BC',  188.25, 2024),
(7, 'ECE', 'MBC', 186.00, 2024),
(7, 'ECE', 'SC',  179.50, 2024);

-- ---- GCE Salem (id=8) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(8, 'CSE', 'OC',  190.75, 2024),
(8, 'CSE', 'BC',  188.50, 2024),
(8, 'CSE', 'MBC', 186.25, 2024),
(8, 'CSE', 'SC',  179.75, 2024),
(8, 'IT',  'OC',  189.50, 2024),
(8, 'IT',  'BC',  187.25, 2024),
(8, 'IT',  'MBC', 185.00, 2024),
(8, 'ECE', 'OC',  190.00, 2024),
(8, 'ECE', 'BC',  187.75, 2024),
(8, 'ECE', 'MBC', 185.50, 2024);

-- ---- GCE Thanjavur (id=9) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(9, 'CSE', 'OC',  189.25, 2024),
(9, 'CSE', 'BC',  187.00, 2024),
(9, 'CSE', 'MBC', 184.75, 2024),
(9, 'CSE', 'SC',  178.25, 2024),
(9, 'ECE', 'OC',  188.50, 2024),
(9, 'ECE', 'BC',  186.25, 2024),
(9, 'ECE', 'MBC', 184.00, 2024);

-- ---- Kumaraguru College (id=10) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(10, 'CSE', 'OC',  185.50, 2024),
(10, 'CSE', 'BC',  183.25, 2024),
(10, 'CSE', 'MBC', 181.00, 2024),
(10, 'CSE', 'SC',  174.75, 2024),
(10, 'IT',  'OC',  184.25, 2024),
(10, 'IT',  'BC',  182.00, 2024),
(10, 'IT',  'MBC', 179.75, 2024),
(10, 'ECE', 'OC',  184.75, 2024),
(10, 'ECE', 'BC',  182.50, 2024),
(10, 'ECE', 'MBC', 180.25, 2024);

-- ---- Sri Venkateswara (id=11) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(11, 'CSE', 'OC',  182.75, 2024),
(11, 'CSE', 'BC',  180.50, 2024),
(11, 'CSE', 'MBC', 178.25, 2024),
(11, 'CSE', 'SC',  171.00, 2024),
(11, 'ECE', 'OC',  181.50, 2024),
(11, 'ECE', 'BC',  179.25, 2024),
(11, 'ECE', 'MBC', 177.00, 2024);

-- ---- Sathyabama (id=12) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(12, 'CSE', 'OC',  178.00, 2024),
(12, 'CSE', 'BC',  175.75, 2024),
(12, 'CSE', 'MBC', 173.50, 2024),
(12, 'CSE', 'SC',  166.25, 2024),
(12, 'IT',  'OC',  176.75, 2024),
(12, 'IT',  'BC',  174.50, 2024),
(12, 'IT',  'MBC', 172.25, 2024),
(12, 'ECE', 'OC',  177.50, 2024),
(12, 'ECE', 'BC',  175.25, 2024),
(12, 'ECE', 'MBC', 173.00, 2024);

-- ---- Vel Tech (id=13) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(13, 'CSE', 'OC',  172.50, 2024),
(13, 'CSE', 'BC',  170.25, 2024),
(13, 'CSE', 'MBC', 168.00, 2024),
(13, 'CSE', 'SC',  161.75, 2024),
(13, 'IT',  'OC',  171.25, 2024),
(13, 'IT',  'BC',  169.00, 2024),
(13, 'IT',  'MBC', 166.75, 2024);

-- ---- KCG College (id=14) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(14, 'CSE', 'OC',  168.75, 2024),
(14, 'CSE', 'BC',  166.50, 2024),
(14, 'CSE', 'MBC', 164.25, 2024),
(14, 'CSE', 'SC',  157.00, 2024),
(14, 'ECE', 'OC',  167.50, 2024),
(14, 'ECE', 'BC',  165.25, 2024),
(14, 'ECE', 'MBC', 163.00, 2024);

-- ---- Bannari Amman (id=15) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(15, 'CSE', 'OC',  183.00, 2024),
(15, 'CSE', 'BC',  180.75, 2024),
(15, 'CSE', 'MBC', 178.50, 2024),
(15, 'CSE', 'SC',  171.25, 2024),
(15, 'IT',  'OC',  181.75, 2024),
(15, 'IT',  'BC',  179.50, 2024),
(15, 'IT',  'MBC', 177.25, 2024),
(15, 'ECE', 'OC',  182.50, 2024),
(15, 'ECE', 'BC',  180.25, 2024),
(15, 'ECE', 'MBC', 178.00, 2024);

-- ---- Sri Krishna College (id=16) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(16, 'CSE', 'OC',  175.25, 2024),
(16, 'CSE', 'BC',  173.00, 2024),
(16, 'CSE', 'MBC', 170.75, 2024),
(16, 'CSE', 'SC',  163.50, 2024),
(16, 'ECE', 'OC',  174.00, 2024),
(16, 'ECE', 'BC',  171.75, 2024),
(16, 'ECE', 'MBC', 169.50, 2024);

-- ---- KSR College (id=17) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(17, 'CSE', 'OC',  170.00, 2024),
(17, 'CSE', 'BC',  167.75, 2024),
(17, 'CSE', 'MBC', 165.50, 2024),
(17, 'CSE', 'SC',  158.25, 2024),
(17, 'IT',  'OC',  168.75, 2024),
(17, 'IT',  'BC',  166.50, 2024),
(17, 'IT',  'MBC', 164.25, 2024);

-- ---- Lieu Iyer College (id=18) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(18, 'CSE', 'OC',  165.50, 2024),
(18, 'CSE', 'BC',  163.25, 2024),
(18, 'CSE', 'MBC', 161.00, 2024),
(18, 'CSE', 'SC',  153.75, 2024),
(18, 'ECE', 'OC',  164.25, 2024),
(18, 'ECE', 'BC',  162.00, 2024),
(18, 'ECE', 'MBC', 159.75, 2024);

-- ---- Mepco Schlenk (id=19) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(19, 'CSE', 'OC',  192.00, 2024),
(19, 'CSE', 'BC',  189.75, 2024),
(19, 'CSE', 'MBC', 187.50, 2024),
(19, 'CSE', 'SC',  181.00, 2024),
(19, 'IT',  'OC',  190.75, 2024),
(19, 'IT',  'BC',  188.50, 2024),
(19, 'IT',  'MBC', 186.25, 2024),
(19, 'ECE', 'OC',  191.50, 2024),
(19, 'ECE', 'BC',  189.25, 2024),
(19, 'ECE', 'MBC', 187.00, 2024);

-- ---- National Engineering College (id=20) ----
INSERT INTO cutoffs (college_id, branch, community, cutoff, year) VALUES
(20, 'CSE', 'OC',  190.25, 2024),
(20, 'CSE', 'BC',  188.00, 2024),
(20, 'CSE', 'MBC', 185.75, 2024),
(20, 'CSE', 'SC',  179.25, 2024),
(20, 'IT',  'OC',  189.00, 2024),
(20, 'IT',  'BC',  186.75, 2024),
(20, 'IT',  'MBC', 184.50, 2024),
(20, 'ECE', 'OC',  189.75, 2024),
(20, 'ECE', 'BC',  187.50, 2024),
(20, 'ECE', 'MBC', 185.25, 2024);

-- Show summary
SELECT 'Database setup complete!' AS status;
SELECT COUNT(*) AS total_colleges FROM colleges;
SELECT COUNT(*) AS total_cutoff_records FROM cutoffs;

