INSERT INTO departments(code, name) VALUES
('CSE', 'Computer Science and Engineering'),
('CST', 'Computer Science and Technology'),
('ECE', 'Electronics and Communication Engineering'),
('AIML', 'Artificial Intelligence and Machine Learning'),
('CSE-IOT', 'Computer Science and Engineering - Internet of Things'),
('CSE-CS', 'Computer Science and Engineering - Cyber Security'),
('CSE-BT', 'Computer Science and Engineering - Blockchain Technology'),
('IT', 'Information Technology'),
('DS', 'Data Science'),
('EE', 'Electrical Engineering'),
('ME', 'Mechanical Engineering'),
('CE', 'Civil Engineering'),
('BCA', 'Bachelor of Computer Applications'),
('MCA', 'Master of Computer Applications')
ON CONFLICT (code) DO NOTHING;

INSERT INTO skills(name) VALUES
('SQL'),
('PostgreSQL'),
('Java'),
('Python'),
('C++'),
('Data Structures'),
('Algorithms'),
('Operating Systems'),
('Computer Networks'),
('DBMS'),
('HTML'),
('CSS'),
('JavaScript'),
('Flask'),
('React'),
('Machine Learning'),
('Deep Learning'),
('Cloud Computing'),
('Cyber Security'),
('IoT'),
('Blockchain'),
('Communication'),
('Aptitude'),
('System Design'),
('DevOps')
ON CONFLICT (name) DO NOTHING;

WITH first_names(name) AS (
    VALUES
    ('Abir'), ('Anirban'), ('Arindam'), ('Aritra'), ('Arnab'), ('Arpita'), ('Ankita'), ('Antara'),
    ('Bishal'), ('Bidisha'), ('Debanjan'), ('Debolina'), ('Debarghya'), ('Debasmita'), ('Dipayan'), ('Doyel'),
    ('Ishani'), ('Indranil'), ('Joydeep'), ('Jhilik'), ('Kaushik'), ('Koyel'), ('Madhurima'), ('Mainak'),
    ('Moumita'), ('Nilanjan'), ('Nandita'), ('Oindrila'), ('Partha'), ('Payel'), ('Prantik'), ('Pritam'),
    ('Ritwik'), ('Riya'), ('Rupam'), ('Sagnik'), ('Saheli'), ('Sanchari'), ('Sayak'), ('Shreya'),
    ('Sohini'), ('Soumyadeep'), ('Subhajit'), ('Sudipta'), ('Sukanya'), ('Tanmoy'), ('Trisha'), ('Utsav'),
    ('Anwesha'), ('Sayan'), ('Riddhi'), ('Suchismita'), ('Priyanka'), ('Sourav'), ('Bhaswati'), ('Raktim')
),
last_names(name) AS (
    VALUES
    ('Banerjee'), ('Basu'), ('Bera'), ('Bhattacharya'), ('Biswas'), ('Bose'), ('Chakraborty'), ('Chatterjee'),
    ('Das'), ('Dasgupta'), ('Datta'), ('De'), ('Dey'), ('Dhar'), ('Ganguly'), ('Ghosh'),
    ('Ghoshal'), ('Guha'), ('Halder'), ('Karmakar'), ('Lahiri'), ('Majumdar'), ('Mandal'), ('Mitra'),
    ('Mukherjee'), ('Nandi'), ('Pal'), ('Paul'), ('Pramanik'), ('Ray'), ('Roy'), ('Saha'),
    ('Sanyal'), ('Sarkar'), ('Sen'), ('Sengupta'), ('Sil'), ('Sinha'), ('Adhikari'), ('Mahato'),
    ('Murmu'), ('Hansda'), ('Tudu'), ('Kisku'), ('Nayak'), ('Panda'), ('Pradhan'), ('Mohanty'),
    ('Borah'), ('Gogoi'), ('Saikia'), ('Barua'), ('Hazarika'), ('Deka'), ('Kalita'), ('Barman')
),
dept_cycle AS (
    SELECT ARRAY[
        'CSE', 'CST', 'ECE', 'AIML', 'CSE-IOT', 'CSE-CS', 'CSE-BT',
        'IT', 'DS', 'EE', 'ME', 'CE', 'BCA', 'MCA'
    ] AS codes
),
generated AS (
    SELECT
        gs AS n,
        (SELECT name FROM first_names OFFSET ((gs - 1) % 20) LIMIT 1) AS first_name,
        (SELECT name FROM last_names OFFSET (((gs - 1) / 20) % 20) LIMIT 1) AS last_name,
        codes[((gs - 1) % array_length(codes, 1)) + 1] AS dept_code,
        ROUND((6.5 + ((gs * 37) % 31) / 10.0)::numeric, 2) AS cgpa,
        CASE
            WHEN gs % 17 = 0 THEN 2
            WHEN gs % 11 = 0 THEN 1
            ELSE 0
        END AS backlogs
    FROM generate_series(1, 1500) gs
    CROSS JOIN dept_cycle
)
INSERT INTO students(roll_no, full_name, email, phone_number, department_id, cgpa, backlogs, graduation_year)
SELECT
    dept_code || LPAD(n::text, 4, '0') AS roll_no,
    first_name || ' ' || last_name || ' ' || LPAD(n::text, 4, '0') AS full_name,
    lower(
        CASE n % 5
            WHEN 0 THEN first_name || '.' || last_name || RIGHT((20270000 + n)::text, 4) || '@iem.edu.in'
            WHEN 1 THEN first_name || last_name || '.' || dept_code || RIGHT((20270000 + n)::text, 4) || '@uem.edu.in'
            WHEN 2 THEN first_name || '.' || RIGHT((20270000 + n)::text, 4) || '@student.iem.edu.in'
            WHEN 3 THEN last_name || '.' || first_name || RIGHT((20270000 + n)::text, 4) || '@campusmail.edu.in'
            ELSE first_name || '_' || last_name || RIGHT((20270000 + n)::text, 4) || '@placement.edu.in'
        END
    ) AS email,
    '+91 ' ||
    CASE n % 8
        WHEN 0 THEN '98'
        WHEN 1 THEN '97'
        WHEN 2 THEN '96'
        WHEN 3 THEN '91'
        WHEN 4 THEN '90'
        WHEN 5 THEN '89'
        WHEN 6 THEN '86'
        ELSE '83'
    END ||
    SUBSTRING(LPAD(((n * 7919 + 234567) % 100000000)::text, 8, '0') FROM 1 FOR 4) ||
    ' ' ||
    SUBSTRING(LPAD(((n * 7919 + 234567) % 100000000)::text, 8, '0') FROM 5 FOR 4) AS phone_number,
    d.department_id,
    LEAST(cgpa, 9.50),
    backlogs,
    2027
FROM generated g
JOIN departments d ON d.code = g.dept_code
ON CONFLICT (roll_no) DO NOTHING;

WITH skill_plan AS (
    SELECT s.student_id, s.roll_no, d.code AS dept_code
    FROM students s
    JOIN departments d ON d.department_id = s.department_id
),
assigned AS (
    SELECT student_id, skill_name, proficiency
    FROM skill_plan
    CROSS JOIN LATERAL (
        VALUES
        ('Communication', 3 + (student_id % 3)::int),
        ('Aptitude', 3 + (student_id % 3)::int),
        ('SQL', 2 + (student_id % 4)::int),
        ('DBMS', 2 + (student_id % 4)::int),
        ('Python', CASE WHEN dept_code IN ('AIML', 'DS', 'CSE', 'CST', 'IT', 'MCA') THEN 4 ELSE 2 END),
        ('Java', CASE WHEN dept_code IN ('CSE', 'CST', 'IT', 'MCA', 'BCA') THEN 4 ELSE 2 END),
        ('Data Structures', CASE WHEN dept_code IN ('CSE', 'CST', 'IT', 'AIML', 'DS', 'MCA', 'BCA') THEN 4 ELSE 2 END),
        ('Algorithms', CASE WHEN dept_code IN ('CSE', 'CST', 'IT', 'AIML', 'DS', 'MCA') THEN 4 ELSE 2 END),
        ('Machine Learning', CASE WHEN dept_code IN ('AIML', 'DS') THEN 4 ELSE 1 END),
        ('Cyber Security', CASE WHEN dept_code = 'CSE-CS' THEN 5 ELSE 1 END),
        ('IoT', CASE WHEN dept_code = 'CSE-IOT' THEN 5 ELSE 1 END),
        ('Blockchain', CASE WHEN dept_code = 'CSE-BT' THEN 5 ELSE 1 END),
        ('Cloud Computing', CASE WHEN student_id % 5 IN (0, 1, 2) THEN 4 ELSE 2 END),
        ('JavaScript', CASE WHEN dept_code IN ('CSE', 'CST', 'IT', 'MCA', 'BCA') THEN 4 ELSE 2 END)
    ) AS x(skill_name, proficiency)
)
INSERT INTO student_skills(student_id, skill_id, proficiency)
SELECT a.student_id, sk.skill_id, LEAST(a.proficiency, 5)
FROM assigned a
JOIN skills sk ON sk.name = a.skill_name
ON CONFLICT (student_id, skill_id) DO UPDATE SET proficiency = EXCLUDED.proficiency;

WITH dept_subject_templates AS (
    SELECT
        d.department_id,
        d.code AS dept_code,
        sem.semester_no,
        sub.position_no,
        CASE
            WHEN sem.semester_no <= 2 THEN sub.foundation_name
            WHEN d.code IN ('CSE', 'CST', 'IT', 'MCA', 'BCA') THEN sub.cs_name
            WHEN d.code = 'AIML' THEN sub.aiml_name
            WHEN d.code = 'CSE-IOT' THEN sub.iot_name
            WHEN d.code = 'CSE-CS' THEN sub.cyber_name
            WHEN d.code = 'CSE-BT' THEN sub.blockchain_name
            WHEN d.code = 'DS' THEN sub.ds_name
            WHEN d.code = 'ECE' THEN sub.ece_name
            ELSE sub.general_name
        END AS subject_name
    FROM departments d
    CROSS JOIN generate_series(1, 8) sem(semester_no)
    CROSS JOIN (
        VALUES
        (1, 'Engineering Mathematics', 'Data Structures', 'Machine Learning', 'IoT Architecture', 'Network Security', 'Blockchain Fundamentals', 'Statistics for Data Science', 'Digital Electronics', 'Engineering Mechanics'),
        (2, 'Engineering Physics', 'Database Management Systems', 'Deep Learning', 'Embedded Systems', 'Cryptography', 'Smart Contracts', 'Data Mining', 'Signals and Systems', 'Thermodynamics'),
        (3, 'Programming in C', 'Operating Systems', 'Python for AI', 'Sensor Networks', 'Ethical Hacking', 'Distributed Ledger Systems', 'Big Data Analytics', 'Analog Communication', 'Manufacturing Processes'),
        (4, 'Basic Electrical Engineering', 'Computer Networks', 'Natural Language Processing', 'Wireless Sensor Networks', 'Digital Forensics', 'Web3 Application Development', 'Data Visualization', 'Microprocessors', 'Control Systems'),
        (5, 'Environmental Science', 'Software Engineering', 'Computer Vision', 'Cloud IoT Platforms', 'Secure Software Engineering', 'Blockchain Security', 'Predictive Analytics', 'VLSI Design', 'Industrial Management')
    ) AS sub(position_no, foundation_name, cs_name, aiml_name, iot_name, cyber_name, blockchain_name, ds_name, ece_name, general_name)
)
INSERT INTO subjects(department_id, semester_no, subject_code, subject_name, credits)
SELECT
    department_id,
    semester_no,
    dept_code || '-S' || semester_no || LPAD(position_no::text, 2, '0') AS subject_code,
    subject_name,
    CASE WHEN position_no = 5 THEN 2 ELSE 4 END AS credits
FROM dept_subject_templates
ON CONFLICT (department_id, semester_no, subject_code) DO NOTHING;

INSERT INTO student_semester_marks(student_id, subject_id, internal_marks, external_marks, grade, exam_status)
SELECT
    s.student_id,
    sub.subject_id,
    18 + ((s.student_id + sub.subject_id + sub.semester_no) % 13) AS internal_marks,
    32 + ((s.student_id * 3 + sub.subject_id * 5 + sub.semester_no) % 39) AS external_marks,
    CASE
        WHEN 18 + ((s.student_id + sub.subject_id + sub.semester_no) % 13)
           + 32 + ((s.student_id * 3 + sub.subject_id * 5 + sub.semester_no) % 39) >= 90 THEN 'O'
        WHEN 18 + ((s.student_id + sub.subject_id + sub.semester_no) % 13)
           + 32 + ((s.student_id * 3 + sub.subject_id * 5 + sub.semester_no) % 39) >= 80 THEN 'A+'
        WHEN 18 + ((s.student_id + sub.subject_id + sub.semester_no) % 13)
           + 32 + ((s.student_id * 3 + sub.subject_id * 5 + sub.semester_no) % 39) >= 70 THEN 'A'
        WHEN 18 + ((s.student_id + sub.subject_id + sub.semester_no) % 13)
           + 32 + ((s.student_id * 3 + sub.subject_id * 5 + sub.semester_no) % 39) >= 60 THEN 'B+'
        WHEN 18 + ((s.student_id + sub.subject_id + sub.semester_no) % 13)
           + 32 + ((s.student_id * 3 + sub.subject_id * 5 + sub.semester_no) % 39) >= 50 THEN 'B'
        ELSE 'C'
    END AS grade,
    CASE
        WHEN (s.student_id + sub.subject_id) % 97 = 0 THEN 'BACKLOG'
        ELSE 'PASS'
    END AS exam_status
FROM students s
JOIN subjects sub ON sub.department_id = s.department_id
ON CONFLICT (student_id, subject_id) DO NOTHING;

INSERT INTO companies(name, package_lpa, openings, min_cgpa, max_backlogs) VALUES
('TCS', 3.60, 120, 6.00, 2),
('Capgemini', 4.25, 90, 6.50, 1),
('Accenture', 4.50, 100, 6.50, 1),
('Wipro', 3.80, 80, 6.00, 2),
('LTIMindtree', 6.50, 55, 7.00, 1),
('Infosys', 3.60, 110, 6.00, 1),
('Hyland', 8.00, 25, 7.50, 0),
('Lexmark', 7.50, 20, 7.20, 1),
('JPMorgan Chase', 18.00, 18, 8.20, 0),
('IBM', 7.00, 45, 7.00, 1),
('Atlassian', 28.00, 8, 8.80, 0),
('Amazon', 32.00, 10, 8.50, 0),
('Microsoft', 45.00, 6, 9.00, 0),
('TechNova Labs', 18.50, 12, 8.00, 1),
('DataOrbit Analytics', 14.00, 15, 7.50, 0),
('CoreBridge Systems', 9.50, 35, 7.00, 2)
ON CONFLICT (name) DO UPDATE SET
    package_lpa = EXCLUDED.package_lpa,
    openings = EXCLUDED.openings,
    min_cgpa = EXCLUDED.min_cgpa,
    max_backlogs = EXCLUDED.max_backlogs;

INSERT INTO company_departments(company_id, department_id)
SELECT c.company_id, d.department_id
FROM companies c
JOIN departments d ON
    CASE
        WHEN c.name IN ('TCS', 'Capgemini', 'Accenture', 'Wipro', 'Infosys', 'IBM') THEN d.code IN ('CSE', 'CST', 'ECE', 'AIML', 'CSE-IOT', 'CSE-CS', 'CSE-BT', 'IT', 'DS', 'BCA', 'MCA', 'EE')
        WHEN c.name IN ('LTIMindtree', 'Hyland', 'Lexmark', 'TechNova Labs') THEN d.code IN ('CSE', 'CST', 'AIML', 'CSE-IOT', 'CSE-CS', 'CSE-BT', 'IT', 'DS', 'MCA')
        WHEN c.name IN ('JPMorgan Chase', 'Atlassian', 'Amazon', 'Microsoft', 'DataOrbit Analytics') THEN d.code IN ('CSE', 'CST', 'AIML', 'CSE-CS', 'IT', 'DS', 'MCA')
        ELSE d.code IN ('CSE', 'CST', 'ECE', 'AIML', 'IT', 'DS', 'EE', 'ME')
    END
ON CONFLICT (company_id, department_id) DO NOTHING;

INSERT INTO company_required_skills(company_id, skill_id, min_proficiency, weight)
SELECT c.company_id, sk.skill_id, x.min_proficiency, x.weight
FROM (
    VALUES
    ('TCS', 'Aptitude', 3, 2), ('TCS', 'Communication', 3, 2), ('TCS', 'SQL', 2, 1),
    ('Capgemini', 'Java', 3, 2), ('Capgemini', 'SQL', 3, 1), ('Capgemini', 'Communication', 3, 1),
    ('Accenture', 'Java', 3, 2), ('Accenture', 'Python', 3, 2), ('Accenture', 'Aptitude', 3, 1),
    ('Wipro', 'Aptitude', 3, 2), ('Wipro', 'Communication', 3, 1), ('Wipro', 'Java', 2, 1),
    ('LTIMindtree', 'Java', 3, 2), ('LTIMindtree', 'Data Structures', 3, 2), ('LTIMindtree', 'SQL', 3, 1),
    ('Infosys', 'Aptitude', 3, 2), ('Infosys', 'Python', 2, 1), ('Infosys', 'Communication', 3, 1),
    ('Hyland', 'Java', 4, 3), ('Hyland', 'Data Structures', 4, 2), ('Hyland', 'DBMS', 3, 1),
    ('Lexmark', 'C++', 2, 1), ('Lexmark', 'Computer Networks', 2, 1), ('Lexmark', 'SQL', 3, 1),
    ('JPMorgan Chase', 'Java', 4, 3), ('JPMorgan Chase', 'Data Structures', 4, 3), ('JPMorgan Chase', 'DBMS', 4, 2),
    ('IBM', 'Cloud Computing', 3, 2), ('IBM', 'Python', 3, 2), ('IBM', 'SQL', 3, 1),
    ('Atlassian', 'Java', 4, 3), ('Atlassian', 'System Design', 2, 2), ('Atlassian', 'Algorithms', 4, 3),
    ('Amazon', 'Data Structures', 4, 3), ('Amazon', 'Algorithms', 4, 3), ('Amazon', 'System Design', 2, 2),
    ('Microsoft', 'Data Structures', 4, 3), ('Microsoft', 'Algorithms', 4, 3), ('Microsoft', 'DBMS', 4, 2),
    ('TechNova Labs', 'SQL', 4, 2), ('TechNova Labs', 'Algorithms', 4, 3),
    ('DataOrbit Analytics', 'Python', 3, 2), ('DataOrbit Analytics', 'Machine Learning', 3, 3),
    ('CoreBridge Systems', 'Communication', 3, 1)
) AS x(company_name, skill_name, min_proficiency, weight)
JOIN companies c ON c.name = x.company_name
JOIN skills sk ON sk.name = x.skill_name
ON CONFLICT (company_id, skill_id) DO UPDATE SET
    min_proficiency = EXCLUDED.min_proficiency,
    weight = EXCLUDED.weight;

INSERT INTO applications(student_id, company_id)
SELECT student_id, company_id
FROM v_eligible_students
WHERE match_score >= 65
ON CONFLICT (student_id, company_id) DO NOTHING;

INSERT INTO interview_slots(company_id, round_no, slot_range, capacity, venue)
SELECT
    c.company_id,
    1,
    tstzrange(
        ('2026-08-01 09:00+05:30'::timestamptz + ((row_number() OVER (ORDER BY c.package_lpa DESC, c.name) - 1) * interval '1 hour')),
        ('2026-08-01 09:45+05:30'::timestamptz + ((row_number() OVER (ORDER BY c.package_lpa DESC, c.name) - 1) * interval '1 hour')),
        '[)'
    ),
    LEAST(GREATEST(c.openings / 4, 5), 30),
    'Panel Room ' || row_number() OVER (ORDER BY c.package_lpa DESC, c.name)
FROM companies c
ON CONFLICT DO NOTHING;

INSERT INTO interview_slots(company_id, round_no, slot_range, capacity, venue)
SELECT
    c.company_id,
    1,
    tstzrange(
        ('2026-08-03 09:00+05:30'::timestamptz + ((row_number() OVER (ORDER BY c.name) - 1) * interval '1 hour')),
        ('2026-08-03 09:45+05:30'::timestamptz + ((row_number() OVER (ORDER BY c.name) - 1) * interval '1 hour')),
        '[)'
    ),
    LEAST(GREATEST(c.openings / 4, 5), 30),
    'Lab ' || row_number() OVER (ORDER BY c.name)
FROM companies c
ON CONFLICT DO NOTHING;

WITH ranked_edges AS (
    SELECT
        a.application_id,
        e.student_id,
        e.company_id,
        e.slot_id,
        e.match_score,
        c.package_lpa,
        s.cgpa,
        ROW_NUMBER() OVER (
            PARTITION BY e.slot_id
            ORDER BY e.match_score DESC, s.cgpa DESC, e.student_id
        ) AS slot_rank,
        sl.capacity
    FROM v_matching_edges e
    JOIN applications a
        ON a.student_id = e.student_id
       AND a.company_id = e.company_id
    JOIN students s ON s.student_id = e.student_id
    JOIN companies c ON c.company_id = e.company_id
    JOIN interview_slots sl ON sl.slot_id = e.slot_id
),
valid_edges AS (
    SELECT *
    FROM ranked_edges
    WHERE slot_rank <= capacity
),
selected AS (
    SELECT DISTINCT ON (application_id)
        application_id,
        student_id,
        company_id,
        slot_id,
        match_score,
        package_lpa,
        cgpa
    FROM valid_edges
    ORDER BY application_id, match_score DESC, package_lpa DESC, slot_id
),
limited AS (
    SELECT application_id, student_id, company_id, slot_id
    FROM selected
    ORDER BY match_score DESC, package_lpa DESC, cgpa DESC, student_id
    LIMIT 180
),
inserted AS (
    INSERT INTO interview_schedules(application_id, student_id, company_id, slot_id)
    SELECT application_id, student_id, company_id, slot_id
    FROM limited
    RETURNING application_id, slot_id
),
slot_counts AS (
    SELECT slot_id, COUNT(*) AS added_count
    FROM inserted
    GROUP BY slot_id
),
updated_slots AS (
    UPDATE interview_slots sl
    SET booked_count = sc.added_count
    FROM slot_counts sc
    WHERE sl.slot_id = sc.slot_id
    RETURNING sl.slot_id
)
UPDATE applications a
SET status = 'SCHEDULED'
FROM inserted i
WHERE a.application_id = i.application_id;
