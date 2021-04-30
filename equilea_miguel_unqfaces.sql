-- Punto 1) 

CREATE TABLE carrera(
id serial PRIMARY KEY, 
nombre VARCHAR(200)
);

CREATE TABLE usuario(
  id serial PRIMARY KEY ,
  nombre VARCHAR(100),
  apellido VARCHAR(100),
  username VARCHAR(30),
  contrasenia VARCHAR(30),
  fecha_nacimiento DATE,
  email VARCHAR(100),
  id_carrera int,

  CONSTRAINT id_carrera_fk FOREIGN KEY (id_carrera) REFERENCES carrera(id) 
);

CREATE TABLE grupo(
 id serial PRIMARY KEY,
 nombre_grupo VARCHAR(100),
 requiere_invitacion BOOLEAN
);

CREATE TABLE grupo_usuario(
id_grupo INT,
id_user INT,
 PRIMARY KEY (id_grupo,id_user),
 CONSTRAINT id_grupo_fk FOREIGN KEY (id_grupo) REFERENCES grupo(id),
 CONSTRAINT id_user_fk FOREIGN KEY (id_user) REFERENCES usuario(id)
);

CREATE TABLE publicacion(
 id serial PRIMARY KEY,
 id_user INT ,
 id_grupo INT,
 titulo VARCHAR(100),
 contenido VARCHAR(300),
 fecha_publicacion TIMESTAMP,
 CONSTRAINT id_grupo_fk FOREIGN KEY (id_grupo) REFERENCES grupo(id),
 CONSTRAINT id_user_fk FOREIGN KEY (id_user) REFERENCES usuario(id)
  );


CREATE TABLE comentario(
 id serial PRIMARY KEY,
 id_public INT ,
 id_user INT,
 contenido VARCHAR(300),
 fecha_comentario TIMESTAMP,
 CONSTRAINT id_user_fk FOREIGN KEY (id_user) REFERENCES usuario(id),
 CONSTRAINT id_public_fk FOREIGN KEY (id_public) REFERENCES publicacion(id)
);

CREATE TABLE like_publicacion(
  id_public INT ,
  id_user INT,
  positivo BOOLEAN,
  fecha TIMESTAMP,
  PRIMARY KEY (id_public,id_user),
 CONSTRAINT id_user_fk FOREIGN KEY (id_user) REFERENCES usuario(id),
 CONSTRAINT id_public_fk FOREIGN KEY (id_public) REFERENCES publicacion(id)
 );

CREATE TABLE like_comentario(
  id_coment INT, 
  id_user INT,
  positivo BOOLEAN, 
  fecha TIMESTAMP,
  PRIMARY KEY (id_coment,id_user), 
  CONSTRAINT id_user_fk FOREIGN KEY (id_user) REFERENCES usuario(id),
  CONSTRAINT id_coment_fk FOREIGN KEY (id_coment) REFERENCES comentario(id)
);

--2)
ALTER TABLE usuario 
DROP CONSTRAINT id_carrera_fk ; 

ALTER TABLE usuario
DROP COLUMN id_carrera ; 

CREATE TABLE carrera_usuario(
 id_carrera int, 
 id_user int,
 PRIMARY KEY (id_carrera,id_user),
 CONSTRAINT id_carrera_fk FOREIGN KEY (id_carrera) REFERENCES carrera(id), 
 CONSTRAINT id_user_fk FOREIGN KEY (id_user) REFERENCES usuario(id)

);

--3)
INSERT INTO carrera VALUES (1, 'Tecnicatura en Programación');
INSERT INTO usuario VALUES (101,'Matias',' Silvestre','canapedemondongo','Dal41lama','9/11/2000','');
INSERT INTO carrera_usuario VALUES (1,101); 

--4)
-- antes de insertar los datos hay que alterar la contrasenia por que hay valores que exeden los 30 caracteres:
ALTER TABLE usuario ALTER COLUMN contrasenia TYPE  varchar(100);
-- y ademas hay que comentar el :INSERT INTO carrera VALUES (1, 'Tecnicatura en Programación'), por que se inserto en el punto 3
--5)

SELECT  nombre,cantidad as cant_alu
FROM carrera JOIN 
(SELECT id_carrera, count (id_user) AS cantidad
FROM carrera_usuario
GROUP BY id_carrera
 ) AS carreras ON carrera.id = carreras.id_carrera;

--6)


SELECT DISTINCT nombre , apellido , username 
FROM (SELECT id_public, id_coment , id_usuario, nombre , apellido, username
      FROM (SELECT id_public , count(positivo) as likes
      FROM like_publicacion
      WHERE positivo = true 
      group by id_public 
      having count(positivo) >=10
      order by id_public asc) AS publicCon10OMasLikes  NATURAL JOIN 
                                  (SELECT id_public,id AS id_coment, id_usuario , nombre , apellido,username
                                   FROM comentario 
                                   NATURAL JOIN (SELECT id_user AS id_usuario , id AS id_public, nombre ,apellido ,username
                                   FROM publicacion NATURAL JOIN 
                                   (SELECT DISTINCT id AS id_user, nombre, apellido ,username 
                                    FROM usuario ) AS usuarios) 
                                    AS usuarioYPublicacion 
                                    order by id_public asc) AS r1) AS userConPublicPositivas NATURAL JOIN 
                                                                                             (SELECT id_coment
                                                                                              FROM like_comentario
                                                                                              WHERE positivo = true 
                                                                                              EXCEPT 
                                                                                              SELECT id_coment
                                                                                              FROM like_comentario
                                                                                              WHERE positivo=false
                                                                                              order by id_coment asc) AS comentSinDislikes ;


--7)
SELECT DISTINCT nombre , apellido , username ,email
FROM (SELECT id_public, id_coment , id_usuario, nombre , apellido, username,email
      FROM (SELECT id_public
            FROM(SELECT id_public , count(positivo) as likes
            FROM like_publicacion
            WHERE positivo = true 
            group by id_public 
            having count(positivo) >=10
            order by id_public asc) AS publicLikes  
             NATURAL JOIN                                        
            (SELECT id_public,count(positivo) as dislikes  
            FROM like_publicacion
            WHERE positivo= false
            GROUP BY id_public) AS publicDislikes 
            WHERE likes > dislikes
            ) AS publicConMasLikesQueDislikes  NATURAL JOIN 
                                  (SELECT id_public,id AS id_coment, id_usuario , nombre , apellido,username ,email
                                   FROM comentario 
                                   NATURAL JOIN (SELECT id_user AS id_usuario , id AS id_public, nombre ,apellido ,username,email
                                   FROM publicacion NATURAL JOIN 
                                   (SELECT DISTINCT id AS id_user, nombre, apellido ,username ,email
                                    FROM usuario ) AS usuarios) 
                                    AS usuarioYPublicacion 
                                    order by id_public asc) AS r1) AS userConPublicPositivas NATURAL JOIN 
                                                                                             (SELECT id_coment
                                                                                              FROM like_comentario
                                                                                              WHERE positivo = true 
                                                                                              EXCEPT 
                                                                                              SELECT id_coment
                                                                                              FROM like_comentario
                                                                                              WHERE positivo=false
                                                                                              order by id_coment asc) AS comentSinDislikes ;


--8)


SELECT id_grupo,nombre_grupo, likes
FROM (SELECT id_grupo,nombre_grupo,sum as likes
FROM grupo JOIN    ( SELECT  id_grupo ,sum(likes) 
                           FROM publicacion NATURAL JOIN 
                           (SELECT id_public as id , count(positivo) as likes
                            FROM like_publicacion
                            WHERE positivo = true 
                             group by id_public) likesDePublicaciones 
                            GROUP BY id_grupo) AS grupoConLikes  ON grupo.id = grupoConLikes.id_grupo) grupoNombreYLikes NATURAL JOIN            
 
(SELECT id as id_grupo
FROM grupo
EXCEPT
SELECT id_grupo
FROM grupo_usuario NATURAL JOIN  
(SELECT id as id_user , date_part( 'year',age(fecha_nacimiento)) as edad
 FROM usuario
 WHERE date_part( 'year',age(fecha_nacimiento)) =16 ) AS usuariosCon16)   AS grupoConMayoresDe16                                                
ORDER BY likes DESC LIMIT 6;                                                                 
 
--9)
SELECT username, sum (cantDeGrupos) as cantidadGrupos
FROM
((SELECT username, cantDeGrupos
FROM (SELECT id_user as id, count(id_grupo) as cantDeGrupos
FROM grupo_usuario
GROUP BY id_user 
ORDER BY id_user ASC) AS usuarios NATURAL JOIN usuario 
ORDER BY username , cantDeGrupos ASC)
UNION ALL 
(SELECT username , count(nombre) - 1 as cantDeGrupos   
FROM usuario
GROUP BY username)) as usuarios 
GROUP BY username;

--10)

SELECT *
FROM (SELECT id_coment,count (positivo) FILTER (WHERE positivo = true) as likes, count(positivo) FILTER (WHERE positivo = false) as dislikes
      FROM like_comentario
      GROUP BY id_coment
      HAVING count (positivo) FILTER (WHERE positivo = false)> 3) AS comentarioConLikesYDislikes
            NATURAL JOIN 

          (SELECT id as id_coment,contenidoPublicacion,fecha_comentario ,contenido as contenidoComentario  
           FROM comentario NATURAL JOIN (SELECT id as id_public , contenido as contenidoPublicacion
                                         FROM publicacion) AS publicaciones)  AS publicacionYComentario

 ORDER BY  dislikes, fecha_comentario DESC; 

--11)
SELECT nombre,apellido, titulo,contenido , fecha_publicacion
FROM  (SELECT * 
       FROM publicacion  NATURAL JOIN  (SELECT id as id_user, nombre , apellido
                                         FROM usuario) AS usuarios ) AS publicacionesConAutor

                              NATURAL JOIN    

                                       (SELECT DISTINCT id_public as id
                                       FROM like_publicacion
                                       WHERE positivo = false) AS publicacionesConDislikes ;

--12)



SELECT id_grupo, avg(edad),max(edad) as major ,min(edad) as menor 
FROM grupo_usuario NATURAL JOIN  (SELECT id as id_user , date_part( 'year',age(fecha_nacimiento)) as edad
                                  FROM usuario) AS edadDeUsuarios
GROUP BY id_grupo 
ORDER BY id_grupo ASC;


--13)
-- esta consulta devuelve el usuario y las carreras que cursa junto a los usuarios que les dio like con sus carreras. 
-- mi idea era hacer una consulta mas donde agrupa a los usuarios con sus carreras y las carreras de las personas que dio like :
-- select usuarioQueDioLike , ARRAY_AGG(carreraDeUsuarioQueDioLike) as carrerasDeUsuario, ARRAY_AGG(carreraDeUsuarioQueRecibioLike) as carrerasDeLosOtros
-- from (de la consulta que hice antes )  y despues quedarme con los usuarios que la interseccion de carrerasDeUsuario Y carreras de los otros sea vacio 
-- pero no se como hacer esa pregunta  de la interseccion.

SELECT usuarioQueDioLike, nombre_carrera_2 as carreraDeUsuarioQueDioLike, usuarioQueRecibioLike , nombre_carrera as carreraDeUsuarioQueRecibioLike  
FROM  
(SELECT *
FROM 
  ((SELECT DISTINCT  usuarioQueDioLike,id_user as usuarioQueRecibioLike  
   FROM publicacion NATURAL JOIN 
                               (SELECT  id_public as id,id_user as usuarioQueDioLike
                               FROM like_publicacion
                               WHERE positivo = true ) AS likesQueDieronLosUsuariosEnPublicaciones
   ORDER BY usuarioQueDioLike ASC)

   UNION 

   (SELECT usuarioQueDioLike,id_user as usuarioQueRecibioLike
    FROM comentario
    JOIN                
   (SELECT  id_coment, id_user as usuarioQueDioLike 
    FROM like_comentario
    WHERE positivo= true) AS usuariosQueDieronLikeAComentarios  
    ON comentario.id = usuariosQueDieronLikeAComentarios.id_coment)) AS userQueLikeoYFueLikeado 

JOIN (SELECT id_carrera , id_user, nombre as nombre_carrera
     FROM carrera_usuario JOIN carrera ON carrera_usuario.id_carrera = carrera.id
     ORDER BY id_user asc) AS  carrerasConSusUsuarios

ON userQueLikeoYFueLikeado. usuarioQueRecibioLike = carrerasConSusUsuarios.id_user ) AS usersConLosLikesHechos                                  

JOIN (SELECT id_carrera , id_user, nombre as nombre_carrera_2
     FROM carrera_usuario JOIN carrera ON carrera_usuario.id_carrera = carrera.id
     ORDER BY id_user asc) as carrerasYSusUsuarios
ON usersConLosLikesHechos.usuarioQueDioLike = carrerasYSusUsuarios.id_user







--14)
SELECT *
FROM comentario NATURAL JOIN  (SELECT  id_user , max(fecha_comentario) as fecha_comentario
                               FROM comentario 
                               GROUP BY id_user
                               ORDER BY id_user) AS ultimoComentario ;






--15) 
SELECT nombre,apellido, username, email, carreras
FROM usuario  JOIN 
(SELECT id_user, ARRAY_AGG(nombre_carrera) as carreras
FROM 
((SELECT id as id_user 
FROM usuario)
 EXCEPT
((((SELECT DISTINCT id_user
FROM publicacion ) 
UNION
(SELECT DISTINCT id_user 
FROM comentario))
UNION
(SELECT DISTINCT id_user 
FROM like_publicacion))
UNION 
(SELECT DISTINCT id_user
FROM like_comentario))) AS usuariosSinActividad 
 NATURAL JOIN    
        (SELECT id_carrera, id_user, nombre as nombre_carrera
        FROM carrera JOIN carrera_usuario ON carrera.id = carrera_usuario.id_carrera) AS carrerasDeUsuarios
 GROUP BY id_user ) as usuariosCarreras               

ON usuario.id = usuariosCarreras.id_user 


--16)
SELECT  nombre || '-'|| apellido as nyap, age (fecha_nacimiento)
from usuario;

--17)

CREATE VIEW ultimaPublicacion AS
SELECT username,contenido,fecha_publicacion
FROM 
(SELECT id_user, max (fecha_publicacion) as fecha_publicacion
FROM publicacion 
GROUP BY id_user
ORDER BY id_user ASC ) AS fechaUltimaPublicacion NATURAL JOIN  (SELECT *
                                                               FROM  publicacion JOIN usuario ON publicacion.id_user = usuario.id ) AS usuarios ;

-- 18)
SELECT contenido, username, fecha_publicacion ,  likes, dislikes , cantidadComentarios
FROM 
(SELECT contenido, username, fecha_publicacion , id_public,likes,dislikes
FROM 
(select *
from
(select contenido, username , fecha_publicacion
from usuario NATURAL JOIN ultimaPublicacion) AS R
NATURAL JOIN 
publicacion) AS r2
 JOIN 

(SELECT id_public , count (positivo) FILTER  (WHERE positivo = true) as likes , count(positivo) FILTER (WHERE positivo = false) as dislikes
FROM like_publicacion
GROUP BY id_public) as r3

ON r2.id = r3.id_public) AS datosDePublicacion
 NATURAL JOIN 

(SELECT id_public, count(id) as cantidadComentarios   
FROM comentario
GROUP BY id_public
ORDER BY id_public) cantidadDeComentarios



--19)
SELECT username,cantLikes, cantDislikes , (cantLikes-cantDislikes) as diferencia
FROM
(SELECT id_user as id, sum (likes) as cantLikes , sum(dislikes) as cantDislikes 
FROM
((SELECT id_user, sum (cantLikes) as likes , sum(cantDislikes) as dislikes
FROM
((SELECT id_user,sum (likes) as cantLikes ,sum (dislikes) as cantDislikes  
FROM 
(SELECT id_public as id, count (positivo) FILTER  (WHERE positivo = true) as likes , count(positivo) FILTER (WHERE positivo = false) as dislikes
FROM like_publicacion
GROUP BY id_public) as likesPublic
 NATURAL JOIN publicacion
GROUP BY id_user)
UNION ALL
(SELECT  id_user ,sum(likes) as cantLikes, sum(dislikes) as cantDislikes 
FROM comentario NATURAL JOIN
(SELECT id_coment as id , count (positivo) FILTER (WHERE positivo = true) as likes, count(positivo) FILTER (WHERE positivo = false) as dislikes
FROM like_comentario 
GROUP BY id_coment) AS likesComent
GROUP BY id_user)) AS likesTotales
GROUP BY id_user
ORDER BY id_user)

UNION ALL 

(SELECT id as id_user, (count (nombre) - 1) AS likes  , (count(nombre )-1) as dislikes
FROM usuario 
GROUP BY id) ) AS dislikesYLikes
GROUP BY id_user ) as likesYDislikes  NATURAL JOIN  usuario
ORDER BY diferencia ASC ;




--20)

CREATE TABLE log_publicacion (
id_log  serial PRIMARY KEY ,
fecha_log date,
accion_log varchar(1),
id  int ,
id_user int ,
id_grupo int,
titulo   varchar(100),
contenido  varchar(300),
fecha_publicacion TIMESTAMP
);

CREATE TABLE log_comentario(

id_log serial PRIMARY KEY ,
fecha_log  date,
accion_log varchar(1),
id  int,
id_public int ,
id_user int ,
contenido varchar(300),
fecha_comentario TIMESTAMP
); 


 CREATE FUNCTION  lg_publicacion() RETURNS TRIGGER AS $$
  DECLARE 
  Fecha date = current_date ; 

  BEGIN 

    IF (TG_OP = 'UPDATE ') THEN 

    INSERT INTO log_publicacion(fecha_log,accion_log,id,id_user,id_grupo,titulo,contenido,fecha_publicacion)
     VALUES (Fecha,'U',old.id,old.id_user,old.id_grupo,old.titulo,old.contenido,old.fecha_publicacion);

    RETURN NEW ;

    ELSIF (TG_OP = 'INSERT') THEN 

    INSERT INTO log_publicacion(fecha_log,accion_log,id,id_user,id_grupo,titulo,contenido,fecha_publicacion)  
    VALUES (Fecha,'I',new.id,new.id_user,new.id_grupo,new.titulo,new.contenido,new.fecha_publicacion);

    RETURN NEW ;                         

    ELSIF (TG_OP='DELETE') THEN 

     INSERT INTO log_publicacion(fecha_log,accion_log,id,id_user,id_grupo,titulo,contenido,fecha_publicacion) 
     VALUES (Fecha,'D',old.id,old.id_user,old.id_grupo,old.titulo,old.contenido,old.fecha_publicacion);

    RETURN OLD;

    END IF;
    END 
   $$
   LANGUAGE plpgsql;


CREATE TRIGGER tg_publicacion BEFORE UPDATE OR INSERT OR DELETE ON publicacion
FOR EACH ROW EXECUTE PROCEDURE lg_publicacion();  





 CREATE FUNCTION  lg_comentario() RETURNS TRIGGER AS $$
  DECLARE 
  Fecha date = current_date ; 

  BEGIN 

    IF (TG_OP = 'UPDATE ') THEN 

    INSERT INTO log_comentario(fecha_log,accion_log,id,id_public,id_user,contenido,fecha_comentario)
     VALUES (Fecha,'U',old.id,old.id_public,old.id_user,old.contenido,old.fecha_comentario);

    RETURN NEW ;

    ELSIF (TG_OP = 'INSERT') THEN 

    INSERT INTO log_comentario(fecha_log,accion_log,id,id_public,id_user,contenido,fecha_comentario)
     VALUES (Fecha,'I',new.id,new.id_public,new.id_user,new.contenido,new.fecha_comentario);

    RETURN NEW ;                         

    ELSIF (TG_OP='DELETE') THEN 

     INSERT INTO log_comentario(fecha_log,accion_log,id,id_public,id_user,contenido,fecha_comentario)
     VALUES (Fecha,'D',old.id,old.id_public,old.id_user,old.contenido,old.fecha_comentario);
    RETURN OLD;

    END IF;
    END 
   $$
   LANGUAGE plpgsql;



CREATE TRIGGER tg_comentario BEFORE UPDATE OR INSERT OR DELETE ON comentario
FOR EACH ROW EXECUTE PROCEDURE lg_comentario();  


--21)

/*
estas consultas verifican que el triger funciona
select *
from log_publicacion

select *
from log_comentario
*/

INSERT INTO publicacion (id_user, id_grupo, titulo, contenido, fecha_publicacion)
VALUES (30,8,'primavera',' se termina primavera y se acerca navidad', '2018-11-20 16:01:45');
INSERT INTO publicacion (id_user, id_grupo, titulo, contenido, fecha_publicacion)
VALUES (30,15,'fin de cursada','si aprovaste todo te tomas unas vacaciones tranquilas','2018-11-20 17:01:45');

INSERT INTO comentario (id_public , id_user , contenido, fecha_comentario)
VALUES (1,64,'jajajjaaja','2016-11-20 17:01:45') ;
INSERT INTO comentario (id_public , id_user , contenido, fecha_comentario)
VALUES (9,64,'jajajjaja','2015-11-20 17:01:45') ;
