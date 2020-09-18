DROP DATABASE IF EXISTS youtube;
CREATE DATABASE youtube;
USE youtube;

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts(
  id bigint unsigned not null auto_increment primary key,
  firstname varchar(100),
  lastname varchar(100) comment 'surname',
  email varchar(100) unique,
  password_hash varchar(100),
  birthday DATE,
  phone bigint unsigned unique,
  
  index idx_users_name (firstname, lastname)
);

DROP TABLE IF EXISTS photos;
CREATE TABLE photos(
	id SERIAL,
	account_id bigint unsigned not null,
	filename varchar(255),
	`size` int,
	metadata JSON,
	created_at datetime default now(),
  
  FOREIGN KEY (account_id) REFERENCES accounts(id)
);

DROP TABLE IF EXISTS channels;
CREATE TABLE channels (
	account_id bigint unsigned not null primary key,
	name varchar(100),
	country varchar(100),
	created_at datetime default now(),
	photo_id bigint unsigned,
	
	INDEX (name),
	FOREIGN KEY (account_id) REFERENCES accounts(id),
	FOREIGN KEY (photo_id) REFERENCES photos(id)
);

DROP TABLE IF EXISTS  subscriptions;
CREATE TABLE subscriptions(
	id SERIAL,
	account_id bigint unsigned not null,
	channel_id bigint unsigned not null,
	status enum('subscribed', 'not subscribed'),
	created_at datetime default now(),
	updated_at datetime on update current_timestamp,
  
	PRIMARY KEY (account_id, channel_id), -- чтобы не было 2 записей о пользователе и канале
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (channel_id) REFERENCES channels(account_id)
);

-- чтобы пользователь не подписывался сам на себя
ALTER TABLE subscriptions 
ADD CHECK(account_id <> channel_id);

DROP TABLE IF EXISTS video_category;
CREATE TABLE video_category(
	id SERIAL,
    category varchar(255)
);

DROP TABLE IF EXISTS videos;
CREATE TABLE videos(
  id SERIAL,
  category_id bigint unsigned not null,
  video_name varchar(255),
  channel_id bigint unsigned not null,
  description text,
  privacy  enum('private', 'unlisted', 'public'),
  metadata JSON,
  `size` int,
  created_at datetime default now(),
  main_photo_id bigint unsigned, 
  
  FOREIGN KEY (channel_id) REFERENCES channels(account_id),
  FOREIGN KEY (main_photo_id) REFERENCES photos(id),
  FOREIGN KEY (category_id) REFERENCES video_category(id)
);

DROP TABLE IF EXISTS video_likes_dislikes;
CREATE TABLE video_likes_dislikes(
	id SERIAL,
	status enum('like', 'dislike'),
    account_id bigint unsigned not null,
    video_id bigint unsigned not null,
    created_at datetime default now(),
    updated_at datetime on update current_timestamp,

	FOREIGN KEY (account_id) REFERENCES accounts(id),
	FOREIGN KEY (video_id) REFERENCES videos(id)
);

DROP TABLE IF EXISTS views;
CREATE TABLE views(
	id SERIAL,
    account_id bigint unsigned not null,
    video_id bigint unsigned not null,
    created_at datetime default now(),

	FOREIGN KEY (account_id) REFERENCES accounts(id),
	FOREIGN KEY (video_id) REFERENCES videos(id)
);

DROP TABLE IF EXISTS comments;
CREATE TABLE comments(
	id SERIAL,
	account_id bigint unsigned not null,
    video_id bigint unsigned not null,
    created_at datetime default now(),
    body text,
  
	FOREIGN KEY (account_id) REFERENCES accounts(id),
	FOREIGN KEY (video_id) REFERENCES videos(id)
);

DROP TABLE IF EXISTS comment_likes_dislikes;
CREATE TABLE comment_likes_dislikes(
	id SERIAL,
	status enum('like', 'dislike'),
    account_id bigint unsigned not null,
    comment_id bigint unsigned not null,
    created_at datetime default now(),
    updated_at datetime on update current_timestamp,

	FOREIGN KEY (account_id) REFERENCES accounts(id),
	FOREIGN KEY (comment_id) REFERENCES comments(id)
);