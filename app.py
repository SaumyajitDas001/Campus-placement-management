import os
import subprocess
from decimal import Decimal
from pathlib import Path

import psycopg
from flask import Flask, jsonify, render_template, request
from psycopg.rows import dict_row


app = Flask(__name__)

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:Saumyajit%402004@localhost:5433/campus_placement",
)

PGADMIN_CANDIDATES = [
    Path(r"C:\Program Files\PostgreSQL\18\pgAdmin 4\runtime\pgAdmin4.exe"),
    Path(r"C:\Program Files\PostgreSQL\17\pgAdmin 4\runtime\pgAdmin4.exe"),
]

PSQL_CANDIDATES = [
    Path(r"C:\Program Files\PostgreSQL\18\bin\psql.exe"),
    Path(r"C:\Program Files\PostgreSQL\17\bin\psql.exe"),
]


def db_query(sql, params=None, fetch=True):
    with psycopg.connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            if fetch:
                return [serialize_row(row) for row in cur.fetchall()]
            conn.commit()
            return []


def db_one(sql, params=None):
    rows = db_query(sql, params)
    return rows[0] if rows else None


@app.errorhandler(psycopg.Error)
def handle_database_error(error):
    return jsonify(
        {
            "error": "Database error",
            "detail": str(error).strip(),
            "hint": "Run setup_database_cmd.bat, then restart Flask.",
        }
    ), 500


@app.errorhandler(Exception)
def handle_unexpected_error(error):
    return jsonify(
        {
            "error": "Server error",
            "detail": str(error).strip(),
        }
    ), 500


def serialize_row(row):
    serialized = {}
    for key, value in row.items():
        if isinstance(value, Decimal):
            serialized[key] = float(value)
        elif hasattr(value, "isoformat"):
            serialized[key] = value.isoformat()
        else:
            serialized[key] = value
    return serialized


@app.get("/")
def index():
    return render_template("index.html")


@app.get("/api/summary")
def summary():
    return jsonify(
        {
            "students": db_one("SELECT COUNT(*) AS total FROM students")["total"],
            "companies": db_one("SELECT COUNT(*) AS total FROM companies")["total"],
            "applications": db_one("SELECT COUNT(*) AS total FROM applications")["total"],
            "scheduled": db_one("SELECT COUNT(*) AS total FROM interview_schedules")["total"],
        }
    )


@app.get("/api/health")
def health():
    row = db_one("SELECT current_database() AS database, current_user AS user")
    return jsonify({"ok": True, **row})


@app.post("/api/open-postgres")
def open_postgres():
    launch_env = os.environ.copy()
    for key in ("FLASK_RUN_FROM_CLI", "WERKZEUG_SERVER_FD"):
        launch_env.pop(key, None)

    for pgadmin_path in PGADMIN_CANDIDATES:
        if pgadmin_path.exists():
            subprocess.Popen([str(pgadmin_path)], shell=False, env=launch_env)
            return jsonify(
                {
                    "ok": True,
                    "opened": "pgAdmin 4",
                    "path": str(pgadmin_path),
                    "database": "campus_placement",
                    "host": "localhost",
                    "port": 5433,
                    "user": "postgres",
                }
            )

    for psql_path in PSQL_CANDIDATES:
        if psql_path.exists():
            command = (
                f'set PGPASSWORD=Saumyajit@2004 && "{psql_path}" '
                "-h localhost -p 5433 -U postgres -d campus_placement"
            )
            subprocess.Popen(["cmd", "/k", command], shell=False, env=launch_env)
            return jsonify(
                {
                    "ok": True,
                    "opened": "psql",
                    "path": str(psql_path),
                    "database": "campus_placement",
                    "host": "localhost",
                    "port": 5433,
                    "user": "postgres",
                }
            )

    return jsonify({"error": "Could not find pgAdmin or psql on this computer."}), 404


@app.get("/api/companies")
def companies():
    return jsonify(
        db_query(
            """
            SELECT company_id, name, package_lpa, openings, min_cgpa, max_backlogs, status
            FROM companies
            ORDER BY package_lpa DESC, name
            """
        )
    )


@app.get("/api/eligible")
def eligible():
    company_id = request.args.get("company_id", type=int)
    sql = """
        SELECT company_id, company_name, roll_no, full_name, department_code,
               cgpa, backlogs, package_lpa, match_score
        FROM v_eligible_students
    """
    params = []
    if company_id:
        sql += " WHERE company_id = %s"
        params.append(company_id)
    sql += " ORDER BY company_name, match_score DESC, cgpa DESC LIMIT 250"
    return jsonify(db_query(sql, params))


@app.get("/api/students")
def students():
    search = request.args.get("q", "").strip()
    params = []
    sql = """
        SELECT student_id, roll_no, full_name, department_code, department_name,
               email, phone_number, cgpa, backlogs, graduation_year, placement_status, skills,
               application_count, interview_count, academic_average_sgpa
        FROM v_student_profiles
    """
    if search:
        sql += """
            WHERE roll_no ILIKE %s
               OR full_name ILIKE %s
               OR department_code ILIKE %s
        """
        pattern = f"%{search}%"
        params.extend([pattern, pattern, pattern])
    sql += " ORDER BY roll_no LIMIT 500"
    return jsonify(db_query(sql, params))


@app.get("/api/students/<int:student_id>/marks")
def student_marks(student_id):
    profile = db_one(
        """
        SELECT student_id, roll_no, full_name, department_code, department_name,
               email, phone_number, cgpa, backlogs, graduation_year, placement_status, skills,
               application_count, interview_count, academic_average_sgpa
        FROM v_student_profiles
        WHERE student_id = %s
        """,
        [student_id],
    )
    if not profile:
        return jsonify({"error": "Student not found"}), 404

    marks = db_query(
        """
        SELECT
            sub.semester_no,
            sub.subject_code,
            sub.subject_name,
            sub.credits,
            m.internal_marks,
            m.external_marks,
            m.total_marks,
            m.grade,
            m.exam_status
        FROM student_semester_marks m
        JOIN subjects sub ON sub.subject_id = m.subject_id
        WHERE m.student_id = %s
        ORDER BY sub.semester_no, sub.subject_code
        """,
        [student_id],
    )

    semesters = db_query(
        """
        SELECT
            sub.semester_no,
            ROUND(AVG(m.total_marks), 2) AS average_marks,
            ROUND(SUM(
                CASE m.grade
                    WHEN 'O' THEN 10
                    WHEN 'A+' THEN 9
                    WHEN 'A' THEN 8
                    WHEN 'B+' THEN 7
                    WHEN 'B' THEN 6
                    WHEN 'C' THEN 5
                    WHEN 'P' THEN 4
                    ELSE 0
                END * sub.credits)::numeric / NULLIF(SUM(sub.credits), 0), 2) AS sgpa,
            COUNT(*) FILTER (WHERE m.exam_status = 'BACKLOG') AS backlogs
        FROM student_semester_marks m
        JOIN subjects sub ON sub.subject_id = m.subject_id
        WHERE m.student_id = %s
        GROUP BY sub.semester_no
        ORDER BY sub.semester_no
        """,
        [student_id],
    )

    return jsonify({"profile": profile, "semesters": semesters, "marks": marks})


@app.get("/api/schedule")
def schedule():
    return jsonify(
        db_query(
            """
            SELECT roll_no, full_name, company_name, round_no, starts_at, ends_at, venue, status
            FROM v_student_schedule
            ORDER BY starts_at, company_name, roll_no
            """
        )
    )


@app.get("/api/dashboard")
def dashboard():
    return jsonify(
        db_query(
            """
            SELECT company_id, name, openings, package_lpa, applications,
                   scheduled_interviews, accepted_offers
            FROM v_company_dashboard
            ORDER BY package_lpa DESC, name
            """
        )
    )


@app.get("/api/matching-edges")
def matching_edges():
    return jsonify(
        db_query(
            """
            SELECT
                e.student_id,
                s.roll_no,
                s.full_name,
                e.company_id,
                c.name AS company_name,
                e.slot_id,
                lower(sl.slot_range) AS starts_at,
                upper(sl.slot_range) AS ends_at,
                e.match_score
            FROM v_matching_edges e
            JOIN students s ON s.student_id = e.student_id
            JOIN companies c ON c.company_id = e.company_id
            JOIN interview_slots sl ON sl.slot_id = e.slot_id
            ORDER BY e.match_score DESC, c.name, s.roll_no
            LIMIT 120
            """
        )
    )


@app.post("/api/schedule-greedy")
def schedule_greedy():
    payload = request.get_json(silent=True) or {}
    company_id = payload.get("company_id")
    if not company_id:
        return jsonify({"error": "company_id is required"}), 400

    try:
        rows = db_query("SELECT * FROM schedule_company_greedy(%s)", [company_id])
        return jsonify({"scheduled_count": len(rows), "rows": rows})
    except psycopg.Error as exc:
        return jsonify({"error": str(exc)}), 400


@app.post("/api/book")
def book():
    payload = request.get_json(silent=True) or {}
    required = ["student_id", "company_id", "slot_id"]
    missing = [key for key in required if not payload.get(key)]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    try:
        row = db_one(
            "SELECT book_interview(%s, %s, %s) AS schedule_id",
            [payload["student_id"], payload["company_id"], payload["slot_id"]],
        )
        return jsonify(row)
    except psycopg.Error as exc:
        return jsonify({"error": str(exc)}), 400


if __name__ == "__main__":
    app.run(debug=True)
