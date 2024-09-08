use salary;
select * from salaries;






/* 1. You are a compensation anlyst employed by a multinational corporation. Your Assignment is to pinpoint Countries
who give work fully remote work, for the title 'Managers' Paying salaries Exceeding $90,000 USD */

select * from salaries;
select distinct company_location from salaries
where job_title like '%Manager%' and salary_in_usd>90000 and remote_ratio=100;

/* 2. AS a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients 
IN large tech firms. you're tasked WITH Identifying top 5 Country Having greatest count of large (company size) 
number of companies. */

select company_location,count(*) from (select * from salaries
where experience_level= 'EN' and company_size='L') t 
group by company_location
order by count(*) desc
limit 5;

/* 3.Picture yourself AS a data scientist Working for a workforce management platform. 
Your objective is to calculate the percentage of employees. Who enjoy fully remote roles WITH 
salaries Exceeding $100,000 USD, Shedding light ON the attractiveness of high-paying 
remote positions IN today's job market */

set @total = (select count(*) from salaries where salary_in_usd>100000);
set @count = (select count(*) from salaries where salary_in_usd>100000 and remote_ratio=100);
set @percentage =((select @count)/(select @total))*100;
select round(@percentage,2) as percentage;

/* 4. Imagine you're a data analyst Working for a global recruitment agency. 
Your Task is to identify the Locations where entry-level average salaries exceed the average salary for 
that job title IN market for entry level, helping your agency guide candidates towards lucrative opportunities. */

select t.job_title, company_location,Average,avg_per_country from
(select job_title, avg(salary_in_usd) as 'Average' from salaries 
where experience_level='EN'
group by job_title)t
inner join
(select company_location,job_title, avg(salary_in_usd) 'avg_per_country' from salaries 
where experience_level='EN'
group by company_location,job_title)m
on t.job_title=m.job_title 
where avg_per_country>Average;

/* 5. You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries. 
Your job is to Find out for each job title which. Country pays the maximum average salary. 
This helps you to place your candidates IN those countries */

select * from (select *, dense_rank() over(partition by job_title order by average desc) as rank_num
from (select company_location,job_title, avg(salary_in_usd) as 'average' from salaries
group by company_location,job_title)t)m
where rank_num=1
order by average desc;

/* 6. AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze 
salary trends across different company Locations. Your goal is to Pinpoint Locations WHERE the average 
salary Has consistently Increased over the Past few 
years (Countries WHERE data is available for 3 years Only(present year and past two years) 
providing Insights into Locations experiencing Sustained salary growth. */

with companies as
(
select * from salaries where company_location in
(
select company_location from 
(
select company_location, avg(salary_in_usd) as avg_salary,count(distinct work_year) as cnt from salaries
where work_year>=year(current_date())-2 group by company_location having cnt=3
)t
)
)
select company_location,
max(case when work_year=2022 then average end) as avg_salary_2022,
max(case when work_year=2023 then average end) as avg_salary_2023,
max(case when work_year=2024 then average end) as avg_salary_2024
from 
(select company_location,work_year, avg(salary_in_usd) as average from companies
group by company_location,work_year)q
group by company_location
having avg_salary_2024>avg_salary_2023 and avg_salary_2023>avg_salary_2022 ;

/* 7. Picture yourself AS a workforce strategist employed by a global HR tech startup.Your Mission is to Determine 
the percentage of fully remote work for each experience level IN 2021 and compare it WITH the corresponding figures 
for 2024, Highlighting any significant Increases or decreases IN remote work Adoption over the years */

select * from (select * , (count/total)*100 as 'remote_2021' from (select a.experience_level,a.total,b.count from (select experience_level,count(*) as total from salaries where work_year=2021
group by experience_level) a
inner join
(select experience_level,count(*) as count from salaries where work_year=2021 and remote_ratio=100 group by experience_level) b
on a.experience_level=b.experience_level)t)m
inner join 
(select * , (count/total)*100 as 'remote_2024' from (select a.experience_level,a.total,b.count from (select experience_level,count(*) as total from salaries where work_year=2021
group by experience_level) a
inner join
(select experience_level,count(*) as count from salaries where work_year=2024 and remote_ratio=100 group by experience_level) b
on a.experience_level=b.experience_level)t)n
on m.experience_level=n.experience_level;

/* 8. AS a Compensation specialist at a Fortune 500 company, you're tasked WITH analyzing salary trends over time. 
Your objective is to calculate the average salary increase percentage for each experience level and 
job title between the years 2023 and 2024, helping the company stay competitive IN the talent market*/

with t as 
	(select job_title,experience_level,work_year,round(avg(salary_in_usd),2) as average from salaries
	where work_year in (2023,2024)
	group by job_title,experience_level,work_year)

select *, round(((avg_salary_2024-avg_salary_2023)/avg_salary_2023),2) as Changes 
from (select job_title,experience_level,
		max(case when work_year=2023 then average end) as avg_salary_2023,
		max(case when work_year=2024 then average end) as avg_salary_2024
		from t group by job_title,experience_level)m
where round(((avg_salary_2024-avg_salary_2023)/avg_salary_2023),2) is not null
;

/* 9. You're a database administrator tasked with role-based access control for a company's employee database. 
Your goal is to implement a security measure where employees in different 
experience level (e.g. Entry Level, Senior level etc.) can only access details relevant to their 
respective experience level, ensuring data confidentiality and minimizing the risk of unauthorized access.*/
create user 'Entry_level'@'%' identified by 'EN';
create view entry_level as
(
select * from salaries where experience_level ='EN'
);
grant alter on salary.entry_level to 'Entry_level'@'%';
show privileges;

/* 10. You are working with a consultancy firm, your client comes to you with certain data and preferences such as 
(their year of experience , their employment type, company location and company size )  and want to make an transaction
into different domain in data industry (like  a person is working as a data analyst and want to move to some other 
domain such as data science or data engineering etc.) your work is to  guide them to which domain they should switch to 
base on  the input they provided, so that they can now update their knowledge as  per the suggestion/.. The Suggestion 
should be based on average salary */

DELIMITER //
create PROCEDURE GetAverageSalary(IN exp_lev VARCHAR(2), IN emp_type VARCHAR(3), IN comp_loc VARCHAR(2), IN comp_size VARCHAR(2))
BEGIN
    SELECT job_title, experience_level, company_location, company_size, employment_type, ROUND(AVG(salary), 2) AS avg_salary 
    FROM salaries 
    WHERE experience_level = exp_lev AND company_location = comp_loc AND company_size = comp_size AND employment_type = emp_type 
    GROUP BY experience_level, employment_type, company_location, company_size, job_title order by avg_salary desc ;
END//
DELIMITER ;
-- Deliminator  By doing this, you're telling MySQL that statements within the block should be parsed as a single unit until the custom delimiter is encountered.

call GetAverageSalary('EN','FT','AU','M');

drop procedure Getaveragesalary;

/* 11. As a market researcher, your job is to Investigate the job market for a company that analyzes workforce data. 
Your Task is to know how many people were employed IN different types of companies AS per their size IN 2021. */

select company_size,count(*) as total_employee from salaries
where work_year=2021
group by company_size;

/* 12. Imagine you are a talent Acquisition specialist Working for an International recruitment agency. Your Task is to 
identify the top 3 job titles that command the highest average salary Among part-time Positions IN the year 2023. */

select job_title,avg(salary_in_usd) as average from salaries
where employment_type='PT' 
group by job_title
order by average desc
limit 3;

/* 13. As a database analyst you have been assigned the task to Select Countries where average mid-level salary is higher 
than overall mid-level salary for the year 2023. */
-- Overall mid-level salary for the year 2023
set @average = (select avg(salary_in_usd) from salaries
				where experience_level='MI' and work_year=2023);
-- Countries where average mid-level salary is higher than overall mid-level salary for the year 2023
select company_location,avg(salary_in_usd) as avg_salary from salaries
where experience_level='MI'
group by company_location
having avg(salary_in_usd) > @average;

/* 14. As a database analyst you have been assigned the task to Identify the company locations with the highest and 
lowest average salary for senior-level (SE) employees in 2023. */
-- highest average salary for senior-level (SE) employees in 2023
-- Set the delimiter for the stored procedure

    -- Query to find the highest average salary for senior-level employees in 2023
    SELECT company_location AS highest_location, AVG(salary_in_usd) AS highest_avg_salary
    FROM  salaries
    WHERE work_year = 2023 AND experience_level = 'SE'
    GROUP BY company_location
    ORDER BY highest_avg_salary DESC
    LIMIT 1;

    -- Query to find the lowest average salary for senior-level employees in 2023
    SELECT company_location AS lowest_location, AVG(salary_in_usd) AS lowest_avg_salary
    FROM  salaries
    WHERE work_year = 2023 AND experience_level = 'SE'
    GROUP BY company_location
    ORDER BY lowest_avg_salary ASC
    LIMIT 1;


/* 15. You're a Financial analyst Working for a leading HR Consultancy, and your Task is to Assess the annual salary 
growth rate for various job titles. By Calculating the percentage Increase IN salary FROM previous year to this year, 
you aim to provide valuable Insights Into salary trends WITHIN different job roles. */

with Annual_salary as
					(select t.job_title,t.salary_2023,m.salary_2024 from
					(select job_title, avg(salary_in_usd) as 'salary_2023' from salaries
					where work_year=2023
					group by job_title)t
					inner join
					(select job_title, avg(salary_in_usd) as 'salary_2024' from salaries
					where work_year=2024
					group by job_title)m
					on t.job_title=m.job_title)
select *,round(((salary_2024-salary_2023)/(salary_2023))*100,2) as 'Pct_change_in_salary' from Annual_salary;

/* 16. You've been hired by a global HR Consultancy to identify Countries experiencing significant salary growth for 
entry-level roles. Your task is to list the top three Countries with the highest salary growth rate FROM 2020 to 2023, 
helping multinational Corporations identify Emerging talent markets. */

with t as (select company_location, work_year, avg(salary_in_usd) as average from salaries
			where  experience_level='EN' and (work_year=2021 or work_year=2023)
			group by company_location, work_year)

select *, (((AVG_salary_2023 - AVG_salary_2021) / AVG_salary_2021) * 100) AS changes 
from (select company_location,
		max(case when work_year=2021 then average end) as 'AVG_Salary_2021',
		max(case when work_year=2023 then average end) as 'AVG_Salary_2023'
		from t 
		group by company_location)a
		where (((AVG_salary_2023 - AVG_salary_2021) / AVG_salary_2021) * 100) is not null
		order by (((AVG_salary_2023 - AVG_salary_2021) / AVG_salary_2021) * 100) desc
		limit 3;

/* 17. Picture yourself as a data architect responsible for database management. Companies in US and AU(Australia) 
decided to create a hybrid model for employees they decided that employees earning salaries exceeding $90000 USD, 
will be given work from home. You now need to update the remote work ratio for eligible employees, ensuring efficient 
remote work management while implementing appropriate error handling mechanisms for invalid input parameters. */

-- creating temporary table so that changes are not made in actual table
create table temp_salaries as select * from salaries;
select * from temp_salaries;

update temp_salaries 
set remote_ratio=100
where (company_location='AU' or company_location='AS') and salary_in_usd>90000;
select * from temp_salaries
where (company_location='AU' or company_location='AS') and salary_in_usd>90000;

/* 18. In the year 2024, due to increased demand in the data industry, there was an increase in salaries of data field 
employees.
a.	Entry Level-35% of the salary.
b.	Mid junior – 30% of the salary.
c.	Immediate senior level- 22% of the salary.
d.	Expert level- 20% of the salary.
e.	Director – 15% of the salary.
You must update the salaries accordingly and update them back in the original database. */

update temp_salaries
set salary_in_usd  = (
					case 
						when experience_level='EN' then salary_in_usd*1.35
                        when experience_level='MI' then salary_in_usd*1.30
                        when experience_level='SE' then salary_in_usd*1.22
                        when experience_level='EX' then salary_in_usd*1.20
                        when experience_level='DX' then salary_in_usd*1.15
                        else salary_in_usd
					end)
                    where work_year=2024;
select * from temp_salaries
where work_year=2024;                    
                    
/* 19. You are a researcher and you have been assigned the task to Find the year with the highest average salary for 
each job title. */

WITH avg_salary_per_year AS 
(
    -- Calculate the average salary for each job title in each year
    SELECT work_year, job_title, AVG(salary_in_usd) AS avg_salary 
    FROM salaries
    GROUP BY work_year, job_title
)

SELECT job_title, work_year, avg_salary FROM 
    (
       -- Rank the average salaries for each job title in each year
       SELECT job_title, work_year, avg_salary, 
       RANK() OVER (PARTITION BY job_title ORDER BY avg_salary DESC) AS rank_by_salary
	   FROM avg_salary_per_year
    ) AS ranked_salary
WHERE 
    rank_by_salary = 1;


/* 20. You have been hired by a market research agency where you been assigned the task to show the percentage of 
different employment type (full time, part time) in Different job roles, in the format where each row will be 
job title, each column will be type of employment type and cell value for that row and column will show the % value.
*/

SELECT 
    job_title,
    ROUND((SUM(CASE WHEN employment_type = 'PT' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS PT_percentage, -- Calculate percentage of part-time employment
    ROUND((SUM(CASE WHEN employment_type = 'FT' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS FT_percentage, -- Calculate percentage of full-time employment
    ROUND((SUM(CASE WHEN employment_type = 'CT' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS CT_percentage, -- Calculate percentage of contract employment
    ROUND((SUM(CASE WHEN employment_type = 'FL' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS FL_percentage -- Calculate percentage of freelance employment
FROM 
    salaries
GROUP BY 
    job_title;