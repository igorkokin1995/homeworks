--=============== ������ 5. ������ � POSTGRESQL =======================================
--= �������, ��� ���������� ���������� ������ ���������� � ������� ����� PUBLIC===========
SET search_path TO public;

--======== �������� ����� ==============

--������� �1
--�������� ������ � ������� payment � � ������� ������� ������� �������� ����������� ������� �������� ��������:
--������������ ��� ������� �� 1 �� N �� ����
--������������ ������� ��� ������� ����������, ���������� �������� ������ ���� �� ����
--���������� ����������� ������ ����� ���� �������� ��� ������� ����������, ���������� ������ 
--���� ������ �� ���� �������, � ����� �� ����� ������� �� ���������� � �������
--������������ ������� ��� ������� ���������� �� ��������� ������� �� ���������� � ������� 
--���, ����� ������� � ���������� ��������� ����� ���������� �������� ������.
--����� ��������� �� ������ ����� ��������� SQL-������, � ����� ���������� ��� ������� � ����� �������.

select customer_id, payment_id, payment_date,
row_number() over (order by payment_date) 
from payment; 

select customer_id, payment_id, payment_date,
row_number() over (partition by customer_id order by payment_date) 
from payment


select customer_id, payment_id, payment_date, amount, 
sum(amount) over (partition by customer_id order by amount, payment_date) 
from (
	select customer_id, payment_id, payment_date, amount
	from payment
	order by customer_id, payment_date, amount, payment_id
) t

 

select customer_id, payment_id, payment_date, amount,
dense_rank() over (partition by customer_id order by amount desc) 
from payment


--������� �2
--� ������� ������� ������� �������� ��� ������� ���������� ��������� ������� � ��������� 
--������� �� ���������� ������ �� ��������� �� ��������� 0.0 � ����������� �� ����.

select customer_id, payment_id, payment_date, amount, 
lag(amount, 1, 0.) over (partition by customer_id order by payment_date) as last_amount 
from payment



--������� �3
--� ������� ������� ������� ����������, �� ������� ������ ��������� ������ ���������� ������ ��� ������ ��������.

select customer_id, payment_id, payment_date, amount, 
(lead(amount, 1) over (partition by customer_id order by payment_date)) - amount as difference 
from payment



--������� �4
--� ������� ������� ������� ��� ������� ���������� �������� ������ � ��� ��������� ������ ������.

with CTE_last_value as (
select customer_id, payment_id, payment_date,
first_value(amount) over (partition by customer_id order by payment_date desc) as "��������� �����",
row_number() over (partition by customer_id order by payment_date desc)
from payment
)
select customer_id, payment_id, payment_date, "��������� �����"
from CTE_last_value
where row_number = 1

--======== �������������� ����� ==============

--������� �1
--� ������� ������� ������� �������� ��� ������� ���������� ����� ������ �� ������ 2005 ���� 
--� ����������� ������ �� ������� ���������� � �� ������ ���� ������� (��� ����� �������) 
--� ����������� �� ����.


select staff_id, payment_date::date, sum(amount) sum_per_mounth, 
sum(sum(amount)) over (partition by staff_id order by payment_date::date)
from payment
where payment_date::date  between '01.08.2005' and '31.08.2005'
group by staff_id, payment_date::date 


--������� �2
--20 ������� 2005 ���� � ��������� ��������� �����: ���������� ������� ������ ������� �������
--�������������� ������ �� ��������� ������. � ������� ������� ������� �������� ���� �����������,
--������� � ���� ���������� ����� �������� ������

with CTE_sale as(
select customer_id, payment_date,
row_number() over (order by payment_date) num_pay
from(
	select customer_id, payment_date
	from payment
	where payment_date::date = '20.08.2005'
	) day_sale
)
select customer_id, payment_date, num_pay
from CTE_sale 
where num_pay::text like '%00' 


--������� �3
--��� ������ ������ ���������� � �������� ����� SQL-�������� �����������, ������� �������� ��� �������:
-- 1. ����������, ������������ ���������� ���������� �������
-- 2. ����������, ������������ ������� �� ����� ������� �����
-- 3. ����������, ������� ��������� ��������� �����

with CTE_cuntry_customer as (
	select c.country as "������", c3.first_name ||' ' || c3.last_name as "����������", c3.customer_id, r.rental_id 
	from country c
	join city c2 on c2.country_id = c.country_id
	join address a on a.city_id = c2.city_id 
	join customer c3 on c3.address_id = a.address_id
	join rental r on r.customer_id  = c3.customer_id 
	join payment p on p.rental_id = r.rental_id 
	order by c.country  
	),
	CTE_1 as (
	select "������", "����������", row_number () over (partition by "������", "����������") t, rental_id 
	from CTE_cuntry_customer
	)
	select "������", "����������", first_value (t) over (partition by "������" order by t desc) f, t 
	from cte_1
	order by "������", "����������"
	
	
	with CTE_cuntry as (
	select c.country as "������", a.address_id 
	from country c
	join city c2 on c2.country_id = c.country_id
	join address a on a.city_id = c2.city_id 
	order by c.country  
	),
	CTE_1 as (
	select c3.first_name ||' ' || c3.last_name as "����������", a.address_id, 
	count(r.rental_id) over (partition by c3.customer_id),
	row_number () over (partition by c3.customer_id) t
	from customer c3 
	join address a on a.address_id = c3.address_id 
	join rental r on r.customer_id  = c3.customer_id
	)
	select "������", "����������"
	from CTE_cuntry
	left join CTE_1 on CTE_1.address_id = CTE_cuntry.address_id
	order by "������", "����������"
	
	
 -- ��� ���� ����
	with c1 as (
	select c.customer_id, c2.country_id, count(i.film_id), sum(amount), max(r.rental_date)
	from customer c
	join rental r on r.customer_id = c.customer_id
	join inventory i on i.inventory_id = r.inventory_id
	join payment p on p.rental_id = r.rental_id
	join address a on a.address_id = c.address_id
	join city c2 on c2.city_id = a.city_id
	group by c.customer_id, c2.country_id),
c2 as (
	select customer_id, country_id,
		row_number() over (partition by country_id order by count desc) r_c,
		row_number() over (partition by country_id order by sum desc) r_s,
		row_number() over (partition by country_id order by max desc) r_m
	from c1
)
select c.country, c_1.customer_id, c_2.customer_id, c_3.customer_id
from country c
left join c2 c_1 on c_1.country_id = c.country_id and c_1.r_c = 1
left join c2 c_2 on c_2.country_id = c.country_id and c_2.r_s = 1
left join c2 c_3 on c_3.country_id = c.country_id and c_3.r_m = 1

	







