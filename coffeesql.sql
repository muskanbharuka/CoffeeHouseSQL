use coffee_house;

create table city(
	city_id int primary key,
    city_name varchar(50),
    population int,
    estimated_rent int,
    city_rank int
);
select * from city;

create table customers(
	customer_id int primary key,
    customer_name varchar(50),
    city_id int,
    FOREIGN KEY (city_id) REFERENCES city(city_id) ON DELETE CASCADE
);
select * from customers;

create table products (
    product_id int primary key,
    product_name varchar(100) not null,
    price int
);
select * from products;

create table sales(
	sale_id int primary key,
    sale_date date,
    product_id int,
    customer_id int,
    total int check (total>0),
    rating int check (rating between 1 and 5),
    foreign key (product_id) references products(product_id) on delete cascade,
	foreign key (customer_id) references customers(customer_id) on delete cascade
);
select * from sales;

select count(distinct city_id) from city;

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_id,
	city_name ,
	Round((0.25 * population)/1000000,3) as coffee_consumer_in_millions
from city order by 2 desc;

-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select sum(total) as total_revenue_2023_lastQuarter 
from sales
where Year(sale_date) = 2023 and quarter(sale_date)=4;  --  quarter(sale_date)=4 or Month(sale_date) in (10,11,12)

select cty.city_name , 
	sum(total) as total_revenue
from sales s 
join customers c on s.customer_id = c.customer_id
join city ct on c.city_id = ct.city_id 
where Year(s.sale_date) = 2023 and quarter(s.sale_date)=4
group by 1
order by 2 desc;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
select p.product_name,
	count(s.product_id) as units_sold 
from sales s
join products p
on s.product_id = p.product_id
group by s.product_id
order by 2 desc;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

select ct.city_name ,
	round(avg(s.total),2) as avg_sale_city,
	count(distinct s.customer_id) as count_customers,
	round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale_customer
from sales s 
join customers c on s.customer_id = c.customer_id
join city ct on c.city_id = ct.city_id 
group by ct.city_id
order by avg_sale_city;

-- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)   -- Unique consumers bhi nikalne hai

select
	ct.city_name,
    round((ct.population*0.25)/1000000,3) as coffee_consumers_millions,
    count(distinct c.customer_id) as unique_consumers_city
from city ct
join customers c
on ct.city_id = c.city_id
group by c.city_id;

-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
with cte_product_sale as (
	select 	
		ct.city_id,
        ct.city_name,
        p.product_id,
        p.product_name,
        sum(total) as product_revenue,
        Dense_Rank() Over(Partition By ct.city_id order by sum(s.total) desc) as product_city_rank
	from sales s
    join products p
    on s.product_id = p.product_id
    join customers c
    on s.customer_id = c.customer_id
    join city ct
    on ct.city_id = c.city_id
    group by 1,2,3,4
)
SELECT city_name, product_name, product_revenue
FROM cte_product_sale
WHERE product_city_rank <= 3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
select * from products;
select distinct product_id from sales; 
select 
	ct.city_name,
    count(distinct c.customer_id) as unique_customer_city
from city ct
join customers c
on ct.city_id = c.city_id
join sales s
on c.customer_id = s.customer_id
where s.product_id>=1 and s.product_id <=14 
group by ct.city_id
order by unique_customer_city  desc;

-- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

select
	ct.city_name,
    ct.estimated_rent,
    sum(s.total)/count(distinct c.customer_id) as avg_sale_per_cust,
    ct.estimated_rent / count(distinct c.customer_id) as avg_rent_per_cust
from city ct
join customers c
on ct.city_id = c.city_id
join sales s
on c.customer_id = s.customer_id
group by ct.city_name,ct.estimated_rent;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city

with cte_month_revenue as (
select ct.city_name,
	DATE_FORMAT(s.sale_date,'%Y-%m') as sale_month,
    SUM(total) as revenue_city_month
from city ct
join customers c
on ct.city_id = c.city_id
join sales s
on c.customer_id = s.customer_id
group by ct.city_id , sale_month
)
select city_name,
	sale_month,
    revenue_city_month,
    LAG(revenue_city_month) OVER(PARTITION BY city_name ORDER BY sale_month) as previous_revenue_month,
    ROUND((revenue_city_month - LAG(revenue_city_month) OVER(PARTITION BY city_name ORDER BY sale_month))/ 
		LAG(revenue_city_month) OVER(PARTITION BY city_name ORDER BY sale_month)*100,2) as revenue_growth_rate
from cte_month_revenue
order by city_name, sale_month;



-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


with cte_city as (
select ct.city_name,
	sum(s.total) as total_revenue,
    count(distinct s.customer_id) as total_customers
from city ct
join customers c
on ct.city_id = c.city_id
join sales s
on c.customer_id = s.customer_id
group by 1
),
cte_rent as (
select 	city_name,
	estimated_rent,
	round((population*0.25)/1000000,3) as consumers_in_millions
from city
)
select c.city_name,
	c.total_revenue,
    c.total_customers,
    r.estimated_rent,
    r.consumers_in_millions
from cte_city c
join cte_rent r
on c.city_name = r.city_name
order by 2 desc;
    
-- 1. Pune as highest tottal_revenue and decent customers with lesser rent
-- 2. Delhi has 68 total_customers and most customers in million which can grow up 
-- 3. Jaipur as it lists itself in top 5 amongst revenue and highest in total customers with low rent 