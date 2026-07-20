CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS offers CASCADE;
DROP TABLE IF EXISTS interview_schedules CASCADE;
DROP TABLE IF EXISTS interview_slots CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS company_required_skills CASCADE;
DROP TABLE IF EXISTS company_departments CASCADE;
DROP TABLE IF EXISTS student_skills CASCADE;
DROP TABLE IF EXISTS student_semester_marks CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    department_id BIGSERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE skills (
    skill_id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE students (
    student_id BIGSERIAL PRIMARY KEY,
    roll_no TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone_number TEXT NOT NULL UNIQUE,
    department_id BIGINT NOT NULL REFERENCES departments(department_id),
    cgpa NUMERIC(3,2) NOT NULL CHECK (cgpa >= 0 AND cgpa <= 10),
    backlogs INT NOT NULL DEFAULT 0 CHECK (backlogs >= 0),
    graduation_year INT NOT NULL CHECK (graduation_year BETWEEN 2000 AND 2100),
    placement_status TEXT NOT NULL DEFAULT 'NOT_PLACED'
        CHECK (placement_status IN ('NOT_PLACED', 'OFFERED', 'PLACED', 'BLOCKED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE student_skills (
    student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    skill_id BIGINT NOT NULL REFERENCES skills(skill_id) ON DELETE CASCADE,
    proficiency INT NOT NULL DEFAULT 3 CHECK (proficiency BETWEEN 1 AND 5),
    PRIMARY KEY (student_id, skill_id)
);

CREATE TABLE subjects (
    subject_id BIGSERIAL PRIMARY KEY,
    department_id BIGINT NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    semester_no INT NOT NULL CHECK (semester_no BETWEEN 1 AND 8),
    subject_code TEXT NOT NULL,
    subject_name TEXT NOT NULL,
    credits INT NOT NULL DEFAULT 3 CHECK (credits BETWEEN 1 AND 6),
    UNIQUE (department_id, semester_no, subject_code)
);

CREATE TABLE student_semester_marks (
    mark_id BIGSERIAL PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    subject_id BIGINT NOT NULL REFERENCES subjects(subject_id) ON DELETE CASCADE,
    internal_marks INT NOT NULL CHECK (internal_marks BETWEEN 0 AND 30),
    external_marks INT NOT NULL CHECK (external_marks BETWEEN 0 AND 70),
    total_marks INT GENERATED ALWAYS AS (internal_marks + external_marks) STORED,
    grade TEXT NOT NULL CHECK (grade IN ('O', 'A+', 'A', 'B+', 'B', 'C', 'P', 'F')),
    exam_status TEXT NOT NULL DEFAULT 'PASS' CHECK (exam_status IN ('PASS', 'BACKLOG')),
    UNIQUE (student_id, subject_id)
);

CREATE TABLE companies (
    company_id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    package_lpa NUMERIC(8,2) NOT NULL CHECK (package_lpa >= 0),
    openings INT NOT NULL CHECK (openings > 0),
    min_cgpa NUMERIC(3,2) NOT NULL CHECK (min_cgpa >= 0 AND min_cgpa <= 10),
    max_backlogs INT NOT NULL DEFAULT 0 CHECK (max_backlogs >= 0),
    status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE company_departments (
    company_id BIGINT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    department_id BIGINT NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    PRIMARY KEY (company_id, department_id)
);

CREATE TABLE company_required_skills (
    company_id BIGINT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    skill_id BIGINT NOT NULL REFERENCES skills(skill_id) ON DELETE CASCADE,
    min_proficiency INT NOT NULL DEFAULT 1 CHECK (min_proficiency BETWEEN 1 AND 5),
    weight INT NOT NULL DEFAULT 1 CHECK (weight > 0),
    PRIMARY KEY (company_id, skill_id)
);

CREATE TABLE applications (
    application_id BIGSERIAL PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    company_id BIGINT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'APPLIED'
        CHECK (status IN ('APPLIED', 'SHORTLISTED', 'SCHEDULED', 'REJECTED', 'SELECTED', 'WITHDRAWN')),
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, company_id)
);

CREATE TABLE interview_slots (
    slot_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    round_no INT NOT NULL DEFAULT 1 CHECK (round_no > 0),
    slot_range TSTZRANGE NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    booked_count INT NOT NULL DEFAULT 0 CHECK (booked_count >= 0),
    venue TEXT NOT NULL,
    CHECK (booked_count <= capacity),
    EXCLUDE USING gist (
        company_id WITH =,
        venue WITH =,
        slot_range WITH &&
    )
);

CREATE TABLE interview_schedules (
    schedule_id BIGSERIAL PRIMARY KEY,
    application_id BIGINT NOT NULL REFERENCES applications(application_id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    company_id BIGINT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    slot_id BIGINT NOT NULL REFERENCES interview_slots(slot_id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'SCHEDULED'
        CHECK (status IN ('SCHEDULED', 'COMPLETED', 'NO_SHOW', 'CANCELLED')),
    scheduled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (application_id),
    UNIQUE (student_id, company_id),
    EXCLUDE USING gist (
        student_id WITH =,
        (slot_id) WITH =
    )
);

CREATE TABLE offers (
    offer_id BIGSERIAL PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    company_id BIGINT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    offered_lpa NUMERIC(8,2) NOT NULL CHECK (offered_lpa >= 0),
    status TEXT NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')),
    offered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, company_id)
);

CREATE INDEX idx_students_department_cgpa ON students(department_id, cgpa DESC);
CREATE INDEX idx_students_backlogs ON students(backlogs);
CREATE INDEX idx_student_skills_skill ON student_skills(skill_id, student_id);
CREATE INDEX idx_subjects_department_semester ON subjects(department_id, semester_no);
CREATE INDEX idx_marks_student_subject ON student_semester_marks(student_id, subject_id);
CREATE INDEX idx_applications_company_status ON applications(company_id, status);
CREATE INDEX idx_slots_company_range ON interview_slots USING gist (company_id, slot_range);
CREATE INDEX idx_slots_available ON interview_slots(company_id, booked_count, capacity);

CREATE OR REPLACE VIEW v_eligible_students AS
WITH required AS (
    SELECT company_id, COUNT(*) AS required_skill_count, COALESCE(SUM(weight), 0) AS total_weight
    FROM company_required_skills
    GROUP BY company_id
),
matched AS (
    SELECT
        s.student_id,
        c.company_id,
        COUNT(crs.skill_id) AS matched_skill_count,
        COALESCE(SUM(crs.weight * ss.proficiency), 0) AS skill_score
    FROM students s
    CROSS JOIN companies c
    LEFT JOIN company_required_skills crs ON crs.company_id = c.company_id
    LEFT JOIN student_skills ss
        ON ss.student_id = s.student_id
       AND ss.skill_id = crs.skill_id
       AND ss.proficiency >= crs.min_proficiency
    WHERE crs.skill_id IS NULL OR ss.skill_id IS NOT NULL
    GROUP BY s.student_id, c.company_id
)
SELECT
    s.student_id,
    s.roll_no,
    s.full_name,
    s.email,
    s.phone_number,
    d.code AS department_code,
    s.cgpa,
    s.backlogs,
    c.company_id,
    c.name AS company_name,
    c.package_lpa,
    COALESCE(m.skill_score, 0) + (s.cgpa * 10) - (s.backlogs * 5) AS match_score
FROM students s
JOIN departments d ON d.department_id = s.department_id
JOIN companies c ON c.status = 'OPEN'
JOIN company_departments cd
    ON cd.company_id = c.company_id
   AND cd.department_id = s.department_id
LEFT JOIN required r ON r.company_id = c.company_id
LEFT JOIN matched m ON m.student_id = s.student_id AND m.company_id = c.company_id
WHERE s.cgpa >= c.min_cgpa
  AND s.backlogs <= c.max_backlogs
  AND COALESCE(m.matched_skill_count, 0) = COALESCE(r.required_skill_count, 0);

CREATE OR REPLACE VIEW v_student_profiles AS
WITH sgpa AS (
    SELECT
        m.student_id,
        sub.semester_no,
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
            END * sub.credits)::numeric / NULLIF(SUM(sub.credits), 0), 2) AS sgpa
    FROM student_semester_marks m
    JOIN subjects sub ON sub.subject_id = m.subject_id
    GROUP BY m.student_id, sub.semester_no
),
skill_summary AS (
    SELECT
        ss.student_id,
        string_agg(sk.name || ' (' || ss.proficiency || ')', ', ' ORDER BY sk.name) AS skills
    FROM student_skills ss
    JOIN skills sk ON sk.skill_id = ss.skill_id
    GROUP BY ss.student_id
)
SELECT
    s.student_id,
    s.roll_no,
    s.full_name,
    s.email,
    s.phone_number,
    d.code AS department_code,
    d.name AS department_name,
    s.cgpa,
    s.backlogs,
    s.graduation_year,
    s.placement_status,
    COALESCE(skill_summary.skills, '') AS skills,
    COUNT(DISTINCT a.application_id) AS application_count,
    COUNT(DISTINCT sch.schedule_id) AS interview_count,
    ROUND(AVG(sgpa.sgpa), 2) AS academic_average_sgpa
FROM students s
JOIN departments d ON d.department_id = s.department_id
LEFT JOIN skill_summary ON skill_summary.student_id = s.student_id
LEFT JOIN applications a ON a.student_id = s.student_id
LEFT JOIN interview_schedules sch ON sch.student_id = s.student_id
LEFT JOIN sgpa ON sgpa.student_id = s.student_id
GROUP BY
    s.student_id,
    s.roll_no,
    s.full_name,
    s.email,
    s.phone_number,
    d.code,
    d.name,
    s.cgpa,
    s.backlogs,
    s.graduation_year,
    s.placement_status,
    skill_summary.skills;

CREATE OR REPLACE VIEW v_student_schedule AS
SELECT
    s.roll_no,
    s.full_name,
    c.name AS company_name,
    i.round_no,
    lower(i.slot_range) AS starts_at,
    upper(i.slot_range) AS ends_at,
    i.venue,
    sch.status
FROM interview_schedules sch
JOIN students s ON s.student_id = sch.student_id
JOIN companies c ON c.company_id = sch.company_id
JOIN interview_slots i ON i.slot_id = sch.slot_id;

CREATE OR REPLACE VIEW v_company_dashboard AS
SELECT
    c.company_id,
    c.name,
    c.openings,
    c.package_lpa,
    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT sch.schedule_id) AS scheduled_interviews,
    COUNT(DISTINCT o.offer_id) FILTER (WHERE o.status = 'ACCEPTED') AS accepted_offers
FROM companies c
LEFT JOIN applications a ON a.company_id = c.company_id
LEFT JOIN interview_schedules sch ON sch.company_id = c.company_id
LEFT JOIN offers o ON o.company_id = c.company_id
GROUP BY c.company_id, c.name, c.openings, c.package_lpa;

CREATE OR REPLACE VIEW v_matching_edges AS
SELECT
    e.student_id,
    sl.slot_id,
    e.company_id,
    e.match_score
FROM v_eligible_students e
JOIN applications a
    ON a.student_id = e.student_id
   AND a.company_id = e.company_id
   AND a.status IN ('APPLIED', 'SHORTLISTED')
JOIN interview_slots sl
    ON sl.company_id = e.company_id
   AND sl.booked_count < sl.capacity
WHERE NOT EXISTS (
    SELECT 1
    FROM interview_schedules existing
    JOIN interview_slots existing_slot ON existing_slot.slot_id = existing.slot_id
    WHERE existing.student_id = e.student_id
      AND existing.status = 'SCHEDULED'
      AND existing_slot.slot_range && sl.slot_range
);

CREATE OR REPLACE FUNCTION assert_application_eligible()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM v_eligible_students
        WHERE student_id = NEW.student_id
          AND company_id = NEW.company_id
    ) THEN
        RAISE EXCEPTION 'Student % is not eligible for company %', NEW.student_id, NEW.company_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_application_eligible
BEFORE INSERT OR UPDATE OF student_id, company_id
ON applications
FOR EACH ROW
EXECUTE FUNCTION assert_application_eligible();

CREATE OR REPLACE FUNCTION assert_no_student_overlap()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    new_range TSTZRANGE;
BEGIN
    SELECT slot_range INTO new_range
    FROM interview_slots
    WHERE slot_id = NEW.slot_id;

    IF EXISTS (
        SELECT 1
        FROM interview_schedules sch
        JOIN interview_slots sl ON sl.slot_id = sch.slot_id
        WHERE sch.student_id = NEW.student_id
          AND sch.status = 'SCHEDULED'
          AND sch.schedule_id <> COALESCE(NEW.schedule_id, -1)
          AND sl.slot_range && new_range
    ) THEN
        RAISE EXCEPTION 'Student % already has an overlapping interview', NEW.student_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_no_student_overlap
BEFORE INSERT OR UPDATE OF student_id, slot_id, status
ON interview_schedules
FOR EACH ROW
WHEN (NEW.status = 'SCHEDULED')
EXECUTE FUNCTION assert_no_student_overlap();

CREATE OR REPLACE FUNCTION sync_offer_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'ACCEPTED' THEN
        UPDATE students
        SET placement_status = 'PLACED'
        WHERE student_id = NEW.student_id;

        UPDATE applications
        SET status = 'SELECTED'
        WHERE student_id = NEW.student_id
          AND company_id = NEW.company_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_offer_status
AFTER INSERT OR UPDATE OF status
ON offers
FOR EACH ROW
EXECUTE FUNCTION sync_offer_status();

CREATE OR REPLACE FUNCTION book_interview(
    p_student_id BIGINT,
    p_company_id BIGINT,
    p_slot_id BIGINT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_application_id BIGINT;
    v_schedule_id BIGINT;
    v_slot interview_slots%ROWTYPE;
BEGIN
    SELECT *
    INTO v_slot
    FROM interview_slots
    WHERE slot_id = p_slot_id
      AND company_id = p_company_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Slot % does not exist for company %', p_slot_id, p_company_id;
    END IF;

    IF v_slot.booked_count >= v_slot.capacity THEN
        RAISE EXCEPTION 'Slot % is full', p_slot_id;
    END IF;

    PERFORM 1
    FROM students
    WHERE student_id = p_student_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id;
    END IF;

    SELECT application_id
    INTO v_application_id
    FROM applications
    WHERE student_id = p_student_id
      AND company_id = p_company_id
      AND status IN ('APPLIED', 'SHORTLISTED')
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active application for student % and company %', p_student_id, p_company_id;
    END IF;

    INSERT INTO interview_schedules(application_id, student_id, company_id, slot_id)
    VALUES (v_application_id, p_student_id, p_company_id, p_slot_id)
    RETURNING schedule_id INTO v_schedule_id;

    UPDATE interview_slots
    SET booked_count = booked_count + 1
    WHERE slot_id = p_slot_id;

    UPDATE applications
    SET status = 'SCHEDULED'
    WHERE application_id = v_application_id;

    RETURN v_schedule_id;
END;
$$;

CREATE OR REPLACE FUNCTION schedule_company_greedy(p_company_id BIGINT)
RETURNS TABLE(schedule_id BIGINT, student_id BIGINT, slot_id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    candidate RECORD;
    chosen_slot_id BIGINT;
    created_schedule_id BIGINT;
BEGIN
    FOR candidate IN
        SELECT
            a.student_id,
            e.match_score,
            e.cgpa,
            e.backlogs,
            a.applied_at
        FROM applications a
        JOIN v_eligible_students e
            ON e.student_id = a.student_id
           AND e.company_id = a.company_id
        WHERE a.company_id = p_company_id
          AND a.status IN ('APPLIED', 'SHORTLISTED')
        ORDER BY e.match_score DESC, e.cgpa DESC, e.backlogs ASC, a.applied_at ASC
    LOOP
        SELECT sl.slot_id
        INTO chosen_slot_id
        FROM interview_slots sl
        WHERE sl.company_id = p_company_id
          AND sl.booked_count < sl.capacity
          AND NOT EXISTS (
              SELECT 1
              FROM interview_schedules existing
              JOIN interview_slots existing_slot ON existing_slot.slot_id = existing.slot_id
              WHERE existing.student_id = candidate.student_id
                AND existing.status = 'SCHEDULED'
                AND existing_slot.slot_range && sl.slot_range
          )
        ORDER BY lower(sl.slot_range), sl.slot_id
        LIMIT 1;

        IF chosen_slot_id IS NOT NULL THEN
            created_schedule_id := book_interview(candidate.student_id, p_company_id, chosen_slot_id);
            schedule_id := created_schedule_id;
            student_id := candidate.student_id;
            slot_id := chosen_slot_id;
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$;
