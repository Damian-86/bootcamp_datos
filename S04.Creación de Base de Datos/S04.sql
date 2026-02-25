# NIVEL 1 

-- Descarga los archivos CSV, estudiales y diseña una base de datos con un esquema de estrella que contenga, 
-- al menos 4 tablas de las que puedas realizar las siguientes consultas:

-- 1) creacion de BBDD sprint4:

drop database sprint4;
create database sprint4;

-- 2) creo tabla users (para simplificar american_users y european_users), credit_card, companies y transactions:

use sprint4;

create table users (
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
    region enum('America','Europe')
);

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

create table companies (
	company_id varchar(50) primary key,
    company_name varchar(50),
    phone varchar(40),
    email varchar(50),
    country varchar(50),
    website varchar(50)
);			

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

-- 3) cargar las tablas con los archivos csv y agregar datos de region en american_users y european_users.

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/S04_datos/american_users.csv'
into table users
fields terminated by ','
enclosed by '"'
ignore 1 rows
(id, name, surname, phone, email, birth_date, country, city, postal_code, address)
set region = "America";

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/S04_datos/european_users.csv'
into table users
fields terminated by ','
enclosed by '"'
ignore 1 rows
(id, name, surname, phone, email, birth_date, country, city, postal_code, address)
set region = "Europe";

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

-- 4) relacionar tablas users con transactions:

alter table transactions
add constraint users_transactions
foreign key (user_id)
references users(id);

# Ejercicio 1
-- Realiza una subconsulta que muestre a todos los usuarios con más de 80 transacciones utilizando al menos 2 tablas.

select u.id, 
	   u.name as name,
       u.surname as surname,
       count(t.id) as transaction_count
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
       avg(t.amount) as avg_amount, 
       c.company_name as company
from transactions as t
join companies as c on c.company_id = t.business_id
join credit_card as card on card.id = t.card_id
where c.company_name = "Donec Ltd"
group by card.iban
order by avg_amount desc; 

# NIVEL 2 

-- Crea una nueva tabla que refleje el estado de las tarjetas de crédito basado en si las tres últimas transacciones 
-- han sido declinadas entonces es inactivo, si al menos una no es rechazada entonces es activo . 

create table card_status (
	card_id varchar(20) primary key, 
    status varchar(20)
);

insert into card_status (card_id, status)
select card_id,
	   case when sum(declined) = 3 then 'Inactive'
	   else 'Active'
	   end as status
from (select card_id,
			 declined,
		     row_number() over(
				partition by card_id
				order by date(timestamp) desc
			 ) as sort_order
	  from transactions) t
where sort_order <= 3
group by card_id;

select * from card_status;

-- Partiendo de esta tabla responde:

# Ejercicio 1
-- ¿Cuántas tarjetas están activas? 

select count(status) as active_count
from card_status
where status = "Active";

# NIVEL 3 

-- Crea una tabla con la que podamos unir los datos del nuevo archivo products.csv con la base de datos creada, 
-- teniendo en cuenta que desde transaction tienes product_ids. Genera la siguiente consulta:

-- 1) crear tabla products

create table products (
	id int primary key,
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

create table product_transactions (
	transaction_id varchar(50), 
    product_id int,
    primary key (transaction_id, product_id)
    );

-- 4) desde transactions insertamos los registros transaction_id y product_id los obtendremos utilizando JSON 
-- para separarlos en columnas distintas.

insert into product_transactions (transaction_id, product_id)
select 
    t.id,
    j.value as product_id
from transactions t
join json_table(                     -- interpreta el texto como json
    concat('[', t.product_ids, ']'), -- esto me deja los arrays asi [1,2,3] donde las comas son parte de la sintaxis oficial de json
    '$[*]' columns (                 -- esto me dice: devuelveme cada elemento del array en filas separadas ($ -> el documento completo, [*] -> cada elemento del array)
        value int path '$'           -- cada elemento se convierte directamente a entero
    )
) AS j;

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

select product_id, count(product_id) as times_sold
from product_transactions
group by product_id;
