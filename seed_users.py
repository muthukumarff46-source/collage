# seed_users.py
# Run this ONCE after schema.sql to insert hashed-password users
# Usage: python seed_users.py

import mysql.connector
from werkzeug.security import generate_password_hash

DB_CONFIG = {
    'host':     'sql12.freesqldatabase.com',
    'user':     'sql12831390',
    'password': 'FQJNpGdHD6',
    'database': 'sql12831390',
    'port':     3306
}

users = [
    {
        'full_name': 'Admin User',
        'email':     'admin@tnea.com',
        'password':  'Admin@123',
        'role':      'admin'
    },
    {
        'full_name': 'Test Student',
        'email':     'student@tnea.com',
        'password':  'Student@123',
        'role':      'user'
    },
]

try:
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()
    print("✅ DB Connected!")

    # Clear old demo users
    cursor.execute("DELETE FROM users WHERE email IN ('admin@tnea.com','student@tnea.com')")

    for u in users:
        hashed = generate_password_hash(u['password'])
        cursor.execute(
            "INSERT INTO users (full_name, email, password, role) VALUES (%s,%s,%s,%s)",
            (u['full_name'], u['email'], hashed, u['role'])
        )
        print(f"✅ Created {u['role']}: {u['email']} / {u['password']}")

    conn.commit()
    cursor.close()
    conn.close()
    print("\n✅ Done! Login with above credentials.")

except Exception as e:
    print(f"❌ Error: {e}")
