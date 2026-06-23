# ============================================================
# app.py  –  TNEA College Predictor
# Single Login Page → role-based redirect
#   admin → /admin/dashboard
#   user  → /predict
# ============================================================
import os
from dotenv import load_dotenv
from flask import (Flask, render_template, request,
                   redirect, url_for, session, flash, jsonify)
import mysql.connector
from mysql.connector import Error
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
from datetime import datetime
load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY')   # change in production!

# ── DB config ─────────────────────────────────────────────
DB_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'database': os.getenv('DB_NAME'),
    'port': int(os.getenv('DB_PORT', 3306))
}

def get_db():
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except Error as e:
        print(f"[DB ERROR] {e}")
        return None

# ============================================================
# DECORATORS  –  protect routes by role
# ============================================================

def login_required(f):
    """Block access if not logged in at all."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please login to continue.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

def admin_required(f):
    """Block access if logged in as student (not admin)."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please login to continue.', 'warning')
            return redirect(url_for('login'))
        if session.get('role') != 'admin':
            flash('Access denied. Admins only.', 'danger')
            return redirect(url_for('predict_page'))
        return f(*args, **kwargs)
    return decorated

def user_required(f):
    """Block admin from accessing student pages (optional guard)."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please login to continue.', 'warning')
            return redirect(url_for('login'))
        # admins CAN see student pages too; remove next 3 lines if you want
        # if session.get('role') == 'admin':
        #     return redirect(url_for('admin_dashboard'))
        return f(*args, **kwargs)
    return decorated

# ============================================================
# ROUTE 1  –  HOME  →  redirect based on login state
# ============================================================
@app.route('/')
def index():
    if 'user_id' in session:
        if session['role'] == 'admin':
            return redirect(url_for('admin_dashboard'))
        return redirect(url_for('predict_page'))
    return redirect(url_for('login'))

# ============================================================
# ROUTE 2  –  SINGLE LOGIN PAGE  (GET + POST)
# ============================================================
@app.route('/login', methods=['GET', 'POST'])
def login():
    # Already logged in → redirect to their dashboard
    if 'user_id' in session:
        return redirect(url_for('index'))

    if request.method == 'POST':
        email    = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '').strip()

        # ── Basic validation ──────────────────────────────
        if not email or not password:
            flash('Email and password are required.', 'danger')
            return render_template('login.html')

        # ── Fetch user from DB ────────────────────────────
        conn = get_db()
        if not conn:
            flash('Database error. Try again later.', 'danger')
            return render_template('login.html')

        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT * FROM users WHERE email = %s AND is_active = TRUE",
            (email,)
        )
        user = cursor.fetchone()

        # ── Password check ────────────────────────────────
        if user and check_password_hash(user['password'], password):
            # Update last_login
            cursor.execute(
                "UPDATE users SET last_login = %s WHERE id = %s",
                (datetime.now(), user['id'])
            )
            conn.commit()
            cursor.close()
            conn.close()

            # ── Store session ─────────────────────────────
            session.clear()
            session['user_id']   = user['id']
            session['full_name'] = user['full_name']
            session['email']     = user['email']
            session['role']      = user['role']      # 'admin' or 'user'

            flash(f"Welcome, {user['full_name']}! Logged in as {user['role'].upper()}.", 'success')

            # ── Role-based redirect ───────────────────────
            if user['role'] == 'admin':
                return redirect(url_for('admin_dashboard'))
            else:
                return redirect(url_for('predict_page'))

        else:
            cursor.close()
            conn.close()
            flash('Invalid email or password. Please try again.', 'danger')
            return render_template('login.html')

    # GET request → show login form
    return render_template('login.html')

# ============================================================
# ROUTE 3  –  REGISTER (optional self-registration for students)
# ============================================================
@app.route('/register', methods=['GET', 'POST'])
def register():
    if 'user_id' in session:
        return redirect(url_for('index'))

    if request.method == 'POST':
        full_name = request.form.get('full_name', '').strip()
        email     = request.form.get('email', '').strip().lower()
        password  = request.form.get('password', '').strip()
        confirm   = request.form.get('confirm_password', '').strip()

        # Validation
        if not full_name or not email or not password:
            flash('All fields are required.', 'danger')
            return render_template('register.html')

        if password != confirm:
            flash('Passwords do not match.', 'danger')
            return render_template('register.html')

        if len(password) < 6:
            flash('Password must be at least 6 characters.', 'danger')
            return render_template('register.html')

        conn = get_db()
        if not conn:
            flash('Database error.', 'danger')
            return render_template('register.html')

        cursor = conn.cursor()
        try:
            hashed = generate_password_hash(password)
            cursor.execute(
                "INSERT INTO users (full_name, email, password, role) VALUES (%s,%s,%s,'user')",
                (full_name, email, hashed)
            )
            conn.commit()
            flash('Registration successful! Please login.', 'success')
            return redirect(url_for('login'))
        except Error as e:
            if 'Duplicate entry' in str(e):
                flash('Email already registered. Please login.', 'warning')
            else:
                flash('Registration failed. Try again.', 'danger')
        finally:
            cursor.close()
            conn.close()

    return render_template('register.html')

# ============================================================
# ROUTE 4  –  LOGOUT
# ============================================================
@app.route('/logout')
def logout():
    name = session.get('full_name', 'User')
    session.clear()
    flash(f'{name} logged out successfully.', 'info')
    return redirect(url_for('login'))

# ============================================================
# ROUTE 5  –  STUDENT PREDICTION PAGE  (role: user or admin)
# ============================================================
@app.route('/predict')
@login_required
def predict_page():
    return render_template('predict.html',
                           user=session.get('full_name'),
                           role=session.get('role'))

@app.route('/predict/result', methods=['POST'])
@login_required
def predict_result():
    try:
        cutoff    = float(request.form.get('cutoff', 0))
        community = request.form.get('community', 'OC').upper()
        branch    = request.form.get('branch', 'CSE').upper()
        district  = request.form.get('district', '').strip()
    except ValueError:
        flash('Invalid cutoff mark entered.', 'danger')
        return redirect(url_for('predict_page'))

    if not (0 <= cutoff <= 200):
        flash('Cutoff must be between 0 and 200.', 'danger')
        return redirect(url_for('predict_page'))

    conn = get_db()
    if not conn:
        flash('Database error.', 'danger')
        return redirect(url_for('predict_page'))

    cursor = conn.cursor(dictionary=True)

    # ── Query colleges where student cutoff >= college cutoff ──
    sql = """
        SELECT c.college_name, c.location, c.district,
               c.type AS college_type,c.website,
               cu.branch, cu.community, cu.cutoff, cu.year
        FROM   colleges c
        JOIN   cutoffs  cu ON c.id = cu.college_id
        WHERE  cu.branch    = %s
          AND  cu.community = %s
          AND  cu.cutoff   <= %s
    """
    params = [branch, community, cutoff]

    if district and district.lower() != 'all':
        sql += " AND c.district = %s"
        params.append(district)

    sql += " ORDER BY cu.cutoff DESC"
    cursor.execute(sql, tuple(params))
    all_colleges = cursor.fetchall()

    # ── Tiering logic ──────────────────────────────────────────
    safe, moderate, dream = [], [], []
    for col in all_colleges:
        col_cutoff = float(col['cutoff'])
        diff = float(cutoff) - float(col['cutoff'])
        col['cutoff'] = col_cutoff 
        col['diff'] = diff  
        if diff >= 10:
            safe.append(col)
        elif diff >= 5:
            moderate.append(col)
        else:
            dream.append(col)

    # ── Log the search ─────────────────────────────────────────
    try:
        cursor.execute(
            """INSERT INTO prediction_logs
               (user_id, cutoff_mark, community, branch, district, result_count)
               VALUES (%s,%s,%s,%s,%s,%s)""",
            (session['user_id'], cutoff, community, branch,
             district or 'All', len(all_colleges))
        )
        conn.commit()
    except Exception:
        pass
    finally:
        cursor.close()
        conn.close()

    return render_template('result.html',
                           cutoff=cutoff,
                           community=community,
                           branch=branch,
                           district=district or 'All Tamil Nadu',
                           safe=safe,
                           moderate=moderate,
                           dream=dream,
                           total=len(all_colleges),
                           user=session.get('full_name'),
                           role=session.get('role'))

# ============================================================
# ROUTE 6  –  ADMIN DASHBOARD  (role: admin only)
# ============================================================
@app.route('/admin/dashboard')
@admin_required
def admin_dashboard():
    conn = get_db()
    if not conn:
        flash('Database error.', 'danger')
        return render_template('admin_dashboard.html',
                               users=[], logs=[], stats={})

    cursor = conn.cursor(dictionary=True)

    # All users
    cursor.execute("SELECT id, full_name, email, role, is_active, created_at, last_login FROM users ORDER BY created_at DESC")
    users = cursor.fetchall()

    # Recent prediction logs
    cursor.execute("""
        SELECT pl.*, u.full_name, u.email
        FROM prediction_logs pl
        LEFT JOIN users u ON pl.user_id = u.id
        ORDER BY pl.searched_at DESC
        LIMIT 50
    """)
    logs = cursor.fetchall()

    # Stats
    cursor.execute("SELECT COUNT(*) AS total FROM users WHERE role='user'")
    total_students = cursor.fetchone()['total']

    cursor.execute("SELECT COUNT(*) AS total FROM users WHERE role='admin'")
    total_admins = cursor.fetchone()['total']

    cursor.execute("SELECT COUNT(*) AS total FROM colleges")
    total_colleges = cursor.fetchone()['total']

    cursor.execute("SELECT COUNT(*) AS total FROM prediction_logs")
    total_searches = cursor.fetchone()['total']

    cursor.close()
    conn.close()

    stats = {
        'students': total_students,
        'admins':   total_admins,
        'colleges': total_colleges,
        'searches': total_searches,
    }

    return render_template('admin_dashboard.html',
                           users=users,
                           logs=logs,
                           stats=stats,
                           admin_name=session.get('full_name'))

# ── Admin: Add new user ──────────────────────────────────────
@app.route('/admin/add_user', methods=['POST'])
@admin_required
def admin_add_user():
    full_name = request.form.get('full_name', '').strip()
    email     = request.form.get('email', '').strip().lower()
    password  = request.form.get('password', '').strip()
    role      = request.form.get('role', 'user')

    if not full_name or not email or not password:
        flash('All fields required to add user.', 'danger')
        return redirect(url_for('admin_dashboard'))

    conn = get_db()
    cursor = conn.cursor()
    try:
        hashed = generate_password_hash(password)
        cursor.execute(
            "INSERT INTO users (full_name, email, password, role) VALUES (%s,%s,%s,%s)",
            (full_name, email, hashed, role)
        )
        conn.commit()
        flash(f'User "{full_name}" ({role}) created successfully!', 'success')
    except Error as e:
        if 'Duplicate entry' in str(e):
            flash('Email already exists.', 'warning')
        else:
            flash('Error creating user.', 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin_dashboard'))

# ── Admin: Toggle user active/inactive ──────────────────────
@app.route('/admin/toggle_user/<int:user_id>')
@admin_required
def toggle_user(user_id):
    if user_id == session['user_id']:
        flash('You cannot deactivate your own account.', 'warning')
        return redirect(url_for('admin_dashboard'))

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE users SET is_active = NOT is_active WHERE id = %s", (user_id,)
    )
    conn.commit()
    cursor.close()
    conn.close()
    flash('User status updated.', 'success')
    return redirect(url_for('admin_dashboard'))

# ── Admin: Change role ────────────────────────────────────────
@app.route('/admin/change_role/<int:user_id>/<string:new_role>')
@admin_required
def change_role(user_id, new_role):
    if new_role not in ('admin', 'user'):
        flash('Invalid role.', 'danger')
        return redirect(url_for('admin_dashboard'))

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET role=%s WHERE id=%s", (new_role, user_id))
    conn.commit()
    cursor.close()
    conn.close()
    flash('User role updated successfully.', 'success')
    return redirect(url_for('admin_dashboard'))

# ── Admin: Delete user ────────────────────────────────────────
@app.route('/admin/delete_user/<int:user_id>')
@admin_required
def delete_user(user_id):
    if user_id == session['user_id']:
        flash('You cannot delete your own account.', 'warning')
        return redirect(url_for('admin_dashboard'))

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
    conn.commit()
    cursor.close()
    conn.close()
    flash('User deleted.', 'success')
    return redirect(url_for('admin_dashboard'))

# ============================================================
if __name__ == '__main__':
    app.run(debug=True)
