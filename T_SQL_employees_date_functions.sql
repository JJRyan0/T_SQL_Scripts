--employees hired in the last year
select employee_id from employees
where datediff(day, hire_date, getdate()) >= 365;

--employee hired in 2020
select * from employees
where month(hire_date) = 11;

--find employees who have a hire end date
select employee_id, concat(first_name, '' , last_name) as fullname, hire_date, hire_end_date, 
datediff(day, current_date, hire_date) as days_employed
from employees;

-- select difference in hours between dates 
select datediff(hour, current_date, '2023-03-15') as DateDifference

-- find employee who have been employed for more than 2 years 

select employee_id, concat(first_name, '' , last_name) as fullname, hire_date
from employees
where datediff(day, current_date, hire_date) > 10
