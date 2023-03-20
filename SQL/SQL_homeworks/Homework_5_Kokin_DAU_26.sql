--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим 
--так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

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


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.

select customer_id, payment_id, payment_date, amount, 
lag(amount, 1, 0.) over (partition by customer_id order by payment_date) as last_amount 
from payment



--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select customer_id, payment_id, payment_date, amount, 
(lead(amount, 1) over (partition by customer_id order by payment_date)) - amount as difference 
from payment



--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

with CTE_last_value as (
select customer_id, payment_id, payment_date,
first_value(amount) over (partition by customer_id order by payment_date desc) as "Последний платёж",
row_number() over (partition by customer_id order by payment_date desc)
from payment
)
select customer_id, payment_id, payment_date, "Последний платёж"
from CTE_last_value
where row_number = 1

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.


select staff_id, payment_date::date, sum(amount) sum_per_mounth, 
sum(sum(amount)) over (partition by staff_id order by payment_date::date)
from payment
where payment_date::date  between '01.08.2005' and '31.08.2005'
group by staff_id, payment_date::date 


--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

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


--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

with CTE_cuntry_customer as (
	select c.country as "Страна", c3.first_name ||' ' || c3.last_name as "Покупатель", c3.customer_id, r.rental_id 
	from country c
	join city c2 on c2.country_id = c.country_id
	join address a on a.city_id = c2.city_id 
	join customer c3 on c3.address_id = a.address_id
	join rental r on r.customer_id  = c3.customer_id 
	join payment p on p.rental_id = r.rental_id 
	order by c.country  
	),
	CTE_1 as (
	select "Страна", "Покупатель", row_number () over (partition by "Страна", "Покупатель") t, rental_id 
	from CTE_cuntry_customer
	)
	select "Страна", "Покупатель", first_value (t) over (partition by "Страна" order by t desc) f, t 
	from cte_1
	order by "Страна", "Покупатель"
	
	
	with CTE_cuntry as (
	select c.country as "Страна", a.address_id 
	from country c
	join city c2 on c2.country_id = c.country_id
	join address a on a.city_id = c2.city_id 
	order by c.country  
	),
	CTE_1 as (
	select c3.first_name ||' ' || c3.last_name as "Покупатель", a.address_id, 
	count(r.rental_id) over (partition by c3.customer_id),
	row_number () over (partition by c3.customer_id) t
	from customer c3 
	join address a on a.address_id = c3.address_id 
	join rental r on r.customer_id  = c3.customer_id
	)
	select "Страна", "Покупатель"
	from CTE_cuntry
	left join CTE_1 on CTE_1.address_id = CTE_cuntry.address_id
	order by "Страна", "Покупатель"
	
	
 -- как надо было
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

	







