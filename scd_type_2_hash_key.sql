/* Implementing hash kays to track changes in SCD type 2 table
An employees can change department, job title, or salary over time.
We want to track those changes historically using SCD Type 2 logic. */

-- 1. create staging table as source table 
create table stg_employee(
    employee_id int,
    full_name varchar(100),
    department_id int,
    job_title varchar(100),
    salary decimal(10,2)
);

-- 2. create slowly changing dimension type 2

create table dim_employee (
    dim_id INT IDENTITY PRIMARY KEY,
    employee_id INT,
    full_name VARCHAR(100),
    department_id INT,
    job_title VARCHAR(100),
    salary DECIMAL(10,2),
    row_hash VARCHAR(64),
    is_current BIT,
    start_date DATETIME,
    end_date DATETIME
);

--3. first initial load of data to source table

INSERT INTO stg_employee (employee_id, full_name, department_id, job_title, salary) VALUES
(1, 'Alice Johnson', 101, 'Data Analyst', 75000.00),
(2, 'Bob Smith', 102, 'Software Engineer', 95000.00);

/* 4. first load of data to dimension table.
Make sure to handle nulls as nulls will break any comparison as null + 'value' = null */

insert into dim_employee(employee_id, full_name, department_id, job_title, salary, row_hash, is_current, start_date, end_date)
select 
    s.employee_id,
    s.full_name,
    s.department_id,
    s.job_title,
    s.salary,
    convert(varchar(64), HASHBYTES('SHA1', 
        concat(
            isnull(cast(s.department_id as varchar), ''), '|',
            isnull(s.job_title, ''), '|',
            isnull(cast(s.salary as varchar), '')
        )
    ), 2), -- Convert binary to a hexadecimal string, without the 0x prefix.
    1, --set is_current = 1
    getdate(), --set the start date = current date
    null -- end date as null as its the current record
from stg_employee s;

select top 4 *
from dim_employee;

-- 5. incorporate a new change to source table (department & salary change for employee_id = 2)

-- Truncate and insert new records
truncate table stg_employee;

INSERT INTO stg_employee (employee_id, full_name, department_id, job_title, salary) VALUES
(1, 'Alice Johnson', 101, 'Data Analyst', 75000.00),        -- unchanged
(2, 'Bob Smith', 103, 'Software Engineer', 98000.00);  -- department & salary for this employees has changed

-- 6. reflect change in the dimension table with SCD type 2 merge logic

with staged_hashes as ( ---create a staging view with converted hash values for new changes
    select 
        s.*, -- selects all rows from staging table
        convert(varchar(64), hashbytes('SHA1',
        concat(
            isnull(cast(s.department_id as varchar), ''), '|',
            isnull(s.job_title, ''), '|',
            isnull(cast(s.salary as varchar), '')
        )
        ), 2) as new_row_hash
from stg_employee s
)
-- merge dimension(target) with staged_hashes(source) on employee_id and current record
merge dim_employee as target
using staged_hashes as source 
on target.employee_id = source.employee_id
and target.is_current = 1
--If matched and row has changed (hash mismatch) — expire old record
when matched and target.row_hash <> source.new_row_hash then
update set
    is_current = 0,
    end_date = GETDATE()
-- if not matched (new or changed row) insert new record version
when not matched by target 
then 
insert (employee_id,
        full_name,
        department_id,
        job_title,
        salary,
        row_hash,
        is_current,
        start_date,
        end_date
    )
    values(source.employee_id,
        source.full_name,
        source.department_id,
        source.job_title,
        source.salary,
        source.new_row_hash,
        1,
        GETDATE(),
        NULL
    );
--check results to verify change is successful

    select * from dim_employee

