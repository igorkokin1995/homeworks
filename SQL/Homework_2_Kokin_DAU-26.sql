--=============== ������ 2. ������ � ������ ������ =======================================
--= �������, ��� ���������� ���������� ������ ���������� � ������� ����� PUBLIC===========
SET search_path TO public;

--======== �������� ����� ==============

--������� �1
--�������� ���������� �������� ������� �� ������� �������.

select distinct city from city


--������� �2
--����������� ������ �� ����������� �������, ����� ������ ������� ������ �� ������,
--�������� ������� ���������� �� �L� � ������������� �� �a�, � �������� �� �������� ��������.

select distinct city from city
where city like 'L%a' and 
city not like '% %'


--������� �3
--�������� �� ������� �������� �� ������ ������� ���������� �� ��������, ������� ����������� 
--� ���������� � 17 ���� 2005 ���� �� 19 ���� 2005 ���� ������������, 
--� ��������� ������� ��������� 1.00.
--������� ����� ������������� �� ���� �������.

select payment_id, payment_date, amount from payment 
where payment_date between '17.06.2005' and '20.06.2005'
and amount > 1.00
order by payment_date


--������� �4
-- �������� ���������� � 10-�� ��������� �������� �� ������ �������.

select payment_id, payment_date, amount from payment
order by payment_date desc limit 10


--������� �5
--�������� ��������� ���������� �� �����������:
--  1. ������� � ��� (� ����� ������� ����� ������)
--  2. ����������� �����
--  3. ����� �������� ���� email
--  4. ���� ���������� ���������� ������ � ���������� (��� �������)
--������ ������� ������� ������������ �� ������� �����.

select concat(first_name, ' ', last_name) as "������� � ���",
email as "����������� �����",
character_length(email) as "����� email",
last_update:: date as "����" from customer 


--������� �6
--�������� ����� �������� ������ �������� �����������, ����� ������� KELLY ��� WILLIE.
--��� ����� � ������� � ����� �� �������� �������� ������ ���� ���������� � ������ �������.

select lower(first_name), lower(last_name), activebool from customer
where activebool = true and 
first_name ilike 'kelly' or
first_name ilike 'willie'


--======== �������������� ����� ==============

--������� �1
--�������� ����� �������� ���������� � �������, � ������� ������� "R" 
--� ��������� ������ ������� �� 0.00 �� 3.00 ������������, 
--� ����� ������ c ��������� "PG-13" � ���������� ������ ������ ��� ������ 4.00.

select film_id, title, description, rating, rental_rate from film
where cast(rating as text) ilike 'r' and 
rental_rate between 0.00 and 3.00 or  
cast(rating as text) ilike 'pg-13' and 
rental_rate >= 4.00


--������� �2
--�������� ���������� � ��� ������� � ����� ������� ��������� ������.

select film_id, title, description from film
order by character_length(description) desc limit 3 


--������� �3
-- �������� Email ������� ����������, �������� �������� Email �� 2 ��������� �������:
--� ������ ������� ������ ���� ��������, ��������� �� @, 
--�� ������ ������� ������ ���� ��������, ��������� ����� @.

select customer_id, email, split_part(email, '@', 1) as "Email before @", split_part(email, '@', 2) as "Email after @" from customer  


--������� �4
--����������� ������ �� ����������� �������, �������������� �������� � ����� ��������: 
--������ ����� ������ ���� ���������, ��������� ���������.

select customer_id, email, 
concat(left(split_part(email, '@', 1),1),lower(substring(split_part(email, '@', 1),2)))  as "Email before @", 
concat(upper(left(split_part(email, '@', 2),1)), substring(split_part(email, '@', 2),2))  as "Email after @" from customer  

