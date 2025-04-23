# SQL Server MERGE with Hash Keys - Slowly Changing Dimension (SCD Type 2)

This project demonstrates how to use SQL Server's `MERGE` statement with a **row hash** to manage **Slowly Changing Dimensions (SCD Type 2)**. 
It tracks changes to employee records, ensuring historical accuracy and efficiently identifying new and changed rows in a data warehouse.

[Full SQL script here] (https://github.com/JJRyan0/T_SQL_Scripts/blob/main/scd_type_2_hash_key.sql)

---

## Project Overview

This project includes the following key elements:

1. **Creation of Staging and Target Tables**  
2. **Row Hash Generation using `HASHBYTES` and `CONCAT`**  
3. **MERGE statement for SCD Type 2 Logic**  
4. **Tracking Changes with `is_current`, `start_date`, and `end_date`**

---

## 1. Table Definitions

### Staging Table (`stg_employee`)

The staging table is where new or changed data is stored temporarily before it's merged into the final dimension table.

```sql
CREATE TABLE stg_employee (
    employee_id INT,
    full_name VARCHAR(100),
    department_id INT,
    job_title VARCHAR(100),
    salary DECIMAL(10,2)
);
```

### Target Table (`dim_employee`)

The target dimension table will hold the historical employee records. It uses the `is_current` flag to mark the active record and `start_date`/`end_date` to track the validity period of each record.

```sql
CREATE TABLE dim_employee (
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
```

---

## 2. Inserting Sample Data into the Staging Table

For testing purposes, sample data is inserted into the staging table. This data represents new or changed employee records.

```sql
INSERT INTO stg_employee (employee_id, full_name, department_id, job_title, salary)
VALUES
(1, 'Alice Smith', 10, 'Analyst', 60000.00),
(2, 'Bob Johnson', 20, 'Engineer', 80000.00),
(3, 'Clara Adams', 30, 'Manager', 95000.00);
```

### Expected Result in `stg_employee`:

| employee_id | full_name     | department_id | job_title | salary  |
|-------------|---------------|---------------|-----------|---------|
| 1           | Alice Smith   | 10            | Analyst   | 60000.00|
| 2           | Bob Johnson   | 20            | Engineer  | 80000.00|
| 3           | Clara Adams   | 30            | Manager   | 95000.00|

---

## 3. Row Hash Generation in Staging

A **row hash** is generated to track changes to records. The hash is based on a combination of `department_id`, `job_title`, and `salary`. If any of these values change, the hash will change, indicating a record modification.

```sql
WITH staged_hashes AS (
    SELECT 
        s.employee_id,
        s.full_name,
        s.department_id,
        s.job_title,
        s.salary,
        CONVERT(VARCHAR(64), HASHBYTES('SHA1',
            CONCAT(
                ISNULL(CAST(s.department_id AS VARCHAR), ''), '|',
                ISNULL(s.job_title, ''), '|',
                ISNULL(CAST(s.salary AS VARCHAR), '')
            )
        ), 2) AS new_row_hash
    FROM stg_employee s
)
```

### Expected Result for `staged_hashes` (Example):

| employee_id | full_name     | department_id | job_title | salary  | new_row_hash                                          |
|-------------|---------------|---------------|-----------|---------|-------------------------------------------------------|
| 1           | Alice Smith   | 10            | Analyst   | 60000.00| `3a3a6a60c4d0f3957887bde8d0e1b9e3d717ddf1`          |
| 2           | Bob Johnson   | 20            | Engineer  | 80000.00| `9e3b2fc56ffb79bb0ea8d25c988b501fe12c5d15`          |
| 3           | Clara Adams   | 30            | Manager   | 95000.00| `35d1f064b4f634efedeea3274b87f029f43fe7fa`          |

The `new_row_hash` is computed using a combination of `department_id`, `job_title`, and `salary`.

---

## 4. MERGE Statement for SCD Type 2

The `MERGE` statement is used to compare the staging data (`staged_hashes`) with the target table (`dim_employee`). The logic tracks changes using the `row_hash` and flags records as **expired** (`is_current = 0`) if they have changed. New records are inserted as new versions.

### Complete `MERGE` Logic

```sql
MERGE dim_employee AS target
USING staged_hashes AS source
ON target.employee_id = source.employee_id AND target.is_current = 1

-- If matched and data has changed (hash mismatch) — expire old record
WHEN MATCHED AND target.row_hash <> source.new_row_hash THEN
    UPDATE SET
        target.is_current = 0,
        target.end_date = GETDATE()

-- If not matched (new or changed row) — insert new version
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        employee_id,
        full_name,
        department_id,
        job_title,
        salary,
        row_hash,
        is_current,
        start_date,
        end_date
    )
    VALUES (
        source.employee_id,
        source.full_name,
        source.department_id,
        source.job_title,
        source.salary,
        source.new_row_hash,
        1,
        GETDATE(),
        NULL
    );
```

### Expected Result in `dim_employee` (First Run):

Assuming this is the first time the `MERGE` is run, the `dim_employee` table will have no records initially, so the `INSERT` logic will insert all records from the `staged_hashes` result.

| employee_id | full_name     | department_id | job_title | salary  | row_hash                                             | is_current | start_date        | end_date |
|-------------|---------------|---------------|-----------|---------|------------------------------------------------------|------------|-------------------|----------|
| 1           | Alice Smith   | 10            | Analyst   | 60000.00| `3a3a6a60c4d0f3957887bde8d0e1b9e3d717ddf1`           | 1          | 2025-04-23 10:00  | NULL     |
| 2           | Bob Johnson   | 20            | Engineer  | 80000.00| `9e3b2fc56ffb79bb0ea8d25c988b501fe12c5d15`           | 1          | 2025-04-23 10:00  | NULL     |
| 3           | Clara Adams   | 30            | Manager   | 95000.00| `35d1f064b4f634efedeea3274b87f029f43fe7fa`           | 1          | 2025-04-23 10:00  | NULL     |

---

## 5. Tracking Changes (Scenario: Update to an Existing Record)

Let’s assume we have a change to an existing employee record in the staging table, for example:

```sql
UPDATE stg_employee
SET job_title = 'Senior Analyst', salary = 65000.00
WHERE employee_id = 1;
```

### Running the MERGE Again

Running the `MERGE` statement again will detect the change in the row hash for employee 1, and the previous record will be expired (`is_current = 0`), while a new version of the record will be inserted.

### Expected Result in `dim_employee` (After Update):

| employee_id | full_name     | department_id | job_title       | salary  | row_hash                                             | is_current | start_date        | end_date           |
|-------------|---------------|---------------|-----------------|---------|------------------------------------------------------|------------|-------------------|--------------------|
| 1           | Alice Smith   | 10            | Analyst         | 60000.00| `3a3a6a60c4d0f3957887bde8d0e1b9e3d717ddf1`           | 0          | 2025-04-23 10:00  | 2025-04-23 10:05  |
| 1           | Alice Smith   | 10            | Senior Analyst  | 65000.00| `5f56a9f89b6c0912bfaef2e7a98478f59d9e3e69`           | 1          | 2025-04-23 10:05  | NULL               |
| 2           | Bob Johnson   | 20            | Engineer        | 80000.00| `9e3b2fc56ffb79bb0ea8d25c988b501fe12c5d15`           | 1          | 2025-04-23 10:00  | NULL               |
| 3           | Clara Adams   | 30            | Manager         | 95000.00| `35d1f064b4f634efedeea3274b87f029f43fe7fa`           | 1          | 2025-04-23 10:00  | NULL               |

In this case:
- The original record for Alice Smith is marked as `is_current = 0`, and an `end_date` is added.
- A new record for Alice Smith with the updated details is inserted as a new version (`is_current = 1`).

---

## 6. Important Considerations

- **Row Hashing**: The `row_hash` is calculated based on changeable fields (`department_id`, `job_title`, and `salary`). Any change in these fields triggers the creation of a new record with a new `row_hash`.
