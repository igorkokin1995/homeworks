--=============== ������ 4. ���������� � SQL =======================================
--= �������, ��� ���������� ���������� ������ ���������� � ������� ����� PUBLIC===========
SET search_path TO public;

--======== �������� ����� ==============

--������� �1
--���� ������: ���� ����������� � �������� ����, �� ������� ����� ����� � ��������� � --���� �������, �������� ������ ���� �� �������� � ������ �������� � ������� �������� --� ���� ����� �����, ���� ����������� � ���������� �������, �� ������� ����� ����� � --� ��� ������� �������.

--������������� ���� ������, ���������� ��� �����������:
--� ���� (����������, ����������� � �. �.);
--� ���������� (�������, ���������� � �. �.);
--� ������ (������, �������� � �. �.).
--��� ������� �� �������: ����-���������� � ����������-������, ��������� ������ �� ������. ������ ������� �� ������� � film_actor.
--���������� � ��������-������������:
--� ������� ����������� ��������� ������.
--� �������������� �������� ������ ������������� ���������������;
--� ������������ ��������� �� ������ ��������� null-��������, �� ������ ����������� --��������� � ��������� ���������.
--���������� � �������� �� �������:
--� ������� ����������� ��������� � ������� ������.

--� �������� ������ �� ������� �������� ������� �������� ������ � ������� �� --���������� � ������ ������� �� 5 ����� � �������.
 
--�������� ������� �����

create table "language"(
language_id serial primary key,
language_name varchar(50) unique not null 
);

--�������� ������ � ������� �����

insert into "language" (language_name)
values
('English'),
('Russian'),
('French'),
('German'),
('Spanish');

select *from "language" l 

--�������� ������� ����������

create table nationality(
nationality_id serial primary key,
nationality varchar(50) unique not null 
);

--�������� ������ � ������� ����������

insert into nationality (nationality)
values
('English'),
('Russian'),
('French'),
('German'),
('Spanish');

select *from nationality n 

--�������� ������� ������

create table country(
country_id serial primary key,
country varchar(50) unique not null 
);


--�������� ������ � ������� ������

insert into country (country)
values
('French'),
('English'),
('Spanish'),
('Russian'),
('German');

select *from country c

--�������� ������ ������� �� �������

create table language_nationality(
language_id integer references "language"(language_id),
nationality_id integer references nationality(nationality_id),
primary key(language_id, nationality_id)
);

--�������� ������ � ������� �� �������

insert into language_nationality (language_id, nationality_id)
values
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

select *from language_nationality ln2 


--�������� ������ ������� �� �������

create table nationality_country(
nationality_id integer references nationality(nationality_id),
country_id integer references country(country_id),
primary key(nationality_id, country_id)
);


--�������� ������ � ������� �� �������

insert into nationality_country (nationality_id, country_id)
values
(1, 2),
(2, 4),
(3, 1),
(4, 5),
(5, 3);

select * from nationality_country


--======== �������������� ����� ==============


--������� �1 
--�������� ����� ������� film_new �� ���������� ������:
--�   	film_name - �������� ������ - ��� ������ varchar(255) � ����������� not null
--�   	film_year - ��� ������� ������ - ��� ������ integer, �������, ��� �������� ������ ���� ������ 0
--�   	film_rental_rate - ��������� ������ ������ - ��� ������ numeric(4,2), �������� �� ��������� 0.99
--�   	film_duration - ������������ ������ � ������� - ��� ������ integer, ����������� not null � �������, ��� �������� ������ ���� ������ 0
--���� ��������� � �������� ����, �� ����� ��������� ������� ������� ������������ ����� �����.

create table kokin_dau_26.film_new(
film_name varchar(255) not null,
film_year integer check(film_year > 0),
film_rental_rate numeric(4,2),
film_duration integer not null check (film_rental_rate > 0)
);

alter table c
alter column film_rental_rate 
set default 0.99

--������� �2 
--��������� ������� film_new ������� � ������� SQL-�������, ��� �������� ������������� ������� ������:
--�       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--�       film_year - array[1994, 1999, 1985, 1994, 1993]
--�       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--�   	  film_duration - array[142, 189, 116, 142, 195]


insert into kokin_dau_26.film_new (film_name, film_year, film_rental_rate, film_duration)
values (unnest(array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']),
unnest(array[1994, 1999, 1985, 1994, 1993]),
unnest(array[2.99, 0.99, 1.99, 2.99, 3.99]),
unnest(array[142, 189, 116, 142, 195])
);

select * from kokin_dau_26.film_new fn 


--������� �3
--�������� ��������� ������ ������� � ������� film_new � ������ ����������, 
--��� ��������� ������ ���� ������� ��������� �� 1.41

update kokin_dau_26.film_new 
set film_rental_rate = film_rental_rate + 1.41

select * from kokin_dau_26.film_new fn 

--������� �4
--����� � ��������� "Back to the Future" ��� ���� � ������, 
--������� ������ � ���� ������� �� ������� film_new

delete from kokin_dau_26.film_new
where film_name = 'Back to the Future'

select * from kokin_dau_26.film_new fn

--������� �5
--�������� � ������� film_new ������ � ����� ������ ����� ������

insert into kokin_dau_26.film_new (film_name, film_year, film_rental_rate, film_duration)
values ('Fight Club', 1999, 6.99, 139);

select * from kokin_dau_26.film_new fn

--������� �6
--�������� SQL-������, ������� ������� ��� ������� �� ������� film_new, 
--� ����� ����� ����������� ������� "������������ ������ � �����", ���������� �� �������

select *, round(fn.film_duration::numeric/60,1) film_duration_hours
from kokin_dau_26.film_new fn


--������� �7 
--������� ������� film_new

drop table if exists kokin_dau_26.film_new restrict;