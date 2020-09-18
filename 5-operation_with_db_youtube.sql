/* ДЛЯ УДОБСТВА И ПРАВИЛЬНОГО ВЫПОЛНЕНИЯ ЗАПРОСОВ ВОСПОЛЬЗУЙТЕСЬ СТРОКОЙ НИЖЕ*/
use youtube;

/* -------------------------Скрипты характерных выборок (включающие группировки, JOIN'ы, вложенные таблицы);--------------------------------------*/

-- получение данных о канале пользователя 71:
select 
	c.name as 'channel name', 
	c.created_at,
	c.country,
	concat(a.firstname, ' ', a.lastname) as 'author',
	c.photo_id as 'main photo'
from channels c 
join accounts a on a.id = c.account_id
where c.account_id = 71;

-- просмотр количества лайков и дислайков у видео пользователя 75:
select
	count(*),
	video_id,
	status
from video_likes_dislikes
where video_id in (
	select id from videos where channel_id = 75
)
group by status;

-- Извлечем те видео у которых есть хоть один просмотр
SELECT * FROM videos
	WHERE EXISTS (SELECT * FROM views WHERE video_id = videos.id);

-- вывод списка категорий с указанием количества видео в каждой категории и списком названий видео
select 
	vc.category,
	count(v.id) as 'quantity',
	GROUP_CONCAT(v.video_name) as 'video names'	
from 
	videos v
left join
	video_category vc
on 
	v.category_id = vc.id
group by vc.category;



/*-------------------------------------------------------представления----------------------------------------------------------------------------------- */

-- представление, выводящее список видео пользователя 101 с кол-м дислайков
CREATE or replace VIEW view_video_dislikes
AS 
	select 
	 	v.video_name, 
	 	count(*) as 'number of dislikes'
	from videos v
	join video_likes_dislikes vld on v.id = vld.video_id 
	where channel_id = 101 and status = 'dislike'
	group by v.id;

select * from view_video_dislikes; -- запуск предствавления

-- представление, показывающее количество подписок у существующих каналов 
CREATE or replace VIEW view_subscriptions
AS 
	select 
		c.name,
		count(*)
	from subscriptions s
	join channels c on s.account_id = c.account_id
	where s.status = 'subscribed'
	group by c.name
	order by count(*) desc;

select * from view_subscriptions;


/*--------------------------------------------хранимая процедура----------------------------------------------------------------------------*/

-- процедура, предлагающая к просмотру каналы:
drop procedure if exists sp_offer_video; 

delimiter // -- задаем новый разделитель

create procedure sp_offer_video(for_account_id bigint)
begin
	-- из одной страны
	select c2.account_id 
	from channels c1 
	join channels c2 on c1.country = c2.country 
	where c1.account_id = for_account_id
		and c2.account_id != for_account_id -- исключаем пользователя от которого идёт запрос
		
union -- добавление новых строк
		
	-- каналы которые подписаны на одни и теже
	select s2.account_id 
	from subscriptions s1
	join subscriptions s2 on s1.channel_id = s2.channel_id 
	where s1.account_id = for_account_id
		and s2.account_id = for_account_id

union 

	-- был просмотр видео этого канала
	select v.channel_id
	from views vs 
	join videos v on vs.video_id = v.id
	where v.id in (select video_id from views where account_id = for_account_id)
		and v.channel_id <> for_account_id
		
union

	-- у каналов есть похожие просмотры
	select v2.account_id 
	from views v1 
	join views v2 on v1.video_id = v2.video_id 
	where v1.account_id = for_account_id
		and v2.account_id != for_account_id

	order by rand() -- будем брать всегда случайные записи
	limit 2 -- ограничим всю выборку до 5 строк
;
end //

delimiter ; -- возвращаем разделитель

call sp_offer_video(71); -- вызов процедуры



/*----------------------------------------------------------триггер----------------------------------------------------------------------------*/

-- триггер который проверят существование имени у канала пользователя
drop TRIGGER if exists check_name_channels;

DELIMITER //

CREATE TRIGGER check_name_channels BEFORE INSERT ON channels
FOR EACH ROW
begin
    IF isnull(new.name) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Update Canceled. Name cant be NULL';
    END IF;
END//

DELIMITER ;

-- добавляем пользователя - его id будет 201
INSERT INTO accounts (firstname, lastname)
VALUES ('Mika', 'Lonu');

-- проверяем какую ошибку выдает добавление новой строки
INSERT INTO channels (name, account_id)
VALUES (NULL, 201);


