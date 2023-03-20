--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

select concat(c.first_name, ' ', c.last_name) as customer_name, a.address, c2.city as city, c3.country as country  
from customer c 
left join address a using(address_id)
left join city c2 using (city_id)
left join country c3 using (country_id)


--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select s.store_id "ID магазина", count(c.customer_id) "Количество покупателей"
from store s 
left join customer c using (store_id)
group by s.store_id 
order by count(c.customer_id) desc 

--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.


select s.store_id "ID магазина", count(c.customer_id) "Количество покупателей"
from store s 
left join customer c using (store_id)
group by s.store_id 
having count(c.customer_id) > 300
order by count(c.customer_id) desc 

-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.


select s.store_id "ID магазина", count(c.customer_id) "Количество покупателей", c2.city "Город",
concat(s2.last_name, '_', s2.first_name) "Сотрудник" 
from store s 
left join customer c on c.store_id = s.store_id 
left join staff s2 on s2.store_id =s.store_id 
left join address a on a.address_id = s.address_id 
left join city c2 on c2.city_id = a.city_id 
group by s.store_id, concat(s2.last_name, '_', s2.first_name), c2.city  
having count(c.customer_id) > 300
order by count(c.customer_id) desc 


--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select concat(c.first_name, ' ', c.last_name) "Покупатель", count(r.rental_id)  
from customer c 
left join rental r using (customer_id)
group by c.customer_id 
order by count(r.rental_id) desc 


--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма


select concat(c.first_name, ' ', c.last_name) "Покупатель", count(pr.inventory_id) "Кол-во фильмов",
sum(pr.amount)::int "Общая стоимость платежей", 
min(pr.amount) "Минимальная стоимость платежа", max(pr.amount) "Максимальная стоимость платежа"   
from customer c 
left join (
select r.customer_id, r.inventory_id, p.amount  
from payment p
left join rental r on p.rental_id = r.rental_id) pr on c.customer_id = pr.customer_id 
group by c.customer_id 
order by count(pr.inventory_id) desc


--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
 
select c.city "Город 1", c2.city "Город 2"
from city c 
cross join city c2 
where c.city_id != c2.city_id and 
c.city != c2.city 


--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
 
select r.customer_id "ID покупателя", round(avg(r.return_date::date - r.rental_date::date),2) 
from rental r
group by r.customer_id 
order by r.customer_id 



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

--без подзапросов
select f.title "Название", f.rating "Рейтинг", c."name" "Жанр", f.release_year "Год выпуска", l."name" "Язык",  count(r.rental_id) "Количество аренд", sum(p.amount) "Общая стоимость аренды" 
from rental r 
left join inventory i using (inventory_id)
left join film f using(film_id)
left join film_category fc using (film_id)
left join category c using (category_id)
left join "language" l using (language_id)
left join payment p using (rental_id)
group by f.film_id, l."name", c."name"  
order by f.title 

--с подзапросами
select h.title "Название", h.rating "Рейтинг", g."name" "Жанр", h.release_year "Год выпуска", l."name" "Язык",  count(r.rental_id) "Количество аренд", sum(p.amount) "Общая стоимость аренды" 
from rental r 
left join (
select f2.title, i2.inventory_id, f2.rating, f2.release_year, f2.film_id, f2.language_id  
from inventory i2 
left join film f2 on i2.film_id =f2.film_id ) h on r.inventory_id = h.inventory_id 
left join (
select c.name, fc.film_id  
from film_category fc 
left join category c on fc.category_id = c.category_id
) g on h.film_id = g.film_id 
left join "language" l on h.language_id = l.language_id 
left join payment p using (rental_id)
group by h.film_id, h.title,  h.rating, h.release_year,  l."name", g."name"  
order by h.title 


--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.

select f.title "Название", f.rating "Рейтинг", c."name" "Жанр", f.release_year "Год выпуска", l."name" "Язык",  count(r.rental_id) "Количество аренд", sum(p.amount) "Общая стоимость аренды" 
from rental r 
right join inventory i using (inventory_id)
right join film f using(film_id)
left join film_category fc using (film_id)
left join category c using (category_id)
left join "language" l using (language_id)
left join payment p using (rental_id)
group by f.film_id, l."name", c."name" 
having count(r.rental_id) = 0
order by f.title


--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select p.staff_id, count(p.payment_id)"Количество продаж", 
case  
	when count(p.payment_id) > 7300 then 'Да'
	else  'Нет'
end "Премия"
from payment p
group by p.staff_id 
