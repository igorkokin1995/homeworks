--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

explain analyze 
select f.film_id ID, f.title "Название", f.special_features  
from film f 
where f.special_features @> array['Behind the Scenes'] 

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

select f.film_id ID, f.title "Название", f.special_features  
from film f 
where 'Behind the Scenes' = any(f.special_features) 

select f.film_id ID, f.title "Название", f.special_features  
from film f 
where array_position(f.special_features, 'Behind the Scenes') is not null 

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

with CTE_sf as (
	select f.film_id ID_film, f.title "Название", f.special_features  
	from film f 
	where array_position(f.special_features, 'Behind the Scenes') is not null 
	)
select concat(c.first_name, ' ', c.last_name) "Покупатель" , count(r.rental_id) "Кол-во фильмов" 
	from CTE_sf
join inventory i on i.film_id = CTE_sf.ID_film
join rental r on r.inventory_id = i.inventory_id
join customer c on c.customer_id = r.customer_id 
group by c.customer_id
order by c.customer_id 


--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.


select concat(c.first_name, ' ', c.last_name) "Покупатель" , count(r.rental_id) "Кол-во фильмов" 
from (
	select f.film_id ID_film, f.title "Название", f.special_features  
	from film f 
	where array_position(f.special_features, 'Behind the Scenes') is not null 
	) t
join inventory i on i.film_id = t.ID_film
join rental r on r.inventory_id = i.inventory_id
join customer c on c.customer_id = r.customer_id 
group by c.customer_id
order by c.customer_id 



--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view BS as
		select concat(c.first_name, ' ', c.last_name) "Покупатель" , count(r.rental_id) "Кол-во фильмов" 
				from (
		select f.film_id ID_film, f.title "Название", f.special_features  
		from film f 
		where array_position(f.special_features, 'Behind the Scenes') is not null 
					) t
		join inventory i on i.film_id = t.ID_film
		join rental r on r.inventory_id = i.inventory_id
		join customer c on c.customer_id = r.customer_id 
		group by c.customer_id
		order by c.customer_id 
with no data

refresh materialized view BS 

select * from BS



--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее

explain analyze --0.628 
select f.film_id ID, f.title "Название", f.special_features  
from film f 
where f.special_features @> array['Behind the Scenes'] 

explain analyze --0.532 Самый быстрый
select f.film_id ID, f.title "Название", f.special_features  
from film f 
where 'Behind the Scenes' = any(f.special_features) 

explain analyze --0.620 
select f.film_id ID, f.title "Название", f.special_features  
from film f 
where array_position(f.special_features, 'Behind the Scenes') is not null 

--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса

explain analyze --14.775
with CTE_sf as (
	select f.film_id ID_film, f.title "Название", f.special_features  
	from film f 
	where array_position(f.special_features, 'Behind the Scenes') is not null 
	)
select concat(c.first_name, ' ', c.last_name) "Покупатель" , count(r.rental_id) "Кол-во фильмов" 
	from CTE_sf
join inventory i on i.film_id = CTE_sf.ID_film
join rental r on r.inventory_id = i.inventory_id
join customer c on c.customer_id = r.customer_id 
group by c.customer_id
order by c.customer_id 

explain analyze --14.664
select concat(c.first_name, ' ', c.last_name) "Покупатель" , count(r.rental_id) "Кол-во фильмов" 
from (
	select f.film_id ID_film, f.title "Название", f.special_features  
	from film f 
	where array_position(f.special_features, 'Behind the Scenes') is not null 
	) t
join inventory i on i.film_id = t.ID_film
join rental r on r.inventory_id = i.inventory_id
join customer c on c.customer_id = r.customer_id 
group by c.customer_id
order by c.customer_id

-- скость одинаковая, стоимость тож 784.02

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии
explain analyze -- coast 1090, time 84.266
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.

select staff_id, film_id, title, amount, payment_date, customer_last_name, customer_first_name 
from (
	select s.staff_id, p.payment_id, p.payment_date, f.film_id, f.title, p.amount, c.last_name customer_last_name, c.first_name customer_first_name,
	row_number () over (partition by s.staff_id order by p.payment_date) n  
	from staff s 
	join payment p on p.staff_id = s.staff_id
	join rental r on r.rental_id = p.rental_id 
	join inventory i on i.inventory_id = r.inventory_id
	join film f on f.film_id = i.film_id
	join customer c on c.customer_id = r.customer_id 
	order by s.staff_id, p.payment_date  
	) t 
where n = 1	




--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день

with cte_1 as (
	select s2.store_id, r.rental_id, r.rental_date::date,
	count(r.rental_id) over (partition by s2.store_id, r.rental_date::date) c_f,
	sum(amount) over (partition by s2.store_id, r.rental_date::date) s_a
	from rental r 
	join staff s on s.staff_id = r.staff_id 
	join store s2 on s2.manager_staff_id = s.staff_id
	join payment p on p.rental_id = r.rental_id 
	order by s2.store_id, c_f desc  
	),
	cte_2 as (
	select store_id, rental_date::date, c_f, s_a,
	row_number () over (partition by store_id order by c_f desc) r_n,
	row_number () over (partition by store_id order by s_a) r_s
	from cte_1
	)
select s3.store_id "ID магазина", ct2.rental_date::date "День MAX count", ct2.c_f "Count",
		ct3.rental_date::date "День MIN amount", ct3.s_a "Amount"
from store s3 
left join cte_2 ct2 on ct2.store_id = s3.store_id and ct2.r_n = 1
left join cte_2 ct3 on ct3.store_id = s3.store_id and ct3.r_s = 1


