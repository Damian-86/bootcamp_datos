
# NIVEL 1

# Ejercicio 2
-- Utilizando JOIN realizarás las siguientes consultas:

-- Listado de los países que están generando ventas.

select distinct c.country 
from transaction t
join company c on c.id = t.company_id
where t.declined = 0;

-- Desde cuántos países se generan las ventas.

select count(distinct c.country) cantidad_paises
from transaction t
join company c on c.id = t.company_id
where t.declined = 0;

-- Identifica a la compañía con la mayor media de ventas.

select c.id, 
       round(avg(t.amount), 2) media_ventas
from transaction t
join company c on c.id = t.company_id
group by c.id
order by media_ventas desc 
limit 1 ;

# Ejercicio 3
-- Utilizando sólo subconsultas (sin utilizar JOIN):

-- Muestra todas las transacciones realizadas por empresas de Alemania.

select *
from transaction 
where company_id in (select id
					 from company 
					 where country = "Germany"
                     );

-- Lista las empresas que han realizado transacciones por un amount superior a la media de todas las transacciones.

select *
from company
where id in (select company_id
			 from transaction
			 where amount > (select avg(amount) "media_ventas"
							 from transaction)
			 );

-- Eliminarán del sistema las empresas que carecen de transacciones registradas, entrega el listado de estas empresas.

-- con not in --
select *
from company
where id not in (select company_id
				 from transaction);
 
-- con not exists --
select *
from company c
where not exists (select 1
					   from transaction t
                       where c.id = t.company_id);

# NIVEL 2

# Ejercicio 1
-- Identifica los cinco días que se generó la mayor cantidad de ingresos en la empresa por ventas. 

select company_id, 
       dia, 
       total_ingresos 
from (select company_id, 
      date(timestamp) dia, 
      sum(amount) total_ingresos, 
      dense_rank() over( 
      partition by company_id 
      order by sum(amount) desc) ranking 
from transaction 
group by company_id, date(timestamp)) tabla_rankeada 
where ranking <= 5;

-- Muestra la fecha de cada transacción junto con el total de las ventas.

select date(timestamp) fecha, 
       sum(amount) total_ventas
from transaction
group by date(timestamp)
order by fecha desc;

# Ejercicio 2
-- ¿Cuál es la media de ventas por país? Presenta los resultados ordenados de mayor a menor medio.

select c.country pais, 
       round(avg(t.amount),2) media_ventas
from transaction t
join company c on c.id = t.company_id
group by c.country
order by media_ventas desc;

# Ejercicio 3
-- En tu empresa, se plantea un nuevo proyecto para lanzar algunas campañas publicitarias para hacer competencia a la compañía “Non Institute”. 
-- Para ello, te piden la lista de todas las transacciones realizadas por empresas que están ubicadas en el mismo país que esta compañía.

-- con join --       
select * 
from transaction t
join company c on t.company_id = c.id
where country = "United Kingdom";

-- Muestra el listado aplicando JOIN y subconsultas.

select *
from transaction t 
join (select *
	  from company c
      where country = "United Kingdom") c_uk 
      on c_uk.id = t.company_id ; 

-- Muestra el listado aplicando solo subconsultas.

-- con in --
select * 
from transaction t
where company_id in (select id 
	   from company
       where country = "United Kingdom");

-- con exists --
select *
from transaction t 
where exists (select 1
			  from company c
              where t.company_id = c.id
              and c.country = "United Kingdom");

# NIVEL 3

# Ejercicio 1
-- Presenta el nombre, teléfono, país, fecha y amount, de aquellas empresas que realizaron transacciones con un valor comprendido entre 350 y 400 euros
-- y en alguna de estas fechas: 29 de abril de 2015, 20 de julio de 2018 y 13 de marzo de 2024. Ordena los resultados de mayor a menor cantidad.

select c.company_name,
	   c.phone,
	   c.country, 
       date(t.timestamp) as fecha, 
       t.amount
from transaction t
join company c on t.company_id = c.id
where t.amount between 350 and 400
and date(t.timestamp) in ("2015-04-29", "2018-07-20", "2024-03-13")
order by t.amount desc;

# Ejercicio 2
-- Necesitamos optimizar la asignación de los recursos y dependerá de la capacidad operativa que se requiera, 
-- por lo que te piden la información sobre la cantidad de transacciones que realizan las empresas, 
-- pero el departamento de recursos humanos es exigente y quiere un listado de las empresas en las que especifiques si tienen más de 400 transacciones o menos.

-- con case when para agregar el nivel_transacciones a la tabla
select c.id, 
       c.company_name, 
       count(*) as cantidad_transaccines,
       case when count(*) > 400 then 'Más de 400'
	   else '400 o menos'
	   end as nivel_transacciones
from transaction t
join company c on t.company_id = c.id
group by c.id, c.company_name;

-- con if
select c.company_name, c.id, 
       if (count(t.amount) > 400, 'mas de 400', 'menos de 400') as conteo_transacciones
from company c
join transaction t on c.id = t.company_id
group by c.company_name, c.id;


