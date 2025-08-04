select *
from customers ;

select *
from date ;

select *
from markets ;

select *
from products ;

select *
from transactions ;


-- EASY

-- 1. List all the customer names and their types.

select custmer_name as customer_name , customer_type
from customers ;

-- 2. Show all the transactions that occurred in Chennai.

select t.product_code , t.customer_code , t.order_date , t.sales_qty , t.sales_amount , t.profit_margin , m.markets_name
from transactions as t 
left join markets as m
on t.market_code = m.markets_code
where m.markets_name = 'Chennai' ;

-- 3. Display all the product codes and their types.

select *
from products ;

-- 4. Show the transactions where the sales amount is greater than 1000.

select * 
from transactions
where sales_amount > 1000
limit 10 ;

-- 5. What are the different zones in the markets table?

select zone
from markets ;

-- MEDIUM 

-- 1. Calculate the total sales amount for each customer.

select customer_code , sum(sales_amount) as total_sales
from transactions
group by customer_code
order by customer_code;

-- 2. What is the total profit margin for each product type?

select coalesce(p.product_type, 'unknown') , round(sum(t.profit_margin),2) as total_profit_margin
from transactions as t
left join products as p
on t.product_code = p.product_code
group by p.product_type
order by p.product_type ;

-- 3. Find the average sales quantity for each market.

select m.markets_name , round(avg(t.sales_qty),2)  as average_sales_quantity
from transactions as t 
left join markets as m
on t.market_code = m.markets_code
group by t.market_code 
order by average_sales_quantity desc;

-- 4. List the top 5 customers by sales amount.
select  c.custmer_name , sum(t.sales_amount) as total_sales_amount , 
rank() over(order by sum(t.sales_amount) desc) as top_5_rank
from transactions as t
left join customers as c
on t.customer_code = c.customer_code
group by t.customer_code
order by total_sales_amount desc
limit 5
;

-- 5. How many transactions were there in each year?

select year(order_date) as order_year , count(product_code) as number_of_transactions 
from transactions
group by order_year
order by order_year ;

-- HARD

-- 1. What is the total profit margin for each customer type in each zone?


select c.customer_type , round(sum(profit_margin),2) as total_profit_margin , m.zone
from transactions as t
left join customers as c
on t.customer_code = c.customer_code
left join markets as m
on t.market_code = m.markets_code
group by c.customer_type , m.zone
order by c.customer_type , m.zone
;

-- 2. Find the customer who has made the most purchases (in terms of quantity) and the total amount they've spent.

select *
from
(
select customer_code , sum(sales_qty) as total_purchases , sum(sales_amount) as total_amount_spent , 
rank () over (order by sum(sales_qty) desc) as rank_p
from transactions
group by customer_code 
) as mm
where rank_p = 1 ;

-- 3. For each market, find the product with the highest sales amount.

WITH MarketProductSales AS (
	select t.market_code , t.product_code , sum(t.sales_amount) as total_sales
	from transactions as t
	group by  t.market_code , t.product_code 
) ,
RankedSales AS (
	select mps.market_code , mps.product_code , mps.total_sales , 
	rank() over(partition by mps.market_code order by mps.total_sales desc) as sales_rank 
    from MarketProductSales as mps )

select rs.market_code , m.markets_name , rs.product_code , rs.total_sales , m.zone  
from RankedSales as rs
left join markets as m 
on rs.market_code = m.markets_code
where sales_rank = 1
;

-- 4. What is the month-over-month growth rate of sales?

with MonthlySales as
(
select  year(order_date) as order_year , month(order_date) as order_month , sum(sales_amount) as total_sales 
from transactions 
group by order_year , order_month
order by order_year , order_month
),
SalesWithLag as
(
select order_year , order_month , total_sales , 
lag(total_sales , 1 , 0 ) over (order by order_year , order_month ) as previous_month_sales
from MonthlySales
)
select order_year, order_month , total_sales , previous_month_sales , 
round(( ( total_sales - previous_month_sales ) / previous_month_sales ) * 100 , 2 ) as mom_growth_percentage
from SalesWithlag
;



-- 5. Which are the top 3 most profitable products?


select *
from
(select product_code , round(sum(profit_margin),2) as total_profit_margin ,
rank () over (order by round(sum(profit_margin),2) desc ) as profit_rank
from transactions
group by product_code
order by total_profit_margin desc ) as mm
where mm.profit_rank < 4
;