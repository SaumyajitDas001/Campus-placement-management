# Advanced Campus Placement Management System - PostgreSQL

This project implements an advanced campus placement database in PostgreSQL.
It is designed for large placement drives with eligibility filtering, interview
slot scheduling, conflict prevention, transactions, triggers, views, and
algorithmic allocation logic.

## Screenshots

### Dashboard

![Dashboard top](docs/screenshots/dashboard-top.png)

### Tables and Scheduling

![Dashboard tables](docs/screenshots/dashboard-tables.png)

### Student Academic Profile

![Student profile modal](docs/screenshots/student-profile.png)

### Semester and Subject Marks

![Student marks modal](docs/screenshots/student-marks.png)

## Features

- 10,000+ student-ready normalized schema
- Company eligibility rules by CGPA, department, skills, and backlogs
- Student applications with trigger-based eligibility validation
- Interview slots with capacity tracking
- Conflict-free interview scheduling using PostgreSQL range types
- Greedy scheduling function using ranking and priority ordering
- Maximum matching input view for implementing bipartite matching externally
- Views for eligible students, schedules, company stats, and placement results
- Transaction-safe booking function with row locks
- Deadlock-aware locking order

## Requirements

- PostgreSQL 14 or newer
- `psql`
- Python 3.10 or newer
- Flask

## Setup

Using Docker:

```bash
docker compose up -d
docker exec -i campus-placement-postgres psql -U campus_admin -d campus_placement < sql/01_schema.sql
docker exec -i campus-placement-postgres psql -U campus_admin -d campus_placement < sql/02_seed.sql
docker exec -i campus-placement-postgres psql -U campus_admin -d campus_placement < sql/03_demo.sql
```

Open the frontend:

```text
http://localhost:5000
```

Using a local PostgreSQL installation:

Create a database:

```bash
createdb campus_placement
```

Run the schema and seed data:

```bash
psql -d campus_placement -f sql/01_schema.sql
psql -d campus_placement -f sql/02_seed.sql
psql -d campus_placement -f sql/03_demo.sql
```

Start the Flask frontend locally:

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
set DATABASE_URL=postgresql://postgres:Saumyajit%%402004@localhost:5433/campus_placement
flask --app app run
```

Then open:

```text
http://localhost:5000
```

## Useful Queries

Eligible students for all companies:

```sql
SELECT * FROM v_eligible_students ORDER BY company_name, match_score DESC;
```

Student schedule:

```sql
SELECT * FROM v_student_schedule WHERE roll_no = 'CSE001';
```

Company dashboard:

```sql
SELECT * FROM v_company_dashboard;
```

Run greedy scheduling for a company:

```sql
SELECT schedule_company_greedy(1);
```

Book a specific interview transactionally:

```sql
SELECT book_interview(1, 1, 1);
```

## Algorithm Mapping

- **Sorting**: eligibility ranking by CGPA, skill match, backlogs, and application time.
- **Greedy**: `schedule_company_greedy(company_id)` assigns best-ranked students to earliest valid slots.
- **Priority Queue**: implemented with `ORDER BY match_score DESC, cgpa DESC, applied_at ASC`.
- **Interval Scheduling**: PostgreSQL `tstzrange` and exclusion constraints prevent overlapping interviews.
- **Segment Tree Equivalent**: GiST indexes on time ranges support efficient overlap queries.
- **Maximum Bipartite Matching**: `v_matching_edges` exposes student-slot edges. Use it as input for Hopcroft-Karp in an application layer.
- **Transactions**: `book_interview` locks slot, student, and application rows in a fixed order.
- **Deadlock Handling**: fixed lock order and retry-safe function design.

## Folder Structure

```text
sql/
  01_schema.sql
  02_seed.sql
  03_demo.sql
app.py
templates/
  index.html
static/
  styles.css
  app.js
```
