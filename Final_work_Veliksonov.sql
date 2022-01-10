--Итоговая работа

-- Задание 1 
-- В каких городах больше одного аэропорта?

/*Обращаемся к таблице airports
Группируем по значениям столбца city
Считаем сколько раз встречается один и тот же город = количество аэропортов в городе
Оставляем только те, в которых количество получилось больше 1*/

select city 
from airports 
group by city
having count(*) > 1

-- Задание 2 
-- В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

/*В подзапросе обращаемся к таблице aircrafts
Сортируем значения столбца range по убыванию 
Оставляем только первую строку, т.е. самолет с максимальной дальностью перелета 
В основном запросе присоединяем таблицу flights, чтобы узнать из каких аэропортов вылетает наш самолет = в какие аэропорты прилетает
Присоединяем таблицу airports по столбцам с одинаковыми значениями, т.е. по столбцам departure_airport и airport_code 
или arrival_airport и airport_code, чтобы узнать название аэропорта
Группируем и выводим столбец airport_name*/

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

-- Задание 3 
-- Вывести 10 рейсов с максимальным временем задержки вылета

/*Получаем информацию из таблицы flights. Оставляем только те записи, где actual_departure is not null, т.е. самолет всё-таки вылетел.
Далее считаем разницу между фактическим временем вылета и планируемым. Выносим получившиеся значения в отдельный столбец delay_time. 
Сортируем по значениям этого столбца по убыванию и оставляем первые 10 записей
 */

select *, actual_departure - scheduled_departure as delay_time
from flights 
where actual_departure is not null
order by delay_time desc
limit 10

-- Задание 4 
-- Были ли брони, по которым не были получены посадочные талоны?

/*
Сначала получаем данные по всем бронированиям из таблицы bookings. Потом присоединяем таблицу tickets, чтобы получить данные по номеру билета
в каждом бронировании. К получившейся таблице присоединяем таблицу boarding_passes через right join, благодаря чему в нашей таблицу появляется
столбец boarding_no. Если в строке в этом столбце есть значение, значит посадочный талон был выдан, если указано null, значит не был выдан.
Далее фильтруем таблицу и оставляем только те, записи, где boarding_no is null. В таблице остается информация по броням, по которым не были 
получены посадочные талоны.
 */

select *	
from 
	(select *
	from bookings b
	join tickets t on b.book_ref = t.book_ref) bt
left join boarding_passes bp on bp.ticket_no = bt.ticket_no
where bp.boarding_no is null 

-- Задание 5 
-- Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.

/*
В первом cte получаем из таблицы flights аэропорт отправления, id рейса, дату отправления, код самолета. Присоединяем таблицу seats, чтобы 
посчитать количество мест в каждом самолете.
Во втором cte получаем из таблицы boarding_passes id рейса и seat_no. Это те номера сидений, по которым были выданы посадочные талоны, т.е.
благодаря этому узнаем сколько в итоге было пассажиров на рейсе.
В основном запросе соединяем результат второго cte c результатом перового cte, дополнительно присоединяем таблицу airports, чтобы вывести 
название аэропорта. 
В селекте выводим id рейса, код аэопорта отправления, название аэропорта, дату и время вылета. Чтобы вывести % свободных мест в самолете вычитаем из
общего количества мест количество пассажиров, умножаем на 100 и делим на общее количества мест. Привоим к типу numeric, чтобы окргулить в round до
2 знаков после запятой. Также выводим количество пассажиров, которое мы посчитали во втором cte. 
Для вывода накопления используем оконную функцию. В partition by группируем по аэропорту и дате отправления, 
сортируем в order by по дате и времени отправления. Выводим сумму по количеству пассажиров
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
round((count_seats - count_passangers)*100/count_seats::numeric, 2) as "% свободных мест", a_p.count_passangers,
sum(a_p.count_passangers) over (partition by a_s.departure_airport, a_s.scheduled_departure::date order by a_s.scheduled_departure) 
as "Накопление за день"
from amount_seats a_s
join amount_passengers a_p on a_s.flight_id = a_p.flight_id
join airports a on a.airport_code = a_s.departure_airport



-- Задание 6 
-- Найдите процентное соотношение перелетов по типам самолетов от общего количества.

/*Обращаемся к табице ticket_flights, чтобы получить данные по всем перелетам. Присоединяем таблицу flights, чтобы получить данные по 
 * aircraft_code и по этому столбцу присоединить таблицу aircrafts. Теперь у нас есть данные по всем перелетам для каждой модели самолета.
 * Группируем по моделям и выводим count, чтобы увидеть сколько перелетов приходится на каждую модель самолета. 
 * Чтобы вывести не количество, а процент от общего количества перелетов, мы в select считаем количество перелетов для каждой модели, 
 * умножаем на 100 и делим на общее количество перелетов, которое мы получаем в подзапросе. Приводим к numeric чтобы можно было округлить
 * до 2 знаков. В итоге получаем % перелетов от общего количества для каждой модели/для каждого типа самолета
 */

select model, round((count(model)::numeric*100 / (select count(*) from ticket_flights)::numeric), 2)
from ticket_flights tf
join flights f on f.flight_id = tf.flight_id
join aircrafts a on f.aircraft_code = a.aircraft_code
group by model

-- Задание 7 
-- Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

/*
 Получаем информацию по перелетам из таблицы flights. Присоединяем таблицу ticket_flights чтобы получить информацию по билетам, 
 классу и стоимости. Присоединяем таблицу airports чтобы получить города прибытия. Группируем, чтобы получить по каждому перелету 
 варианты стоимости билета в зависимости от класса. Всё это записываем в cte1.
 Обращаемся к cte1. Выводим по кажому перелету максимальную стоимость билета класса Economy и минимальную стоимость билета класса Business. 
 Эти значения группируем с помощью оконных функций по flight_id, чтобы заполнить значения null числовыми значениями. Записываем результат 
 в cte2. 
 Далее обращаемся к cte2 и выводим только те перелеты и города, где max_economy > min_business. Получается, что в рамках перелета не было
 билетов бизнес-класса дешевле эконом-класса
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

-- Задание 8 
-- Между какими городами нет прямых рейсов?

/*
 1) Получаем из таблицы airports название всех городов, в которых есть аэропорты. Используем декартово произведение, чтобы получить все 
 возможные пары город отправления + город прибытия. Фильтруем, чтобы убрать строки, где название города отправления и города прибытия
 совпадают. Записываем получившуюся таблицу в представление. Называем представление all_variants
 2) Обращаемся к таблицы flights, чтобы получить коды аэропортов отправления и прибытия. Присоденияем таблицу airports, чтобы получить
 названия городов отправления и прибытия. Используем distinct, чтобы получить только уникальные пары город отправления + город прибытия, 
 между которыми есть прямые рейсы. 
 3) С помощью оператора except убираем из таблицы all_variants строки, получившиеся во второй части запроса.
 В итоге остаются только те пары городов, между которыми нет прямых рейсов
 */

create view all_variants as
	select a.city as departure_city, a2.city as arrival_city -- Получили все возможные пары городов и записали в представление
	from airports a, airports a2
	where a.city != a2.city
	
select *
from all_variants 
except
select distinct a.city as departure_city, a2.city as arrival_city 
from flights f
join airports a on f.departure_airport = a.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code 

-- Задание 9
-- Вычислите расстояние между аэропортами, связанными прямыми рейсами,
-- сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы 
/*
Обращаемся к таблице flights, чтобы получить id и номер рейса, аэропорт вылета и прибытия. Присоединяем таблицу airports, чтобы узнать 
широту и долготу для каждого аэропорта. Присоединяем таблицу aircrafts, чтобы получить максимальную дальность полета самолета для 
каждого рейса. В селекте с помощью оператора case выводим столбец "Долетел/Не долетел". Для этого в условии when рассчитываем по формуле
значени d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}. Получаем значение в 
градусах. Используем оператор radians, чтобы перевести значение в радианы. Умножаем на 6371 и сравниваем с максимальной дальностью полета.
*/

select f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, 
	a.longitude as longitude_a, a.latitude as latitude_a,
	a2.longitude as longitude_b, a2.latitude as latitude_b,
	a3."range",
	case 
		when 6371*radians((acosd(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))) > a3."range" then 'Не долетел'
		when 6371*radians((acosd(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)))) <= a3."range" then 'Долетел'
	end as "Долетел/Не долетел"
from flights f 
join airports a on f.departure_airport = a.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code 
join aircrafts a3 on f.aircraft_code = a3.aircraft_code 




















