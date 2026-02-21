# NIVEL 1 

-- Descarga los archivos CSV, estudiales y diseña una base de datos con un esquema de estrella que contenga, 
-- al menos 4 tablas de las que puedas realizar las siguientes consultas:

-- 1) creacion sssde BBDD sprint4:

create database sprint4;

-- 2) crear tablas american_users, european_users, credit_card, companies y transactions:

use sprint4;

drop table if exists american_users;
create table american_users (
	id int primary key,
    name varchar(20),
    surname varchar(20),
    phone varchar(40),
    email varchar(50),
    birth_date varchar(20),
    country varchar(20),
    city varchar(40),
    postal_code varchar(40),
    address varchar(50),
    region varchar(20)
);

drop table if exists european_users;
create table european_users (
	id int primary key,
    name varchar(20),
    surname varchar(20),
    phone varchar(40),
    email varchar(50),
    birth_date varchar(20),
    country varchar(20),
    city varchar(40),
    postal_code varchar(40),
    address varchar(50),
    region varchar(20)
);

drop table if exists credit_card;
create table credit_card (
	id varchar(20) primary key,
    user_id int,
    iban varchar(50),
    pan varchar(50),
    pin varchar(5),
    cvv varchar(5),
    track1 varchar(100),
    track2 varchar(100),
    expiring_date varchar(20)
);

drop table if exists companies;
create table companies (
	company_id varchar(50) primary key,
    company_name varchar(50),
    phone varchar(40),
    email varchar(50),
    country varchar(50),
    website varchar(50)
);			

drop table if exists transactions;
create table transactions (
	id varchar(50) primary key,
    card_id varchar(20), 
    business_id varchar(50),
	timestamp timestamp,
	amount decimal(10, 2),
    declined boolean,
    product_ids varchar(20),
    user_id int,
    lat varchar(100),
    longitude varchar(100),
    foreign key (card_id) references credit_card(id),
    foreign key (business_id) references companies(company_id)
); 

-- 3) cargar las tablas con los archivos csv y agregar datos de region en american_users y european_users 
-- para luego unirlos en una sola tabla users con su identificador de region:

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/S04_datos/american_users.csv'
into table american_users
fields terminated by ','
enclosed by '"'
ignore 1 rows
(id, name, surname, phone, email, birth_date, country, city, postal_code, address)
set region = "America";

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/S04_datos/european_users.csv'
into table european_users
fields terminated by ','
enclosed by '"'
ignore 1 rows
(id, name, surname, phone, email, birth_date, country, city, postal_code, address)
set region = "Europa";

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/S04_datos/credit_cards.csv'
into table credit_card
fields terminated by ','
enclosed by '"'
ignore 1 rows;

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/S04_datos/companies.csv'
into table companies
fields terminated by ','
enclosed by '"'
ignore 1 rows;

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/S04_datos/transactions.csv'
into table transactions
fields terminated by ';'
ignore 1 rows;

-- 4)  crear tabla users con todos los datos de american_users y european_users:

drop table if exists users;
create table users as
select * from american_users
union all
select * from european_users;

-- 5) eliminar tablas sobrantes:

drop table if exists  american_users, european_users;

-- 6) asignar primary key a users:

alter table users
add primary key (id);

-- 7) relacionar tablas users con transactions:

alter table transactions
add constraint users_transactions
foreign key (user_id)
references users(id);

# Ejercicio 1
-- Realiza una subconsulta que muestre a todos los usuarios con más de 80 transacciones utilizando al menos 2 tablas.

select u.id, 
	   u.name as nombre,
       u.surname as apellido,
       count(t.id) as cantidad_transacciones
from users as u
join transactions as t on t.user_id = u.id
where u.id in (select t.user_id
			   from transactions as t
               where t.declined = 0
               group by t.user_id
               having count(t.id) > 80)
group by u.id, u.name, u.surname;

# Ejercicio 2
-- Muestra la media de amount por IBAN de las tarjetas de crédito en la compañía Donec Ltd., utiliza por lo menos 2 tablas.

select card.iban, 
       avg(t.amount) as media_ventas, 
       c.company_name as compania
from transactions as t
join companies as c on c.company_id = t.business_id
join credit_card as card on card.id = t.card_id
where c.company_name = "Donec Ltd"
group by card.iban
order by media_ventas desc; 

# NIVEL 2 

-- Crea una nueva tabla que refleje el estado de las tarjetas de crédito basado en si las tres últimas transacciones 
-- han sido declinadas entonces es inactivo, si al menos una no es rechazada entonces es activo . 

drop table if exists estado_tarjeta;
create table estado_tarjeta (
	card_id varchar(20) primary key, 
    estado varchar(20)
);

insert into estado_tarjeta (card_id, estado)
select card_id,
	   case when sum(declined) = 3 then 'Inactiva'
	   else 'Activa'
	   end as estado
from (select card_id,
			 declined,
		     row_number() over(
				partition by card_id
				order by date(timestamp) desc
			 ) as orden
	  from transactions) t
where orden <= 3
group by card_id;

select * from estado_tarjeta;

-- Partiendo de esta tabla responde:

# Ejercicio 1
-- ¿Cuántas tarjetas están activas? 

select count(estado) as cantidad_activas
from estado_tarjeta
where estado = "Activa";

# NIVEL 3 

-- Crea una tabla con la que podamos unir los datos del nuevo archivo products.csv con la base de datos creada, 
-- teniendo en cuenta que desde transaction tienes product_ids. Genera la siguiente consulta:

-- 1) crear tabla products

drop table if exists products;
create table products (
	id varchar(20) primary key,
    product_name varchar(40),
    price varchar(20),
    colour varchar(40),
    weight varchar(40),
    warehouse_id varchar(20)
);

-- 2) cargar csv

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/S04_datos/products.csv'
into table products 
fields terminated by ','
enclosed by '"'
ignore 1 rows;

-- 3) crear tabla puente product_transactions con clave primaria compuesta para permitir múltiples product_id por transaction_id
-- y múltiples transaction_id por product_id.

drop table if exists product_transactions;
create table product_transactions (
	transaction_id varchar(50), 
    product_id varchar(20),
    primary key (transaction_id, product_id)
    );

-- 4) desde transactions insertamos los registros transaction_id y product_id los obtendremos utilizando JSON 
-- para separarlos en columnas distintas.

insert into product_transactions (transaction_id, product_id)
select t.id, cast(jason.value as unsigned) as product_id 
FROM transactions t
join json_table(
    concat(
        '["', replace(t.product_ids, ',', '","'),'"]'
    ),
    '$[*]' columns (value varchar(50) path '$')
) as jason;

-- 5) relacionar tablas product_transactions con products y transations.

alter table product_transactions
add constraint pt_product
foreign key (product_id)
references products(id);

alter table product_transactions
add constraint pt_transactions
foreign key (transaction_id)
references transactions(id);

# Ejercicio 1
-- Necesitamos conocer el número de veces que se ha vendido cada producto. 

select product_id, count(product_id) as veces_vendidos
from product_transactions
group by product_id;
