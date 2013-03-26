create database $DB_NAME character set utf8;
use $DB_NAME;

drop table if exists last_processed;
create table last_processed (
    set_name varchar(128) primary key,
    last_processed timestamp
) engine = innodb;


drop table if exists picks;
create table picks (
    user_id int not null,
    item_id int not null,
    timestamp timestamp not null default CURRENT_TIMESTAMP,

    unique key (user_id, item_id),
    key (item_id),
    key (user_id, timestamp),
    key (timestamp)
) engine = innodb;

drop table if exists picks_buffer;
create table picks_buffer (
    id int not null auto_increment primary key,

    user_id int,
    user_char_id varchar(255),
    item_id int,
    item_char_id varchar(255),
    is_delete tinyint(1) not null default 0,
    timestamp timestamp not null default CURRENT_TIMESTAMP
) engine = innodb;

drop table if exists uninterested;
create table uninterested (
    user_id int not null,
    item_id int not null,
    timestamp timestamp not null default CURRENT_TIMESTAMP,

    unique key (user_id, item_id),
    key (item_id),
    key (user_id, timestamp),
    key (timestamp)
) engine = innodb;

drop table if exists uninterested_buffer;
create table uninterested_buffer (
    id int not null auto_increment primary key,

    user_id int,
    user_char_id varchar(255),
    item_id int,
    item_char_id varchar(255),
    is_delete tinyint(1) not null default 0,
    timestamp timestamp not null default CURRENT_TIMESTAMP
) engine = innodb;



drop table if exists user_id_char2int;
create table user_id_char2int (
    id int not null auto_increment primary key,
    char_id varchar(255) not null,
    timestamp timestamp not null default CURRENT_TIMESTAMP,

    unique key (char_id),
    key (timestamp)
) engine = innodb;

drop table if exists item_id_char2int;
create table item_id_char2int (
    id int not null auto_increment primary key,
    char_id varchar(255) not null,
    timestamp timestamp not null default CURRENT_TIMESTAMP,

    unique key (char_id),
    key (timestamp)
) engine = innodb;




drop table if exists ratings;
create table ratings (
    user_id int not null,
    item_id int not null,
    rating double,
    timestamp timestamp not null default CURRENT_TIMESTAMP,

    unique key (user_id, item_id),
    key (item_id),
    key (user_id, timestamp),
    key (timestamp)
) engine = innodb;

drop table if exists ratings_buffer;
create table ratings_buffer (
    id int not null auto_increment primary key,

    user_id int,
    user_char_id varchar(255),
    item_id int,
    item_char_id varchar(255),
    rating double,
    is_delete tinyint(1) not null default 0,
    timestamp timestamp not null default CURRENT_TIMESTAMP
) engine = innodb;


drop table if exists tagged_relations;
create table tagged_relations (
    tag_id int not null,
    user_id int not null,
    item_id int not null,
    timestamp timestamp not null default CURRENT_TIMESTAMP,

    key (user_id, item_id),
    key (item_id),
    key (tag_id)
) engine = innodb;

drop table if exists tagged_relations_buffer;
create table tagged_relations_buffer (
    id int not null auto_increment primary key,

    tag_id int not null,
    user_id int,
    user_char_id varchar(255),
    item_id int,
    item_char_id varchar(255),
    is_delete tinyint(1) not null default 0,
    timestamp timestamp not null default CURRENT_TIMESTAMP
) engine = innodb;

drop table if exists categories;
create table categories (
    id int not null auto_increment primary key,

    item_id int,
    category_id int,
    timestamp timestamp not null default CURRENT_TIMESTAMP,
    key(item_id),
    unique key(category_id, item_id)
) engine = innodb;

drop table if exists categories_buffer;
create table categories_buffer (
    id int not null auto_increment primary key,

    item_id int,
    item_char_id varchar(255),
    category_id int,
    is_delete tinyint(1) not null default 0,
    timestamp timestamp not null default CURRENT_TIMESTAMP
) engine = innodb;

