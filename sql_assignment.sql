
Q1
/*
# most inner query (t1): finding the total amount for each order for every customer with given conditions 
# inner query (t2) : generating flag 1,0 for concerned variable values using case statement for max amount order of each customer 
# using the generated column to find the count and percentage
*/

SELECT SUM(amt_below_35) as no_of_cust_below_35, SUM(amt_below_35)*100/COUNT(*) as %_cust_below_35 
FROM (
SELECT ugc_id, 
CASE WHEN MAX(tot_amt) <= 35 THEN 1 
WHEN MAX(tot_amt) > 35 THEN 0 
END AS amt_below_35
FROM (
SELECT ugc_id,grp_ord_num,SUM(amount) tot_amt
FROM sales 
WHERE channel = 'dotcom' AND service_id IN (8,11) AND (visit_date >= '2018-01-01' AND visit_date <= '2018-12-31')
GROUP BY ugc_id,grp_ord_num) t1
GROUP BY ugc_id) t2

########################################################################################################################################

Q2
/*
# inner query (t1): finding total of records with conditions applied and grouped by channel, year, month
# using window function to find total revenue with channel partition as required 
*/


select channel, fy,fym, SUM(tot) OVER (PARTITION BY channel, fy ORDER BY fym ROWS UNBOUNDED PRECEDING) AS total_revenue_untill
FROM (
select channel,YEAR(visit_date) as fy,MONTH(visit_date) as fym,SUM(amount) as tot
from sales
WHERE (visit_date >= '2017-01-01' AND visit_date <= '2017-12-31') AND channel IN ('DOTCOM', 'OG')
group by channel, YEAR(visit_date) ,MONTH(visit_date)) t1

###########################################################################################################################################

Q3
/*
# assuming fiscal_year same as calender year
# generating new column "year_quarter" using the visit_date 
# grouping and ordering by ugc_id and year_quarter
# inner query (t1): generating column "purchase_subdequent_quarter" using lead partitioned by customer 
# using the generated column to count and percentage 
*/


WITH fy as (
SELECT ugc_id, YEAR(visit_date) as year,  
CASE WHEN MONTH(visit_date) IN (1,2,3) THEN YEAR(visit_date)*10+1
WHEN MONTH(visit_date) IN (4,5,6) THEN YEAR(visit_date)*10+2 
WHEN MONTH(visit_date) IN (7,8,9) THEN YEAR(visit_date)*10+3
WHEN MONTH(visit_date) IN(10,11,12) THEN YEAR(visit_date)*10+4
END AS year_quarter
FROM sales 
GROUP BY ugc_id,YEAR(visit_date), year_quarter
ORDER BY ugc_id,YEAR(visit_date), year_quarter),

SELECT year,year_quarter%YEAR(visit_date) as quarter, SUM (purchase_subdequent_quarter) As count, 
(SUM(purchase_subdequent_quarter)*100/COUNT(purchase_subdequent_quarter)) AS percentage 
FROM (
SELECT ugc_id, year ,year_quarter
CASE WHEN (year_quarter - LEAD(year_quarter, 1) over (PARTITION BY ugc_id ORDER BY ugc_id,year, year_quarter)) IN (-1,-7) THEN 1
ELSE 0
END AS purchase_subdequent_quarter
FROM fy) t1
GROUP BY year,year_quarter%YEAR(visit_date)

