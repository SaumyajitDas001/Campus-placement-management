const state = {
  companies: [],
};

const money = new Intl.NumberFormat("en-IN", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

function updateClock() {
  const now = new Date();
  document.getElementById("clockText").textContent = now.toLocaleTimeString("en-IN", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: true,
  });
}

function cell(value, className = "") {
  const td = document.createElement("td");
  td.textContent = value ?? "";
  if (className) td.className = className;
  return td;
}

function renderRows(targetId, rows, renderer, emptyText = "No records found") {
  const tbody = document.getElementById(targetId);
  if (!tbody) return;

  tbody.innerHTML = "";

  if (!rows.length) {
    const tr = document.createElement("tr");
    const td = cell(emptyText, "empty");
    td.colSpan = 10;
    tr.appendChild(td);
    tbody.appendChild(tr);
    return;
  }

  rows.forEach((row) => tbody.appendChild(renderer(row)));
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  const contentType = response.headers.get("content-type") || "";
  const data = contentType.includes("application/json")
    ? await response.json()
    : { error: await response.text() };
  if (!response.ok) {
    throw new Error(data.detail || data.error || "Request failed");
  }
  return data;
}

function formatDate(value) {
  if (!value) return "";
  return new Date(value).toLocaleString("en-IN", {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

async function loadSummary() {
  const summary = await api("/api/summary");
  const cards = [
    ["Students", summary.students],
    ["Companies", summary.companies],
    ["Applications", summary.applications],
    ["Scheduled Interviews", summary.scheduled],
  ];

  const container = document.getElementById("summaryCards");
  container.innerHTML = "";
  cards.forEach(([label, value]) => {
    const card = document.createElement("article");
    card.className = "metric";
    card.innerHTML = `<span>${label}</span><strong>${value}</strong>`;
    container.appendChild(card);
  });
}

async function loadCompanies() {
  state.companies = await api("/api/companies");
  const select = document.getElementById("companySelect");
  select.innerHTML = "";

  state.companies.forEach((company) => {
    const option = document.createElement("option");
    option.value = company.company_id;
    option.textContent = `${company.name} (${company.package_lpa} LPA)`;
    select.appendChild(option);
  });
}

async function loadDashboard() {
  const rows = await api("/api/dashboard");
  renderRows("dashboardRows", rows, (row) => {
    const tr = document.createElement("tr");
    tr.append(
      cell(row.name),
      cell(`${money.format(row.package_lpa)} LPA`, "numeric"),
      cell(row.openings, "numeric"),
      cell(row.applications, "numeric"),
      cell(row.scheduled_interviews, "numeric"),
      cell(row.accepted_offers, "numeric")
    );
    return tr;
  });
}

async function loadStudents() {
  const query = encodeURIComponent(document.getElementById("studentSearch").value.trim());
  const rows = await api(`/api/students?q=${query}`);
  renderRows("studentRows", rows, (row) => {
    const tr = document.createElement("tr");
    tr.className = "clickable";
    tr.title = "Click to view semester-wise marks";
    tr.append(
      cell(row.roll_no),
      cell(row.full_name),
      cell(row.email),
      cell(row.phone_number),
      cell(row.department_code),
      cell(row.cgpa, "numeric"),
      cell(row.backlogs, "numeric"),
      cell(row.graduation_year, "numeric"),
      cell(row.placement_status),
      cell(row.application_count, "numeric"),
      cell(row.interview_count, "numeric"),
      cell(row.academic_average_sgpa ?? "", "numeric")
    );
    tr.addEventListener("click", () => openStudentDetails(row.student_id));
    return tr;
  });
}

function renderProfileStrip(profile) {
  const items = [
    ["Roll No", profile.roll_no],
    ["Department", `${profile.department_code} - ${profile.department_name}`],
    ["CGPA", profile.cgpa],
    ["Email", profile.email],
    ["Phone", profile.phone_number],
    ["Backlogs", profile.backlogs],
    ["Graduation Year", profile.graduation_year],
    ["Placement Status", profile.placement_status],
    ["Applications", profile.application_count],
    ["Interviews", profile.interview_count],
  ];

  const strip = document.getElementById("modalProfileStrip");
  strip.innerHTML = "";
  items.forEach(([label, value]) => {
    const div = document.createElement("div");
    div.className = "profile-pill";
    div.innerHTML = `<strong>${label}</strong>${value ?? ""}`;
    strip.appendChild(div);
  });
}

async function openStudentDetails(studentId) {
  const details = await api(`/api/students/${studentId}/marks`);
  const { profile, semesters, marks } = details;

  document.getElementById("modalStudentName").textContent = profile.full_name;
  document.getElementById("modalStudentMeta").textContent = `${profile.roll_no} | ${profile.department_name} | Skills: ${profile.skills}`;
  renderProfileStrip(profile);

  renderRows("semesterRows", semesters, (row) => {
    const tr = document.createElement("tr");
    tr.append(
      cell(row.semester_no, "numeric"),
      cell(row.average_marks, "numeric"),
      cell(row.sgpa, "numeric"),
      cell(row.backlogs, "numeric")
    );
    return tr;
  });

  renderRows("markRows", marks, (row) => {
    const tr = document.createElement("tr");
    tr.append(
      cell(row.semester_no, "numeric"),
      cell(row.subject_code),
      cell(row.subject_name),
      cell(row.credits, "numeric"),
      cell(row.internal_marks, "numeric"),
      cell(row.external_marks, "numeric"),
      cell(row.total_marks, "numeric"),
      cell(row.grade),
      cell(row.exam_status)
    );
    return tr;
  });

  document.getElementById("studentModal").hidden = false;
}

function closeStudentDetails() {
  document.getElementById("studentModal").hidden = true;
  document.getElementById("modalStudentName").textContent = "Student Marks";
  document.getElementById("modalStudentMeta").textContent = "";
  document.getElementById("modalProfileStrip").innerHTML = "";
  document.getElementById("semesterRows").innerHTML = "";
  document.getElementById("markRows").innerHTML = "";
}

async function loadSchedule() {
  const rows = await api("/api/schedule");
  renderRows("scheduleRows", rows, (row) => {
    const tr = document.createElement("tr");
    tr.append(
      cell(`${row.roll_no} - ${row.full_name}`),
      cell(row.company_name),
      cell(formatDate(row.starts_at)),
      cell(formatDate(row.ends_at)),
      cell(row.venue)
    );
    return tr;
  });
}

async function loadEdges() {
  const rows = await api("/api/matching-edges");
  renderRows("edgeRows", rows, (row) => {
    const tr = document.createElement("tr");
    tr.append(
      cell(`${row.roll_no} - ${row.full_name}`),
      cell(row.company_name),
      cell(`${formatDate(row.starts_at)} | Slot ${row.slot_id}`),
      cell(Number(row.match_score).toFixed(2), "numeric")
    );
    return tr;
  });
}

async function refreshAll() {
  const message = document.getElementById("actionMessage");
  message.textContent = "";
  try {
    await loadSummary();
    await loadCompanies();
    await Promise.all([loadDashboard(), loadStudents(), loadSchedule(), loadEdges()]);
  } catch (error) {
    message.textContent = error.message;
    message.style.color = "#b42318";
  }
}

async function runGreedyScheduling() {
  const message = document.getElementById("actionMessage");
  const companyId = Number(document.getElementById("companySelect").value);
  message.style.color = "#0f7b62";
  message.textContent = "Scheduling...";

  try {
    const result = await api("/api/schedule-greedy", {
      method: "POST",
      body: JSON.stringify({ company_id: companyId }),
    });
    message.textContent = `Scheduled ${result.scheduled_count} interview(s).`;
    await Promise.all([loadSummary(), loadDashboard(), loadSchedule(), loadEdges(), loadStudents()]);
  } catch (error) {
    message.style.color = "#b42318";
    message.textContent = error.message;
  }
}

async function openPostgres() {
  const message = document.getElementById("actionMessage");
  message.style.color = "#0f7b62";
  message.textContent = "Opening PostgreSQL...";

  try {
    const result = await api("/api/open-postgres", { method: "POST" });
    message.textContent = `${result.opened} opened. Connect to ${result.database} on ${result.host}:${result.port}.`;
  } catch (error) {
    message.style.color = "#b42318";
    message.textContent = error.message;
  }
}

document.getElementById("refreshBtn").addEventListener("click", refreshAll);
document.getElementById("runGreedyBtn").addEventListener("click", runGreedyScheduling);
document.getElementById("openPostgresBtn").addEventListener("click", openPostgres);
document.getElementById("studentSearch").addEventListener("input", () => {
  window.clearTimeout(state.studentSearchTimer);
  state.studentSearchTimer = window.setTimeout(loadStudents, 250);
});
document.getElementById("closeStudentModal").addEventListener("click", closeStudentDetails);
document.getElementById("studentModal").addEventListener("click", (event) => {
  if (event.target.id === "studentModal") closeStudentDetails();
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && !document.getElementById("studentModal").hidden) {
    closeStudentDetails();
  }
});
document.querySelectorAll("[data-scroll-target]").forEach((button) => {
  button.addEventListener("click", () => {
    document.getElementById(button.dataset.scrollTarget)?.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  });
});

updateClock();
setInterval(updateClock, 1000);
refreshAll();
