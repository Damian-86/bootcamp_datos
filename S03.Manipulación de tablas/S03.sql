
# NIVEL 1

# Ejercicio 1
-- Tu tarea es diseñar y crear una tabla llamada "credit_card" que almacene detalles cruciales sobre las tarjetas de crédito. 
-- La nueva tabla debe ser capaz de identificar de forma única cada tarjeta y establecer una relación adecuada con las otras dos tablas ("transaction" y "company"). 
-- Después de crear la tabla será necesario que ingreses la información del documento denominado "datos_introducir_credit". 
-- Recuerda mostrar el diagrama y realizar una breve descripción del mismo.

use transactions;

drop table if exists credit_card;
create table credit_card (
    id varchar(20) primary key,
    iban varchar(40),
    pan varchar(20),
    pin varchar(5),
    cvv varchar(5),
    expiring_date varchar(10)
);

-- correr informacion de archivo "datos_introducir_credit"

update credit_card
set expiring_date = str_to_date(expiring_date, '%m/%d/%y')
where id != '';

alter table credit_card
modify expiring_date date; -- para que se modifique en la tabla

alter table transaction
add constraint card_transaction
foreign key (credit_card_id)
references credit_card(id);

# Ejercicio 2
-- El departamento de Recursos Humanos ha identificado un error en el número de cuenta asociado a su tarjeta de crédito con ID CcU-2938. 
-- La información que debe mostrarse para este registro es: TR323456312213576817699999. Recuerda mostrar que el cambio se realizó.
  
update credit_card 
set iban = 'TR323456312213576817699999'
where id = 'CcU-2938';

select iban
from credit_card
where id = 'CcU-2938';

# Ejercicio 3
-- En la tabla "transaction" ingresa una nueva transacción con la siguiente información:
-- Id	108B1D1D-5B23-A76C-55EF-C568E49A99DD
-- credit_card_id	CcU-9999
-- company_id	b-9999
-- user_id	9999
-- lat	829.999
-- longitude  -117.999
-- amount	111.11
-- declined	0
  
insert into credit_card (id)  values ('CcU-9999');
insert into company (id)  values ('b-9999');
insert into transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined) 
values ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, 111.11, 0);

# Ejercicio 4
-- Desde recursos humanos te solicitan eliminar la columna "pan" de la tabla credit_card. Recuerda mostrar el cambio realizado.

alter table credit_card
drop column pan; 

select *
from credit_card;

# NIVEL 2

# Ejercicio 1
-- Elimina de la tabla transacción el registro con ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de datos.

delete from transaction 
where id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

# Ejercicio 2
-- La sección de marketing desea tener acceso a información específica para realizar análisis y estrategias efectivas. 
-- Se ha solicitado crear una vista que proporcione detalles clave sobre las compañías y sus transacciones. 
-- Será necesaria que crees una vista llamada VistaMarketing que contenga la siguiente información: Nombre de la compañía. 
-- Teléfono de contacto. País de residencia. Media de compra realizado por cada compañía. 
-- Presenta la vista creada, ordenando los datos de mayor a menor promedio de compra.

create view vistamarketing as
select c.company_name, 
       c.phone, 
       c.country, 
       round(avg(t.amount),2) as average_purchase
from company c
join transaction t on c.id = t.company_id
group by c.id, c.company_name
order by average_purchase desc;

select * 
from vistamarketing;

# Ejercicio 3
-- Filtra la vista VistaMarketing para mostrar sólo las compañías que tienen su país de residencia en "Germany"

select *
from vistamarketing
where country = "Germany";

# NIVEL 3

# Ejercicio 1
-- La próxima semana tendrás una nueva reunión con los gerentes de marketing. 
-- Un compañero de tu equipo realizó modificaciones en la base de datos, pero no recuerda cómo las realizó. 
-- Te pide que le ayudes a dejar los comandos ejecutados para obtener el siguiente diagrama:

-- 1) Corremos "estructura_datos_user"  para crear tabla user y ejecutamos "datos_introducir_user" para insertar datos.

-- 2) En tabla user hacemos: 
      -- cambio nombre de user a data_user
      -- pasar id char(10) a int
      -- cambio nombre email a personal_email
      
rename table user to data_user;    
alter table data_user
modify column id int,
rename column email to personal_email;


-- 3) En tabla company eliminamos columna website.

alter table company
drop column website;

-- 4) En tabla transaction cambiamos credit_card_id varchar(15) a varchar(20).

alter table transaction
modify column credit_card_id varchar(20);

-- 5) En tabla credit_card cambiar:
      -- iban varchar(40) a varchar(50)
      -- pin varchar(5) a varchar(4)
      -- cvv varchar(5) a int
      -- expiring_date date a varchar(20)
      -- agregar columna fecha_actual date
      
alter table credit_card
modify column iban varchar(50),
modify column pin varchar(4),
modify column cvv int,
modify column expiring_date varchar(20),
add column fecha_actual date;

-- 6) Buscamos datos huerfano en columna id de tabla data_user y lo agregamos a la tabla.

select distinct t.user_id
from transaction t 
left join data_user d on t.user_id = d.id
where d.id is null;

insert into data_user (id) values (9999);

-- 7) Creamos relación entre data_user y transaction.

alter table transaction
add constraint user_transaction
foreign key (user_id)
references data_user(id);

# Ejercicio 2
-- La empresa también le pide crear una vista llamada "InformeTecnico" que contenga la siguiente información:

-- ID de la transacción
-- Nombre del usuario/a
-- Apellido del usuario/a
-- IBAN de la tarjeta de crédito usada.
-- Nombre de la compañía de la transacción realizada.
-- Asegúrese de incluir información relevante de las tablas que conocerá y utilice alias para cambiar de nombre columnas según sea necesario.
-- Muestra los resultados de la vista, ordena los resultados de forma descendente en función de la variable ID de transacción.

create view informetecnico as
select t.id as "id de transaccion",
       u.name,
	   u.surname,
       cc.iban,
       c.company_name
from transaction t
join company c on c.id = t.company_id
join data_user u ON t.user_id = u.id
join credit_card cc ON cc.id = t.credit_card_id;

select *
from informetecnico;
