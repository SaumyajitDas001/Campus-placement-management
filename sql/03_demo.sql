SELECT 'Eligible Students' AS section;
SELECT company_name, roll_no, full_name, cgpa, backlogs, match_score
FROM v_eligible_students
ORDER BY company_name, match_score DESC;

SELECT 'Greedy Scheduling: TechNova Labs' AS section;
SELECT *
FROM schedule_company_greedy(
    (SELECT company_id FROM companies WHERE name = 'TechNova Labs')
);

SELECT 'Student Schedule' AS section;
SELECT *
FROM v_student_schedule
ORDER BY starts_at, roll_no;

SELECT 'Company Dashboard' AS section;
SELECT *
FROM v_company_dashboard
ORDER BY package_lpa DESC;

SELECT 'Bipartite Matching Edges' AS section;
SELECT *
FROM v_matching_edges
ORDER BY company_id, match_score DESC, slot_id;

