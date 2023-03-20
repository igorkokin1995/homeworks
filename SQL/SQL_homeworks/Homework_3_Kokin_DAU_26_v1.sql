--=============== ������ 3. ������ SQL =======================================
--= �������, ��� ���������� ���������� ������ ���������� � ������� ����� PUBLIC===========
SET search_path TO public;

--======== �������� ����� ==============

--������� �1
--�������� ��� ������� ���������� ��� ����� ����������, 
--����� � ������ ����������.

select concat(c.first_name, ' ', c.last_name) as customer_name, a.address, c2.city as city, c3.country as country  
from customer c 
left join address a using(address_id)
left join city c2 using (city_id)
left join country c3 using (country_id)


--������� �2
--� ������� SQL-������� ���������� ��� ������� �������� ���������� ��� �����������.

select s.store_id "ID ��������", count(c.customer_id) "���������� �����������"
from store s 
left join customer c using (store_id)
group by s.store_id 
order by count(c.customer_id) desc 

--����������� ������ � �������� ������ �� ��������, 
--� ������� ���������� ����������� ������ 300-��.
--��� ������� ����������� ���������� �� ��������������� ������� 
--� �������������� ������� ���������.


select s.store_id "ID ��������", count(c.customer_id) "���������� �����������"
from store s 
left join customer c using (store_id)
group by s.store_id 
having count(c.customer_id) > 300
order by count(c.customer_id) desc 

-- ����������� ������, ������� � ���� ���������� � ������ ��������, 
--� ����� ������� � ��� ��������, ������� �������� � ���� ��������.


select s.store_id "ID ��������", count(c.customer_id) "���������� �����������", c2.city "�����",
concat(s2.last_name, '_', s2.first_name) "���������" 
from store s 
left join customer c on c.store_id = s.store_id 
left join staff s2 on s2.store_id =s.store_id 
left join address a on a.address_id = s.address_id 
left join city c2 on c2.city_id = a.city_id 
group by s.store_id, concat(s2.last_name, '_', s2.first_name), c2.city  
having count(c.customer_id) > 300
order by count(c.customer_id) desc 


--������� �3
--�������� ���-5 �����������, 
--������� ����� � ������ �� �� ����� ���������� ���������� �������

select concat(c.first_name, ' ', c.last_name) "����������", count(r.rental_id)  
from customer c 
left join rental r using (customer_id)
group by c.customer_id 
order by count(r.rental_id) desc 


--������� �4
--���������� ��� ������� ���������� 4 ������������� ����������:
--  1. ���������� �������, ������� �� ���� � ������
--  2. ����� ��������� �������� �� ������ ���� ������� (�������� ��������� �� ������ �����)
--  3. ����������� �������� ������� �� ������ ������
--  4. ������������ �������� ������� �� ������ ������


select concat(c.first_name, ' ', c.last_name) "����������", count(pr.inventory_id) "���-�� �������",
sum(pr.amount)::int "����� ��������� ��������", 
min(pr.amount) "����������� ��������� �������", max(pr.amount) "������������ ��������� �������"   
from customer c 
left join (
select r.customer_id, r.inventory_id, p.amount  
from payment p
left join rental r on p.rental_id = r.rental_id) pr on c.customer_id = pr.customer_id 
group by c.customer_id 
order by count(pr.inventory_id) desc


--������� �5
--��������� ������ �� ������� ������� ��������� ����� �������� ������������ ���� ������� ����� �������,
 --����� � ���������� �� ���� ��� � ����������� ���������� �������. 
 --��� ������� ���������� ������������ ��������� ������������.
 
select c.city "����� 1", c2.city "����� 2"
from city c 
cross join city c2 
where c.city_id != c2.city_id and 
c.city != c2.city 


--������� �6
--��������� ������ �� ������� rental � ���� ������ ������ � ������ (���� rental_date)
--� ���� �������� ������ (���� return_date), 
--��������� ��� ������� ���������� ������� ���������� ����, �� ������� ���������� ���������� ������.
 
select r.customer_id "ID ����������", round(avg(r.return_date::date - r.rental_date::date),2) 
from rental r
group by r.customer_id 
order by r.customer_id 



--======== �������������� ����� ==============

--������� �1
--���������� ��� ������� ������ ������� ��� ��� ����� � ������ � �������� ����� ��������� ������ ������ �� �� �����.

--��� �����������
select f.title "��������", f.rating "�������", c."name" "����", f.release_year "��� �������", l."name" "����",  count(r.rental_id) "���������� �����", sum(p.amount) "����� ��������� ������" 
from rental r 
left join inventory i using (inventory_id)
left join film f using(film_id)
left join film_category fc using (film_id)
left join category c using (category_id)
left join "language" l using (language_id)
left join payment p using (rental_id)
group by f.film_id, l."name", c."name"  
order by f.title 

--� ������������
select h.title "��������", h.rating "�������", g."name" "����", h.release_year "��� �������", l."name" "����",  count(r.rental_id) "���������� �����", sum(p.amount) "����� ��������� ������" 
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


--������� �2
--����������� ������ �� ����������� ������� � �������� � ������� ������� ������, ������� �� ���� �� ����� � ������.

select f.title "��������", f.rating "�������", c."name" "����", f.release_year "��� �������", l."name" "����",  count(r.rental_id) "���������� �����", sum(p.amount) "����� ��������� ������" 
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


--������� �3
--���������� ���������� ������, ����������� ������ ���������. �������� ����������� ������� "������".
--���� ���������� ������ ��������� 7300, �� �������� � ������� ����� "��", ����� ������ ���� �������� "���".

select p.staff_id, count(p.payment_id)"���������� ������", 
case  
	when count(p.payment_id) > 7300 then '��'
	else  '���'
end "������"
from payment p
group by p.staff_id 
