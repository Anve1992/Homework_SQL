--�������� ������

-- ������� 1 
-- � ����� ������� ������ ������ ���������?

/*���������� � ������� airports
���������� �� ��������� ������� city
������� ������� ��� ����������� ���� � ��� �� ����� = ���������� ���������� � ������
��������� ������ ��, � ������� ���������� ���������� ������ 1*/

select city 
from airports 
group by city
having count(*) > 1

-- ������� 2 
-- � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?

/*� ���������� ���������� � ������� aircrafts
��������� �������� ������� range �� �������� 
��������� ������ ������ ������, �.�. ������� � ������������ ���������� �������� 
� �������� ������� ������������ ������� flights, ����� ������ �� ����� ���������� �������� ��� ������� = � ����� ��������� ���������
������������ ������� airports �� �������� � ����������� ����������, �.�. �� �������� departure_airport � airport_code 
��� arrival_airport � airport_code, ����� ������ �������� ���������
���������� � ������� ������� airport_name*/

select a.airport_name 
from (
	select *
	from aircrafts 
	order by range desc 
	limit 1
	) r
join flights f on f.aircraft_code = r.aircraft_code
join airports a on a.airport_code = f.departure_airport 
group by a.airport_name 

-- ������� 3 
-- ������� 10 ������ � ������������ �������� �������� ������

/*�������� ���������� �� ������� flights. ��������� ������ �� ������, ��� actual_departure is not null, �.�. ������� ��-���� �������.
����� ������� ������� ����� ����������� �������� ������ � �����������. ������� ������������ �������� � ��������� ������� delay_time. 
��������� �� ��������� ����� ������� �� �������� � ��������� ������ 10 �������
 */

select *, actual_departure - scheduled_departure as delay_time
from flights 
where actual_departure is not null
order by delay_time desc
limit 10

-- ������� 4 
-- ���� �� �����, �� ������� �� ���� �������� ���������� ������?

/*
������� �������� ������ �� ���� ������������� �� ������� bookings. ����� ������������ ������� tickets, ����� �������� ������ �� ������ ������
� ������ ������������. � ������������ ������� ������������ ������� boarding_passes ����� right join, ��������� ���� � ����� ������� ����������
������� boarding_no. ���� � ������ � ���� ������� ���� ��������, ������ ���������� ����� ��� �����, ���� ������� null, ������ �� ��� �����.
����� ��������� ������� � ��������� ������ ��, ������, ��� boarding_no is null. � ������� �������� ���������� �� ������, �� ������� �� ���� 
�������� ���������� ������.
 */

select *	
from 
	(select *
	from bookings b
	join tickets t on b.book_ref = t.book_ref) bt
left join boarding_passes bp on bp.ticket_no = bt.ticket_no
where bp.boarding_no is null 

-- ������� 5 
-- ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
-- �������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
-- �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.

/*
� ������ cte �������� �� ������� flights �������� �����������, id �����, ���� �����������, ��� ��������. ������������ ������� seats, ����� 
��������� ���������� ���� � ������ ��������.
�� ������ cte �������� �� ������� boarding_passes id ����� � seat_no. ��� �� ������ �������, �� ������� ���� ������ ���������� ������, �.�.
��������� ����� ������ ������� � ����� ���� ���������� �� �����.
� �������� ������� ��������� ��������� ������� cte c ����������� �������� cte, ������������� ������������ ������� airports, ����� ������� 
�������� ���������. 
� ������� ������� id �����, ��� �������� �����������, �������� ���������, ���� � ����� ������. ����� ������� % ��������� ���� � �������� �������� ��
������ ���������� ���� ���������� ����������, �������� �� 100 � ����� �� ����� ���������� ����. ������� � ���� numeric, ����� ��������� � round ��
2 ������ ����� �������. ����� ������� ���������� ����������, ������� �� ��������� �� ������ cte. 
��� ������ ���������� ���������� ������� �������. � partition by ���������� �� ��������� � ���� �����������, 
��������� � order by �� ���� � ������� �����������. ������� ����� �� ���������� ����������
 */

with amount_seats as 
	(
	select f.departure_airport, f.flight_id, f.scheduled_departure, f.aircraft_code, count(seat_no) as count_seats
	from flights f
	join seats s on f.aircraft_code = s.aircraft_code 
	group by f.aircraft_code, f.flight_id
), amount_passengers as
	(
	select bp.flight_id, count(bp.seat_no) as count_passangers
	from boarding_passes bp 
	group by bp.flight_id
)
select a_s.flight_id, a_s.departure_airport, a.airport_name, a_s.scheduled_departure, 
round((count_seats - count_passangers)*100/count_seats::numeric, 2) as "% ��������� ����", a_p.count_passangers,
sum(a_p.count_passangers) over (partition by a_s.departure_airport, a_s.scheduled_departure::date order by a_s.scheduled_departure) 
as "���������� �� ����"
from amount_seats a_s
join amount_passengers a_p on a_s.flight_id = a_p.flight_id
join airports a on a.airport_code = a_s.departure_airport



-- ������� 6 
-- ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.

/*���������� � ������ ticket_flights, ����� �������� ������ �� ���� ���������. ������������ ������� flights, ����� �������� ������ �� 
 * aircraft_code � �� ����� ������� ������������ ������� aircrafts. ������ � ��� ���� ������ �� ���� ��������� ��� ������ ������ ��������.
 * ���������� �� ������� � ������� count, ����� ������� ������� ��������� ���������� �� ������ ������ ��������. 
 * ����� ������� �� ����������, � ������� �� ������ ���������� ���������, �� � select ������� ���������� ��������� ��� ������ ������, 
 * �������� �� 100 � ����� �� ����� ���������� ���������, ������� �� �������� � ����������. �������� � numeric ����� ����� ���� ���������
 * �� 2 ������. � ����� �������� % ��������� �� ������ ���������� ��� ������ ������/��� ������� ���� ��������
 */

select model, round((count(model)::numeric*100 / (select count(*) from ticket_flights)::numeric), 2)
from ticket_flights tf
join flights f on f.flight_id = tf.flight_id
join aircrafts a on f.aircraft_code = a.aircraft_code
group by model

-- ������� 7 
-- ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?

/*
 �������� ���������� �� ��������� �� ������� flights. ������������ ������� ticket_flights ����� �������� ���������� �� �������, 
 ������ � ���������. ������������ ������� airports ����� �������� ������ ��������. ����������, ����� �������� �� ������� �������� 
 �������� ��������� ������ � ����������� �� ������. �� ��� ���������� � cte1.
 ���������� � cte1. ������� �� ������ �������� ������������ ��������� ������ ������ Economy � ����������� ��������� ������ ������ Business. 
 ��� �������� ���������� � ������� ������� ������� �� flight_id, ����� ��������� �������� null ��������� ����������. ���������� ��������� 
 � cte2. 
 ����� ���������� � cte2 � ������� ������ �� �������� � ������, ��� max_economy > min_business. ����������, ��� � ������ �������� �� ����
 ������� ������-������ ������� ������-������
 */

with cte2 as 	
	(with cte1 as 
			(select f.flight_id, tf.fare_conditions, tf.amount, a.city 	
			from flights f
			join ticket_flights tf on f.flight_id = tf.flight_id 
			join airports a on a.airport_code = f.arrival_airport 
			group by f.flight_id, tf.fare_conditions, tf.amount, a.city)
	select flight_id, fare_conditions, max(amount) filter (where fare_conditions = 'Economy') over (partition by flight_id) as max_economy,
		min(amount) filter (where fare_conditions = 'Business') over (partition by flight_id) as min_business, city
	from cte1
	group by flight_id, fare_conditions, city, amount)
select *
from cte2
where max_economy > min_business

-- ������� 8 
-- ����� ������ �������� ��� ������ ������?

/*
 1) �������� �� ������� airports �������� ���� �������, � ������� ���� ���������. ���������� ��������� ������������, ����� �������� ��� 
 ��������� ���� ����� ����������� + ����� ��������. ���������, ����� ������ ������, ��� �������� ������ ����������� � ������ ��������
 ���������. ���������� ������������ ������� � �������������. �������� ������������� all_variants
 2) ���������� � ������� flights, ����� �������� ���� ���������� ����������� � ��������. ������������ ������� airports, ����� ��������
 �������� ������� ����������� � ��������. ���������� distinct, ����� �������� ������ ���������� ���� ����� ����������� + ����� ��������, 
 ����� �������� ���� ������ �����. 
 3) � ������� ��������� except ������� �� ������� all_variants ������, ������������ �� ������ ����� �������.
 � ����� �������� ������ �� ���� �������, ����� �������� ��� ������ ������
 */

create view all_variants as
	select a.city as departure_city, a2.city as arrival_city -- �������� ��� ��������� ���� ������� � �������� � �������������
	from airports a, airports a2
	where a.city != a2.city
	
select *
from all_variants 
except
select distinct a.city as departure_city, a2.city as arrival_city 
from flights f
join airports a on f.departure_airport = a.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code 

-- ������� 9
-- ��������� ���������� ����� �����������, ���������� ������� �������,
-- �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� 
/*
���������� � ������� flights, ����� �������� id � ����� �����, �������� ������ � ��������. ������������ ������� airports, ����� ������ 
������ � ������� ��� ������� ���������. ������������ ������� aircrafts, ����� �������� ������������ ��������� ������ �������� ��� 
������� �����. � ������� � ������� ��������� case ������� ������� "�������/�� �������". ��� ����� � ������� when ������������ �� �������
������� d = arccos {sin(latitude_a)�sin(latitude_b) + cos(latitude_a)�cos(latitude_b)�cos(longitude_a - longitude_b)}. �������� �������� � 
��������. ���������� �������� radians, ����� ��������� �������� � �������. �������� �� 6371 � ���������� � ������������ ���������� ������.
*/

select f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, 
	a.longitude as longitude_a, a.latitude as latitude_a,
	a2.longitude as longitude_b, a2.latitude as latitude_b,
	a3."range",
	case 
		when 6371*radians((acosd(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))) > a3."range" then '�� �������'
		when 6371*radians((acosd(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))) <= a3."range" then '�������'
	end as "�������/�� �������"
from flights f 
join airports a on f.departure_airport = a.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code 
join aircrafts a3 on f.aircraft_code = a3.aircraft_code 




















