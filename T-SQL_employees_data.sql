
--SQL Server - Create insert statements


CREATE TABLE managers (
    employee_id INT,
    employee_name NVARCHAR(100),
    manager_id INT
);

INSERT INTO managers (employee_id, employee_name, manager_id) VALUES
(1, 'Alice', NULL),
(2, 'Bob', 1),
(3, 'Carol', 2),
(4, 'David', 2),
(5, 'Eve', 1);

--projects

CREATE TABLE projects (
    project_id INT,
    employee_id INT
);

INSERT INTO projects (project_id, employee_id) VALUES
(101, 1),
(102, 2),
(103, 2),
(104, 3),
(105, 4),
(106, 4),
(107, 4);

--employees

CREATE TABLE employees (
    id INT PRIMARY KEY,
    name NVARCHAR(100),
    department NVARCHAR(100),
    salary DECIMAL(10, 2)
);

INSERT INTO employees (id, name, department, salary) VALUES
(1, 'Alice', 'Engineering', 75000),
(2, 'Bob', 'Sales', 65000),
(3, 'Carol', 'Engineering', 85000),
(4, 'David', 'HR', 55000),
(5, 'Eve', 'Sales', 68000);
--departments (only used in total salary calcs, assumed as part of employees)
--No separate table needed due to usage in employees.

--customers

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name NVARCHAR(100)
);

INSERT INTO customers (customer_id, customer_name) VALUES
(1, 'Customer A'),
(2, 'Customer B'),
(3, 'Customer C'),
(4, 'Customer D');

--orders

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_amount DECIMAL(10, 2)
);

INSERT INTO orders (order_id, customer_id, order_date, order_amount) VALUES
(101, 1, '2024-12-01', 150.00),
(102, 1, '2025-03-01', 200.00),
(103, 2, '2025-03-15', 300.00),
(104, 3, '2025-04-10', NULL),
(105, 3, '2025-01-10', 400.00);

--sales

CREATE TABLE sales (
    sales_id INT PRIMARY KEY,
    product_id INT,
    sale_date DATE,
    customer_id INT,
    quantity INT,
    price DECIMAL(10, 2),
    quantity_sold INT,
    order_amount DECIMAL(10, 2)
);

INSERT INTO sales (sales_id, product_id, sale_date, customer_id, quantity, price, quantity_sold, order_amount) VALUES
(1, 101, '2025-01-01', 1, 2, 100, 2, 200.00),
(2, 102, '2025-02-01', 1, 1, 200, 1, 200.00),
(3, 101, '2025-03-01', 2, 3, 100, 3, 300.00),
(4, 103, '2025-03-15', 3, 1, 400, 1, 400.00),
(5, 101, '2025-04-01', 4, 4, 100, 4, 400.00);

--transactions

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10, 2)
);

INSERT INTO transactions (transaction_id, customer_id, transaction_date, amount) VALUES
(1, 1, '2025-03-10', 100.00),
(2, 1, '2025-04-01', 200.00),
(3, 2, '2025-02-20', 300.00),
(4, 3, '2025-01-15', 400.00),
(5, 1, '2025-03-25', 50.00),
(6, 3, '2025-04-01', 120.00);

CREATE TABLE famous (
    user_id INT,
    follower_id INT
);

INSERT INTO famous (user_id, follower_id) VALUES
(1, 2),
(1, 3),
(1, 4),
(2, 3),
(3, 4),
(4, 2);

--subscriptions

CREATE TABLE subscriptions (
    subscription_id INT,
    customer_id INT,
    start_date DATE,
    end_date DATE
);

INSERT INTO subscriptions (subscription_id, customer_id, start_date, end_date) VALUES
(1, 1, '2025-03-01', '2025-04-30'),
(2, 1, '2025-04-10', '2025-05-10'),
(3, 2, '2025-03-01', '2025-03-31'),
(4, 3, '2025-02-01', '2025-04-01');

--users

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email NVARCHAR(100)
);

INSERT INTO users (user_id, email) VALUES
(1, 'user@example.com'),
(2, 'USER@example.com'),
(3, 'user2@example.com');

 --performance

CREATE TABLE performance (
    employee_id INT,
    evaluation_date DATE,
    evaluation_score INT
);

INSERT INTO performance (employee_id, evaluation_date, evaluation_score) VALUES
(1, '2025-01-01', 80),
(1, '2025-04-01', 90),
(2, '2025-02-01', 70),
(2, '2025-03-15', 85);

-------------------------------------------------------------------------------------

-- SQL Server queries

-- 1. Subquery in WHERE clause
SELECT firstname, lastname
FROM employees
WHERE departmentid IN (SELECT departmentid FROM department WHERE departmentname = 'Finance');

-- 2. Second-highest salary
SELECT MAX(salary) AS second_highest_salary
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- 3. Third highest salary without using LIMIT
SELECT MAX(salary) AS third_highest_salary
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees WHERE salary < (SELECT MAX(salary) FROM employees));

-- 3.1 Third highest using OFFSET equivalent
SELECT TOP 1 salary AS third_highest_salary
FROM (
    SELECT DISTINCT TOP 3 salary
    FROM employees
    ORDER BY salary DESC
) AS temp
ORDER BY salary ASC;

-- 3.2 Third highest salary using window function
SELECT DISTINCT salary
FROM (
    SELECT salary, RANK() OVER (ORDER BY salary DESC) AS rank
    FROM employees
) ranked
WHERE rank = 3;

-- 3.3 Employees ranked by salary within department
SELECT first_name, last_name, department_id, 
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
FROM employees;

-- 4. Total salary per department above threshold
WITH department_total_salaries AS (
    SELECT departmentid, SUM(salary) AS total_salary
    FROM employees
    GROUP BY departmentid
)
SELECT d.departmentname, dt.departmentid, dt.total_salary
FROM department_total_salaries dt
INNER JOIN department d ON d.departmentid = dt.departmentid
WHERE total_salary > 600000;

-- 5. Find duplicate department_id
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 1;

-- Duplicate emails using window function
SELECT personid, email
FROM (
    SELECT personid, email, COUNT(*) OVER (PARTITION BY personid) AS email_count
    FROM person
) t
WHERE email_count > 1;

-- Count total duplicate departmentid values
WITH dup_records_cte AS (
    SELECT departmentid, COUNT(*) OVER(PARTITION BY departmentid) AS email_count
    FROM employees
)
SELECT SUM(email_count - 1) AS total_duplicates
FROM dup_records_cte
WHERE email_count > 1;

-- Delete duplicate emails
WITH CTE AS (
    SELECT personid, email, ROW_NUMBER() OVER (PARTITION BY email ORDER BY personid) AS row_num
    FROM Person
)
DELETE FROM Person
WHERE personid IN (SELECT personid FROM CTE WHERE row_num > 1);

-- 6. Employees earning more than dept average
SELECT e.first_name, e.last_name, e.salary
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary)
    FROM employees
    WHERE department_id = e.department_id
);

-- cte version much preferred method
--- employees earning more than department average 
-- Note the salary data type is decimal (10,2) however its beneficial to always cast to decimal 10, 2 when using round function

with dept_avg_cte as (
    select department_id, cast(round(avg(salary), 2) as decimal(10,2)) as dept_avg
    from Employees
    group by department_id
)
select e.first_name, e.last_name, e.salary, da.dept_avg
from Employees e
inner join dept_avg_cte da
on e.department_id = da.department_id
where e.salary > da.dept_avg;

-- 7. pivot data by a categorical column such as Pivot by a gender
SELECT department_id,
       SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM employees
GROUP BY department_id;

-- 8. Top 5 customers by purchases
SELECT TOP 5 customer_id, SUM(order_amount) AS total_spent
FROM orders
GROUP BY customer_id
ORDER BY total_spent DESC;

-- 9. Products never sold
SELECT product_id, product_name
FROM products
WHERE product_id NOT IN (SELECT DISTINCT product_id FROM orders);

-- 10. Employees without department
SELECT e.employee_id, e.name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE d.department_id IS NULL;

-- 11. Employees hired last year
SELECT employee_id, name, hire_date
FROM employees
WHERE YEAR(hire_date) = YEAR(GETDATE()) - 1;

-- 12. Hired in last 6 months
SELECT first_name, last_name, hire_date
FROM employees
WHERE hire_date >= DATEADD(MONTH, -6, GETDATE());

-- 13. Department with most employees
SELECT TOP 1 department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
ORDER BY employee_count DESC;

-- 14. Top 5 products by sales revenue
SELECT TOP 5 product_id, SUM(quantity * price) AS total_sales
FROM sales
GROUP BY product_id
ORDER BY total_sales DESC;

-- 15. Monthly sales per product (current month)
SELECT product_id, SUM(quantity * price) AS total_sales
FROM sales
WHERE MONTH(sale_date) = MONTH(GETDATE())
  AND YEAR(sale_date) = YEAR(GETDATE())
GROUP BY product_id;

-- 16. Month-over-month revenue growth
with month_rev as (
    select 
        month(order_date) as month,
        coalesce(sum(order_amount),0) as monthly_revenue
    from orders
    group by month(order_date)
)
select 
    month,
    monthly_revenue,
    coalesce(lag(monthly_revenue) over(order by month),0) as previous_month_revenue,
    coalesce(round(monthly_revenue - lag(monthly_revenue) over(order by month) * 100 / 
    nullif(lag(monthly_revenue) over(order by month),0), 2), 0) as revenue_growth_percent
from month_rev;


-- year over year revenue growth

-- revenue growth % = (year revenue - previous year revenue X 100) / previous year revenue

with y_o_y_rev as (
    select 
        year(order_date) as year,
        coalesce(sum(order_amount),0) as yearly_revenue
    from orders
    group by year(order_date)
)

select 
    year,
   coalesce(lag(yearly_revenue) over(order by year),0) as previous_year_revenue,
   coalesce(round(yearly_revenue - lag(yearly_revenue) over(order by year) * 100 /
   nullif(lag(yearly_revenue) over(order by year),0)
        ,2)
    ,0) as revenue_growth_percent
from y_o_y_rev;


-- Products with increasing monthly sales
WITH product_sales_cte AS (
    SELECT product_id, 
           FORMAT(order_date, 'yyyy-MM') AS month,
           SUM(sale_amount) AS monthly_sales,
           LAG(SUM(sale_amount)) OVER(PARTITION BY product_id ORDER BY FORMAT(order_date, 'yyyy-MM')) AS previous_month_sales
    FROM orders 
    GROUP BY product_id, FORMAT(order_date, 'yyyy-MM')
)
SELECT product_id, month, monthly_sales
FROM product_sales_cte
WHERE monthly_sales > previous_month_sales;

-- 18. Employees joined after 2021-01-01 with tenure
WITH recent_hires AS (
    SELECT id, name, hire_date
    FROM employees
    WHERE hire_date > '2021-01-01'
)
SELECT name, hire_date, DATEDIFF(YEAR, hire_date, GETDATE()) AS tenure_years
FROM recent_hires;

-- 19. Departments with total salary over 120k
WITH department_salaries AS (
    SELECT department, SUM(salary) AS total_salary
    FROM employees
    GROUP BY department
)
SELECT department, total_salary
FROM department_salaries
WHERE total_salary > 120000;

-- 20. Employees earning above department average
WITH department_avg AS (
    SELECT department, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department
),
above_avg_employees AS (
    SELECT e.name, e.department, e.salary
    FROM employees e
    JOIN department_avg d ON e.department = d.department
    WHERE e.salary > d.avg_salary
)
SELECT * FROM above_avg_employees;

--SQL Server queries

-- 21. Recursive CTE: Organizational Hierarchy
WITH hierarchy AS (
    SELECT 
        employee_id, 
        employee_name, 
        manager_id, 
        CAST(employee_name AS VARCHAR(MAX)) AS chain_of_command
    FROM managers
    WHERE manager_id IS NULL
    UNION ALL
    SELECT 
        m.employee_id, 
        m.employee_name, 
        m.manager_id, 
        h.chain_of_command + ' -> ' + m.employee_name
    FROM managers m
    JOIN hierarchy h ON m.manager_id = h.employee_id
)
SELECT * 
FROM hierarchy
ORDER BY employee_id;

-- 22. Employees on more than one project
WITH project_counts AS (
    SELECT employee_id, COUNT(*) AS project_count
    FROM projects
    GROUP BY employee_id
)
SELECT 
    e.name AS employee_name, p.project_count
FROM employees e
JOIN project_counts p ON e.id = p.employee_id
WHERE p.project_count > 1;

-- 23. Top 3 highest-paid employees and departments with highest total salary
WITH top_employees AS (
    SELECT TOP 3 name, salary
    FROM employees
    ORDER BY salary DESC
),
top_departments AS (
    SELECT TOP 2 department, SUM(salary) AS total_salary
    FROM employees
    GROUP BY department
    ORDER BY total_salary DESC
)
SELECT 'Top Employees' AS category, name AS detail FROM top_employees
UNION ALL
SELECT 'Top Departments', department FROM top_departments;

-- 24. Salaries > 65,000
WITH high_earners AS (
    SELECT id, name, salary
    FROM employees
    WHERE salary > 65000
)
SELECT * FROM high_earners;

-- 25. Above average salary
WITH avg_salary AS (
    SELECT AVG(salary) AS average_salary FROM employees
),
above_avg AS (
    SELECT name, department, salary
    FROM employees
    WHERE salary > (SELECT average_salary FROM avg_salary)
)
SELECT * FROM above_avg;

-- 26. Customers without orders
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 26a. Cumulative sum of orders
SELECT order_id, order_date, customer_id, order_amount,
       SUM(order_amount) OVER (ORDER BY order_date) AS cumulative_sales
FROM sales;

-- 27. Most recent order per customer
SELECT customer_id, order_id, order_date
FROM (
    SELECT customer_id, order_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
) ranked_orders
WHERE rn = 1;

-- 28. Orders in last 3 months but not last month
SELECT c.customer_id, c.name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
    AND o.order_date >= DATEADD(MONTH, -3, GETDATE())
    AND o.order_date < DATEADD(MONTH, -1, GETDATE())
)
AND NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
    AND o.order_date >= DATEADD(MONTH, -1, GETDATE())
);

-- 28a. Famous percentage
WITH total_users AS (
    SELECT COUNT(DISTINCT user_id) AS total_num_users FROM famous
),
total_followers_of_user AS (
    SELECT user_id, COUNT(DISTINCT follower_id) AS follower_count
    FROM famous
    GROUP BY user_id
)
SELECT user_id, ROUND(1.0 * follower_count * 100 / (SELECT total_num_users FROM total_users), 2) AS famous_percent
FROM total_followers_of_user;

-- 29. Products with more than 3 sales per day
SELECT product_id, sale_date, COUNT(*) AS sales_count
FROM sales
GROUP BY product_id, sale_date
HAVING COUNT(*) > 3;

-- 30. Total transaction amount per customer (last 30 days)
SELECT customer_id, SUM(amount) AS total_amount
FROM transactions
WHERE transaction_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY customer_id;

-- 31. Running total of quantity_sold per product
SELECT product_id, sale_date,
       SUM(quantity_sold) OVER (PARTITION BY product_id ORDER BY sale_date) AS running_total
FROM sales;

-- 32. Total sales per customer excluding NULLs
SELECT customer_id, SUM(order_amount) AS total_sales
FROM orders
WHERE order_amount IS NOT NULL
GROUP BY customer_id;

-- 33. Subscriptions ended in last 30 days and new one started in last 7
SELECT s.customer_id, s.subscription_id
FROM subscriptions s
WHERE s.end_date >= DATEADD(DAY, -30, GETDATE())
AND s.start_date <= DATEADD(DAY, -7, GETDATE())
AND EXISTS (
    SELECT 1 FROM subscriptions s2
    WHERE s2.customer_id = s.customer_id
    AND s2.start_date >= DATEADD(DAY, -7, GETDATE())
);

-- 34. Customers with more than 5 transactions in last 6 months
WITH customer_transactions AS (
    SELECT customer_id, COUNT(*) AS transaction_count, SUM(amount) AS total_spent
    FROM transactions
    WHERE transaction_date >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY customer_id
)
SELECT customer_id, total_spent
FROM customer_transactions
WHERE transaction_count > 5;

-- 35. Duplicate emails regardless of case
SELECT LOWER(email) AS normalized_email, COUNT(*) AS email_count
FROM users
GROUP BY LOWER(email)
HAVING COUNT(*) > 1;

-- 36. Score difference between last two evaluations
WITH ranked_performance AS (
    SELECT employee_id, evaluation_date, evaluation_score,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY evaluation_date DESC) AS rank
    FROM performance
)
SELECT p1.employee_id, p1.evaluation_score - p2.evaluation_score AS score_difference
FROM ranked_performance p1
JOIN ranked_performance p2 ON p1.employee_id = p2.employee_id AND p1.rank = 1 AND p2.rank = 2;

-- 37. Rolling 3-month average of revenue using LAG()
WITH revenue_per_day AS (
    SELECT product_id, sale_date, SUM(quantity * price) AS revenue
    FROM sales
    GROUP BY product_id, sale_date
)
SELECT 
    product_id, sale_date, revenue,
    ROUND((
        revenue + 
        ISNULL(LAG(revenue, 1) OVER (PARTITION BY product_id ORDER BY sale_date), 0) +
        ISNULL(LAG(revenue, 2) OVER (PARTITION BY product_id ORDER BY sale_date), 0)
    ) / 3.0, 2) AS rolling_avg_3_months
FROM revenue_per_day;

-- Forecast avg using LEAD()
SELECT 
    product_id, sale_date, revenue,
    ROUND((
        revenue + 
        ISNULL(LEAD(revenue, 1) OVER (PARTITION BY product_id ORDER BY sale_date), 0) +
        ISNULL(LEAD(revenue, 2) OVER (PARTITION BY product_id ORDER BY sale_date), 0)
    ) / 3.0, 2) AS forecast_avg_3_months
FROM revenue_per_day;

-- 38. Categorize order values
SELECT 
    sales_id, Price, 
    CASE 
        WHEN price >= 1000 THEN 'High Value'
        WHEN price >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_category
FROM sales;

-- Procedure: GetLowSalaryEmployees
CREATE PROCEDURE GetLowSalaryEmployees
    @salary_threshold NUMERIC
AS
BEGIN
    PRINT 'Employee IDs with salary less than ' + CAST(@salary_threshold AS VARCHAR);
    DECLARE @EID INT;
    DECLARE emp_cursor CURSOR FOR 
        SELECT EID FROM Employee WHERE ESalary < @salary_threshold;

    OPEN emp_cursor;
    FETCH NEXT FROM emp_cursor INTO @EID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @EID;
        FETCH NEXT FROM emp_cursor INTO @EID;
    END

    CLOSE emp_cursor;
    DEALLOCATE emp_cursor;
END;
GO

EXEC GetLowSalaryEmployees 50000;

-- Procedure: TruncateTable already provided
-- Trigger conversion would depend on the logic needed and is written differently in SQL Server (AFTER/INSTEAD OF TRIGGER)
