
--1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, sum(menu.price) from dannys_diner.sales 
inner join dannys_diner.menu on 
sales.product_id = menu.product_id
group by 1 
order by 1;

--2.How many days has each customer visited the restaurant?

select sales.customer_id, count(distinct order_date) from dannys_diner.sales 
group by 1
order by 1;

--3.What was the first item(s) from the menu purchased by each customer?
with sample as (
select sales.customer_id, menu.product_name,sales.order_date, 
rank() over (partition by sales.customer_id order by sales.order_date) as item_rank
from dannys_diner.sales inner join dannys_diner.menu
on sales.product_id = menu.product_id
)
select distinct customer_id, product_name from sample
where item_rank =1;

--4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select menu.product_name, count(sales.*) as total_purchase from dannys_diner.sales 
inner join dannys_diner.menu
on sales.product_id= menu.product_id
group by 1
order by total_purchase desc 
limit 1;

--5. Which item(s) was the most popular for each customer?

with customer_cte as(
select sales.customer_id, count(sales.*) as total_purchase, menu.product_name, dense_rank() over(partition by sales.customer_id order by count(sales.*) desc) as item_rank 
from dannys_diner.sales inner join dannys_diner.menu on sales.product_id = menu.product_id
group by 1,3
)
select * from customer_cte
where item_rank =1;
;

--6.Which item was purchased first by the customer after they became a member and what date was it? (including the date they joined)

with customer_cte as (
select sales.customer_id, count(sales.*) as total_purchase, sales.order_date, menu.product_name, members.join_date,rank() over ( partition by sales.customer_id order by sales.order_date) as rank
from dannys_diner.sales inner join dannys_diner.menu on sales.product_id = menu.product_id 
inner join dannys_diner.members on sales.customer_id = members.customer_id
where sales.order_date >= members.join_date ::DATE
group by 1,3,4,5
)

select customer_id,order_date,product_name from customer_cte
where rank = 1;

--7.Which menu item(s) was purchased just before the customer became a member and when?

with purchase_cte as (
select sales.customer_id,count(sales.*)as total, sales.order_date,menu.product_name, members.join_date, rank() over (partition by sales.customer_id order by sales.order_date desc) as rank
from dannys_diner.sales inner join dannys_diner.menu on 
sales.product_id = menu.product_id
inner join dannys_diner.members on 
sales.customer_id = members.customer_id
where sales.order_date < members.join_date
group by 1,3,4,5
) 
select customer_id,total, order_date,product_name,join_date
from purchase_cte 
where rank = 1;

--8.What is the number of unique menu items and total amount spent for each member before they became a member?

select sales.customer_id, count(distinct sales.product_id) as count, sum(menu.price) 
from dannys_diner.sales inner join dannys_diner.menu on 
sales.product_id = menu.product_id
inner join dannys_diner.members on 
sales.customer_id = members.customer_id
where sales.order_date < members.join_date::date 
group by 1;

--9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select
  sales.customer_id,
  sum (
    case
      when menu.product_name = 'sushi' then menu.price * 20
      else menu.price * 10
    end
  ) as points
from
  dannys_diner.menu
  inner join dannys_diner.sales on sales.product_id = menu.product_id
group by
  customer_id
order by
  points desc;
--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select
  sales.customer_id,
  sum (
    case
      when sales.order_date between members.join_date
      and members.join_date + interval '6days' then menu.price * 20
      when menu.product_name = 'sushi' then menu.price * 20
      else menu.price * 10
    end
  ) as points
from
  dannys_diner.menu
  inner join dannys_diner.sales on sales.product_id = menu.product_id
  inner join dannys_diner.members on sales.customer_id = members.customer_id
where
  sales.order_date < '2021-01-31'
group by 1;

