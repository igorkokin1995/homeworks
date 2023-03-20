-- 1. � ����� ������� ������ ������ ���������?

select c_a.city , c_a.c_s as count_airports -- �������� ������ �� ����������
from (
	select city, count(*) c_s  --��������� � ������� airport, ������� �������� ������ � ����������� � ���� ���-�� �������
	from airports 
	group by city -- ����������� �� �������
	) c_a
where c_a.c_s > 1 -- �������, ������������ ������, ��� c_a.c_s > 1

-- 2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?

select distinct fv.departure_airport_name max_range_airports
from flights_v fv 
right join (
	select a.aircraft_code -- ��������� � join, ������������ ������� � ������������ ���������� ������
		from aircrafts a
		order by a."range" desc 
		limit 1
	) mr on mr.aircraft_code = fv.aircraft_code --������ ����������, ������������ ��������, �� ����� ����������� ����� � ������������ ����������
	
-- 3. ������� 10 ������ � ������������ �������� �������� ������

select flight_no, route, delay 
from (
	select fv.flight_no, concat(fv.departure_airport_name, ' - ', fv.arrival_airport_name) route,
	fv.actual_departure - fv.scheduled_departure as delay --��������� ������������ ������� ������ �� ����������������
	from flights_v fv
	) md
where delay is not null -- ���������� null ��������
order by delay desc -- ���������� �� ��������
limit 10 -- ����� ������ 10 ��������

-- 4. ���� �� �����, �� ������� �� ���� �������� ���������� ������? 
select b.book_ref bookings_without_boarding_passes 
from bookings b 
join tickets t on t.book_ref = b.book_ref -- ���������� ������ ������������ � ������ �������
left join boarding_passes bp on bp.ticket_no = t.ticket_no -- left jon ����� �������� ������� � �������� ���������� �������
where bp.ticket_no is null -- �������, ���������� ������ ��������, ������� ���� � ������ �������, �� ��� �� ������
group by b.book_ref -- ����������� �� �������������
 
select distinct t.book_ref bookings_without_boarding_passes
from tickets t 
left join boarding_passes bp on bp.ticket_no = t.ticket_no -- left jon ����� �������� ������� � �������� ���������� �������
where bp.ticket_no is null -- �������, ���������� ������ ��������, ������� ���� � ������ �������, �� ��� �� ������

-- 5. ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
--�.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ � ������� ���.

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

-- 6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.

with cte_1 as -- ������� CTE
	( 
	select f.flight_no, f.aircraft_code, a.model, 
	concat(round((count(f.flight_id) over (partition by f.aircraft_code)::numeric/count(f.flight_id) over ()::numeric)*100,2),'%') cf_percent, -- � ������ ������� ������� ������� ������� ��������� �� ����� ���������
	row_number () over (partition by f.aircraft_code) rn -- �������� ������ �� ����� ���������, ����� ������� �� ����� ������
	from flights f
	join aircrafts a on a.aircraft_code = f.aircraft_code -- ������������ ������� aircrafts, ����� ������� �� ��� ������ ���������
	)
select aircraft_code, model, cf_percent percentage_of_all -- ������� ������ �� cte_1
from cte_1 
where rn = 1 -- �������, ����������� ������� �� ����� ������ ��� ������� ���� ���������

-- 7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
 

with cte_b as ( --������� cte, � ������� ������� ��� ���������� ����� � ��������� �������� � ��� � ������ ������
	select  distinct f.departure_airport da, f.arrival_airport aa, tf.amount  
	from flights f
	join ticket_flights tf on tf.flight_id = f.flight_id and tf.fare_conditions = 'Business'
	),
	cte_e as (  --������� cte, � ������� ������� ��� ���������� ����� � ��������� �������� � ��� � ������ ������
	select  distinct f.departure_airport da, f.arrival_airport aa, tf.amount  
	from flights f
	join ticket_flights tf on tf.flight_id = f.flight_id and tf.fare_conditions = 'Economy'
	),
	cte_c as(  --������� cte, � ������� ���������, ��� ����� ������ ������ ������� �������
	select cte_b.amount, cte_e.amount,
	case 
		when cte_b.amount < cte_e.amount then '?!'
		else 'ok'
	end comparison
	from cte_b
	join cte_e on cte_b.da = cte_e.da and cte_b.aa = cte_e.aa
	)
select * from cte_c -- ������� �����, � ������� ������ ������� �������
where comparison = '?!' -- ����� �� �������

-- 8. ����� ������ �������� ��� ������ ������?

create view city2 as --������� �������������
	select distinct fv.departure_city, fv.arrival_city  --�� ������������� flights_v ����� ���������� ������ ������ � �������
 	from flights_v fv;
select a.city, a2.city  
from airports a 
cross join airports a2 -- ������ ��������� ������������ ������� airports 
where a.city != a2.city --��� ��������� ���� ��������� ��� �������; ��������� ���� � ����� � ��� �� �������
except -- �������� �� ��������� ������������
select * from city2 -- ��� ���� �� �������������, �������� ������ ���� �������, ����� �������� ��� ������ ������



-- 9. ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� *

select distinct fv.departure_airport_name, fv.arrival_airport_name,  a2."range" max_distance_aircraft, -- �������� ������ � �������� ���������� � ������������ ��������� ������ ������
round((acos(sind(a.latitude) * sind(a1.latitude) + cosd(a.latitude) * cosd(a1.latitude) * cosd(a.longitude - a1.longitude)) * 6371)::dec, 2) distance_between_airports, -- ���������� �� �������
case -- ������� case, ������� ���������� ������������ ��������� ������ ������ �������� � ������������ �� ������� ���������� ����� �����������
	when a2."range" >= round((acos(sind(a.latitude) * sind(a1.latitude) + cosd(a.latitude) * cosd(a1.latitude) * cosd(a.longitude - a1.longitude)) * 6371)::dec, 2) then '�������'
	else '�� �������:('
end  "yes_or_no"
from flights_v fv 
join airports a on a.airport_code = fv.departure_airport -- ������������� ������� aiports ��� ��������� ��������� ��������� �����������
join airports a1 on a1.airport_code = fv.arrival_airport  -- ������������� ������� aiports ��� ��������� ��������� ��������� ��������
join aircrafts a2 on a2.aircraft_code = fv.aircraft_code -- ������������� ������� aircrafts ��� ��������� ������������ ��������� ������ ��������