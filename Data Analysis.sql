/* 
		CodeBasics Resume Challenge #4
        
		Atliq Hardwares is one of the leading computer hardware producers in India and well expanded in
        other countries too. Now their managment wants to get insights on the sales of its products.
        As a Data Analyst, I have been assaigned 10 ad-hoc requests and draw insights from them regarding sales.

*/


-- 1.Provide the list of markets in which customer "Atliq Exclusive" operates its
--   business in the APAC region.
select distinct(market)
from dim_customer
where region= "APAC" and customer="Atliq Exclusive"
order by market;


-- 2.What is the percentage of unique product increase in 2021 vs. 2020? The
--   final output contains these fields.
SELECT X.A AS unique_product_2020, Y.B AS unique_products_2021, ROUND((B-A)*100/A, 2) AS percentage_chg
FROM
     (
      (SELECT COUNT(DISTINCT(product_code)) AS A FROM fact_sales_monthly
      WHERE fiscal_year = 2020) X,
      (SELECT COUNT(DISTINCT(product_code)) AS B FROM fact_sales_monthly
      WHERE fiscal_year = 2021) Y 
	 );


-- 3.Provide a report with all the unique product counts for each segment and
--   sort them in descending order of product counts. The final output contains
--   2 fields,
select segment, count(distinct(product_code)) as product_count
from dim_product
group by segment
order by product_count desc;


-- 4.Follow-up: Which segment had the most increase in unique products in
--   2021 vs 2020?
WITH CTE1 AS 
	(SELECT P.segment AS A , COUNT(DISTINCT(FS.product_code)) AS B 
    FROM dim_product P, fact_sales_monthly FS
    WHERE P.product_code = FS.product_code
    GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = "2020"),
CTE2 AS
    (
	SELECT P.segment AS C , COUNT(DISTINCT(FS.product_code)) AS D 
    FROM dim_product P, fact_sales_monthly FS
    WHERE P.product_code = FS.product_code
    GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = "2021"
    )     
    
SELECT CTE1.A AS segment, CTE1.B AS product_count_2020, CTE2.D AS product_count_2021, (CTE2.D-CTE1.B) AS difference  
FROM CTE1, CTE2
WHERE CTE1.A = CTE2.C
order by difference desc;


-- 5.Get the products that have the highest and lowest manufacturing costs.
SELECT F.product_code, P.product, F.manufacturing_cost 
FROM fact_manufacturing_cost F JOIN dim_product P
ON F.product_code = P.product_code
WHERE manufacturing_cost
IN (
	(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost),
    (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
    ) 
ORDER BY manufacturing_cost DESC ;


-- 6.Generate a report which contains the top 5 customers who received an
--   average high pre_invoice_discount_pct for the fiscal year 2021 and in the
--   Indian market.
select c.customer_code, c.customer, pid.pre_invoice_discount_pct
from fact_pre_invoice_deductions pid
join dim_customer c on c.customer_code=pid.customer_code
where pid.fiscal_year="2021" and market="India"
group by c.customer_code, pid.pre_invoice_discount_pct, c.customer
having pid.pre_invoice_discount_pct>(select avg(pre_invoice_discount_pct) from fact_pre_invoice_deductions)
order by pid.pre_invoice_discount_pct desc
limit 5;


-- 7.Get the complete report of the Gross sales amount for the customer “Atliq
--   Exclusive” for each month. This analysis helps to get an idea of low and
--   high-performing months and take strategic decisions.
select monthname(fsm.date) Month, year(fsm.date) Year, round(sum(fgp.gross_price*fsm.sold_quantity)/1000000,2) as Gross_sales_Amount_mln
from fact_sales_monthly fsm 
join fact_gross_price fgp on fsm.product_code=fgp.product_code
join dim_customer c on c.customer_code=fsm.customer_code
where customer="Atliq Exclusive"
group by date,fsm.fiscal_year
order by fsm.fiscal_year;


-- 8.In which quarter of 2020, got the maximum total_sold_quantity?
select quarter(date), year(date), sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where year(date)="2020"
group by quarter(date), year(date)
order by total_sold_quantity desc;


-- 9.Which channel helped to bring more gross sales in the fiscal year 2021
--   and the percentage of contribution?
select channel, round(sum(gross_price)/1000000,2) as gross_sales_mln
from dim_customer c
join fact_sales_monthly fsm on c.customer_code=fsm.customer_code
join fact_gross_price gp on gp.product_code=fsm.product_code
where gp.fiscal_year=2021
group by channel
order by gross_sales_mln desc;


-- 10.Get the Top 3 products in each division that have a high
--    total_sold_quantity in the fiscal_year 2021?
with ranked_products as
(
	with top_sold_products as
    (select segment,
			product,
            sum(sold_quantity) as total_sold_quantity
	 from dim_product p
     join fact_sales_monthly fsm
     on p.product_code=fsm.product_code
     where fiscal_year=2021
     group by segment, product
     order by total_sold_quantity
	)
select *,
	   row_number() over(
       partition by segment
       order by total_sold_quantity) as rank_order
from top_sold_products
)

select *
from ranked_products
where rank_order<=3;
