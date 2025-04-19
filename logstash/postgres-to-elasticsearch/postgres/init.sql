-- Create user and database
CREATE USER vbv WITH PASSWORD 'vbv';
CREATE DATABASE vbvdb;
GRANT ALL PRIVILEGES ON DATABASE vbvdb TO vbv;

\connect vbvdb;

-- Tables
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    position VARCHAR(50),
    salary DECIMAL(10,2),
    department_id INT REFERENCES departments(id)
);

CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(id),
    project_name VARCHAR(100),
    hours_worked INT
);

-- Data: Departments
INSERT INTO departments (name) VALUES 
('IT'), ('HR'), ('Finance'), ('Marketing'), ('Operations');

-- Data: Employees
INSERT INTO employees (name, position, salary, department_id) VALUES
('Bhuvi', 'Manager', 675000.00, 1),
('Vibhu', 'Developer', 555000.00, 1),
('Rudra', 'Analyst', 460000.00, 2),
('Anaya', 'Accountant', 480000.00, 3),
('Aarav', 'Sales Lead', 510000.00, 4);

-- Data: Projects
INSERT INTO projects (employee_id, project_name, hours_worked) VALUES
(1, 'Infra Upgrade', 120),
(1, 'Cloud Migration', 90),
(2, 'Analytics', 100),
(2, 'Backend Refactor', 60),
(3, 'Survey', 40),
(4, 'Audit', 70),
(4, 'Compliance', 55),
(5, 'Ad Campaign', 80),
(5, 'Market Study', 45);

-- View for Elasticsearch
CREATE VIEW employee_summary AS
SELECT 
    e.id,
    e.name,
    e.position,
    e.salary,
    d.name AS department,
    json_agg(
        json_build_object('project_name', p.project_name, 'hours', p.hours_worked)
    ) AS projects
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN projects p ON e.id = p.employee_id
GROUP BY e.id, d.name;

-- Grant access
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO vbv;
