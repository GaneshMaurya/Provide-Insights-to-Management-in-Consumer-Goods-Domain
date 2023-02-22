# Test
select * from gdb023.dim_customer where customer = 'croma';

select
s.fiscal_year,
ROUND(SUM(g.gross_price * s.sold_quantity)/1000000,2) as yearly_gross_sales
from gdb023.fact_sales_monthly s
join gdb023.fact_gross_price g
on 
g.fiscal_year=s.fiscal_year and
g.product_code=s.product_code
where
customer_code=90002002
group by fiscal_year
order by fiscal_year;

# Chhecking Outputs of Tables
select * from gdb023.dim_customer limit 10;
select * from gdb023.dim_product limit 10;
select * from gdb023.fact_gross_price limit 10;
select * from gdb023.fact_manufacturing_cost limit 10;
select * from gdb023.fact_pre_invoice_deductions limit 10;
select * from gdb023.fact_sales_monthly limit 10;

# Q1
select customer, market, region 
from gdb023.dim_customer 
where customer = 'Atliq Exclusive' and region = 'APAC';

select distinct(market) 
from gdb023.dim_customer 
where customer = 'Atliq Exclusive' and region = 'APAC';

# Q2
select * from gdb023.fact_sales_monthly;

select (select count(distinct(product_code))
from gdb023.fact_sales_monthly 
where fiscal_year = 2020) as unique_products_2020,
(select count(distinct(product_code))
from gdb023.fact_sales_monthly 
where fiscal_year = 2021) as unique_products_2021;

select unique_products_2020, unique_products_2021, 
round(((unique_products_2021 - unique_products_2020)/unique_products_2020)*100, 2) as percentage_chg
from (
	select
    count(distinct(case when fiscal_year = 2020 then product_code end)) as unique_products_2020,
    count(distinct(case when fiscal_year = 2021 then product_code end)) as unique_products_2021
    from gdb023.fact_sales_monthly
) as innerquery;

# Q4
select * from gdb023.dim_product;

select segment, count(product_code) as product_count
from gdb023.dim_product 
group by segment order by product_count desc;

select segment, unique_products_2020, unique_products_2021, 
(unique_products_2021 - unique_products_2020) as difference
from (
	select p.segment, 
    count(distinct(case when m.fiscal_year = 2020 then m.product_code end)) as unique_products_2020,
    count(distinct(case when m.fiscal_year = 2021 then m.product_code end)) as unique_products_2021
    from gdb023.dim_product p join gdb023.fact_sales_monthly m 
    on p.product_code = m.product_code
    group by p.segment 
) as innerquery;

# Q5
select * from gdb023.fact_manufacturing_cost;

select c.product_code, p.product, c.manufacturing_cost
from gdb023.dim_product p join gdb023.fact_manufacturing_cost c
on p.product_code = c.product_code order by c.manufacturing_cost desc limit 1;

select c.product_code, p.product, c.manufacturing_cost
from gdb023.dim_product p join gdb023.fact_manufacturing_cost c
on p.product_code = c.product_code order by c.manufacturing_cost asc limit 1;

# Q6
select distinct(customer) from gdb023.dim_customer;
select customer_code, (pre_invoice_discount_pct) as average from gdb023.fact_pre_invoice_deductions 
group by customer_code order by average desc limit 5;

select c.customer_code, c.customer, round(pre_invoice_discount_pct*100, 2) as pre_invoice_discount_pct 
from gdb023.dim_customer c 
join (
	select customer_code, avg(pre_invoice_discount_pct) as pre_invoice_discount_pct
    from gdb023.fact_pre_invoice_deductions 
    group by customer_code 
) as t on c.customer_code = t.customer_code
order by pre_invoice_discount_pct desc limit 5;

# Q7
select month(m.date) as month, m.fiscal_year, round(sum(m.sold_quantity*g.gross_price), 2) as gross_sales_amount
from gdb023.fact_sales_monthly m join gdb023.fact_gross_price g 
on m.product_code = g.product_code 
join gdb023.dim_customer c on m.customer_code = c.customer_code
where c.customer = 'Atliq Exclusive' 
group by month, m.fiscal_year 
order by m.fiscal_year, month;

# Q8
select quarter(date) as quarter, fiscal_year, sum(sold_quantity) as total_sold_quantity
from gdb023.fact_sales_monthly 
where fiscal_year = 2020
group by quarter, fiscal_year 
order by total_sold_quantity desc limit 1;

# Q9
select c.channel, round(sum(g.gross_price*m.sold_quantity/1000000), 2) as gross_sales_mln
from gdb023.fact_sales_monthly m join gdb023.fact_gross_price g 
on m.product_code = g.product_code 
join gdb023.dim_customer c on c.customer_code = m.customer_code 
where m.fiscal_year = 2021 
group by c.channel;

# Q10
select * from (select p.division, p.product_code, p.product, sum(m.sold_quantity) as total_sold_quantity, 
rank() over (partition by p.division order by m.sold_quantity desc) as rank_order
from gdb023.dim_product p, gdb023.fact_sales_monthly m 
where p.product_code = m.product_code
and m.fiscal_year = 2021) as t where t.rank_order <= 3 
group by 1, 2;

select distinct(product) from gdb023.dim_product;

select p.division, p.product_code, p.product, m.sold_quantity as total_sold_quantity
from gdb023.dim_product p, gdb023.fact_sales_monthly m 
where p.product_code = m.product_code 
group by p.division, p.product_code, p.product
order by m.sold_quantity desc;

select * from (select p.division, p.product_code, p.product, total_sold_quantity, 
rank() over (partition by p.division order by total_sold_quantity desc) as rank_order 
from gdb023.dim_product p join (
	select p.division, m.product_code, sum(m.sold_quantity) as total_sold_quantity
    from gdb023.fact_sales_monthly m join gdb023.dim_product p 
    on p.product_code = m.product_code
    where m.fiscal_year = 2021
    group by 1, 2
) as m on p.product_code = m.product_code) as t 
where t.rank_order <= 3;