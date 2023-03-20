-- 1. В каких городах больше одного аэропорта?

select c_a.city , c_a.c_s as count_airports -- выбираем данные из подзапроса
from (
	select city, count(*) c_s  --подзапрос к таблице airport, берущий название городо и относящиеся к нему кол-во записей
	from airports 
	group by city -- группировка по городам
	) c_a
where c_a.c_s > 1 -- условие, возвращающее записи, где c_a.c_s > 1

-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

select distinct fv.departure_airport_name max_range_airports
from flights_v fv 
right join (
	select a.aircraft_code -- подзапрос в join, возвращающий самолет с максимальной дальностью полета
		from aircrafts a
		order by a."range" desc 
		limit 1
	) mr on mr.aircraft_code = fv.aircraft_code --правое соединение, возвращающее аэропоты, из корых совершаются рейсы с максимальной дальностью
	
-- 3. Вывести 10 рейсов с максимальным временем задержки вылета

select flight_no, route, delay 
from (
	select fv.flight_no, concat(fv.departure_airport_name, ' - ', fv.arrival_airport_name) route,
	fv.actual_departure - fv.scheduled_departure as delay --вычитание фактического времени вылета из запланированного
	from flights_v fv
	) md
where delay is not null -- исключение null значений
order by delay desc -- сортировка по убыванию
limit 10 -- вывод первых 10 значений

-- 4. Были ли брони, по которым не были получены посадочные талоны? 
select b.book_ref bookings_without_boarding_passes 
from bookings b 
join tickets t on t.book_ref = b.book_ref -- соединение таблиц бронирования и таблиц билетов
left join boarding_passes bp on bp.ticket_no = t.ticket_no -- left jon между таблицей билетов и таблицей посадочных талонов
where bp.ticket_no is null -- условие, оставляюее только значения, которые есть в первой таблице, но нет во второй
group by b.book_ref -- группировка по бронированиям
 
select distinct t.book_ref bookings_without_boarding_passes
from tickets t 
left join boarding_passes bp on bp.ticket_no = t.ticket_no -- left jon между таблицей билетов и таблицей посадочных талонов
where bp.ticket_no is null -- условие, оставляюее только значения, которые есть в первой таблице, но нет во второй

-- 5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.

with cte_1 as
	(
	select f.flight_id, f.flight_no, f.aircraft_code, count(bp.seat_no) count_sold_seats,
	f.departure_airport, date_trunc('day', f.actual_departure) day_flight   
	from flights f 
	join boarding_passes bp on bp.flight_id = f.flight_id
	group by f.flight_id 
	),
	cte_2 as 
	(
	select s.aircraft_code, count(s.seat_no) count_all_seats
	from seats s 
	group by s.aircraft_code 
	)
select flight_no, count_all_seats-count_sold_seats free_seats, 
concat(round(((count_all_seats-count_sold_seats)::numeric/count_all_seats::numeric)*100,2), '%') percentage_free_seats,
sum(count_sold_seats) over (partition by departure_airport, day_flight order by flight_id) departed_passengers, 
departure_airport airport, day_flight::date  
from cte_1
join cte_2 on cte_2.aircraft_code = cte_1.aircraft_code
order by departure_airport, day_flight

-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.

with cte_1 as -- создаем CTE
	( 
	select f.flight_no, f.aircraft_code, a.model, 
	concat(round((count(f.flight_id) over (partition by f.aircraft_code)::numeric/count(f.flight_id) over ()::numeric)*100,2),'%') cf_percent, -- с помощь оконных функций считаем процент перелетов по типам самолетов
	row_number () over (partition by f.aircraft_code) rn -- нумеруем данные по типам самолетов, чтобы забрать по одной строке
	from flights f
	join aircrafts a on a.aircraft_code = f.aircraft_code -- присоединяем таблицу aircrafts, чтобы забрать из нее модели самолетов
	)
select aircraft_code, model, cf_percent percentage_of_all -- выводим данные из cte_1
from cte_1 
where rn = 1 -- условие, позволяющее забрать по одной строке для каждого типа самолетов

-- 7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
 

with cte_b as ( --создаем cte, в котором выводим все уникальные рейсы и стоимость перелета в них в классе бизнес
	select  distinct f.departure_airport da, f.arrival_airport aa, tf.amount  
	from flights f
	join ticket_flights tf on tf.flight_id = f.flight_id and tf.fare_conditions = 'Business'
	),
	cte_e as (  --создаем cte, в котором выводим все уникальные рейсы и стоимость перелета в них в классе эконом
	select  distinct f.departure_airport da, f.arrival_airport aa, tf.amount  
	from flights f
	join ticket_flights tf on tf.flight_id = f.flight_id and tf.fare_conditions = 'Economy'
	),
	cte_c as(  --создаем cte, в котором проверяем, для каких рейсов бизнес дешевле эконома
	select cte_b.amount, cte_e.amount,
	case 
		when cte_b.amount < cte_e.amount then '?!'
		else 'ok'
	end comparison
	from cte_b
	join cte_e on cte_b.da = cte_e.da and cte_b.aa = cte_e.aa
	)
select * from cte_c -- выводим рейсы, в которых бизнес дешевле эконома
where comparison = '?!' -- таких не нашлось

-- 8. Между какими городами нет прямых рейсов?

create view city2 as --создаем представление
	select distinct fv.departure_city, fv.arrival_city  --из представления flights_v берем уникальные города вылета и прилета
 	from flights_v fv;
select a.city, a2.city  
from airports a 
cross join airports a2 -- делаем декартово произведение таблицы airports 
where a.city != a2.city --для получения всех возможных пар городов; исключаем пары с одним и тем же городом
except -- вычитаем из декартова произведения
select * from city2 -- все пары из представления, получаем только пары городов, между которыми нет прямых рейсов



-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы *

select distinct fv.departure_airport_name, fv.arrival_airport_name,  a2."range" max_distance_aircraft, -- забираем данные о названия аэропортов и максимальной возможной длинне полета
round((acos(sind(a.latitude) * sind(a1.latitude) + cosd(a.latitude) * cosd(a1.latitude) * cosd(a.longitude - a1.longitude)) * 6371)::dec, 2) distance_between_airports, -- вычисления по формуле
case -- условие case, которое сравнивает максимальную возможную длинну полета самолета с посчитанному по формуле расстоянию между аэропортами
	when a2."range" >= round((acos(sind(a.latitude) * sind(a1.latitude) + cosd(a.latitude) * cosd(a1.latitude) * cosd(a.longitude - a1.longitude)) * 6371)::dec, 2) then 'Долетит'
	else 'Не повезло:('
end  "yes_or_no"
from flights_v fv 
join airports a on a.airport_code = fv.departure_airport -- присоединение таблицы aiports для получения координат аэропорта отправления
join airports a1 on a1.airport_code = fv.arrival_airport  -- присоединение таблицы aiports для получения координат аэропорта прибытия
join aircrafts a2 on a2.aircraft_code = fv.aircraft_code -- присоединение таблицы aircrafts для получения максимальной дальности полета самолета
