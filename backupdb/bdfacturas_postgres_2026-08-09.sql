--
-- PostgreSQL database dump
--

\restrict 7eq0Cko6nE1Sw8hzdDjhx6dwgBla3sQmps4jXlG1gheWmCUY3ebbCDu4BHrnS1b

-- Dumped from database version 18.2
-- Dumped by pg_dump version 18.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.vendedor DROP CONSTRAINT IF EXISTS fk_vendedor_persona;
ALTER TABLE IF EXISTS ONLY public.rutarol DROP CONSTRAINT IF EXISTS fk_rutarol_ruta;
ALTER TABLE IF EXISTS ONLY public.rutarol DROP CONSTRAINT IF EXISTS fk_rutarol_rol;
ALTER TABLE IF EXISTS ONLY public.rol_usuario DROP CONSTRAINT IF EXISTS fk_rolusuario_usuario;
ALTER TABLE IF EXISTS ONLY public.rol_usuario DROP CONSTRAINT IF EXISTS fk_rolusuario_rol;
ALTER TABLE IF EXISTS ONLY public.productosporfactura DROP CONSTRAINT IF EXISTS fk_prodfact_producto;
ALTER TABLE IF EXISTS ONLY public.productosporfactura DROP CONSTRAINT IF EXISTS fk_prodfact_factura;
ALTER TABLE IF EXISTS ONLY public.factura DROP CONSTRAINT IF EXISTS fk_factura_vendedor;
ALTER TABLE IF EXISTS ONLY public.factura DROP CONSTRAINT IF EXISTS fk_factura_cliente;
ALTER TABLE IF EXISTS ONLY public.cliente DROP CONSTRAINT IF EXISTS fk_cliente_persona;
ALTER TABLE IF EXISTS ONLY public.cliente DROP CONSTRAINT IF EXISTS fk_cliente_empresa;
DROP TRIGGER IF EXISTS trg_actualizar_totales_y_stock ON public.productosporfactura;
ALTER TABLE IF EXISTS ONLY public.ruta DROP CONSTRAINT IF EXISTS uq_ruta;
ALTER TABLE IF EXISTS ONLY public.vendedor DROP CONSTRAINT IF EXISTS pk_vendedor;
ALTER TABLE IF EXISTS ONLY public.usuario DROP CONSTRAINT IF EXISTS pk_usuario;
ALTER TABLE IF EXISTS ONLY public.rutarol DROP CONSTRAINT IF EXISTS pk_rutarol;
ALTER TABLE IF EXISTS ONLY public.ruta DROP CONSTRAINT IF EXISTS pk_ruta;
ALTER TABLE IF EXISTS ONLY public.rol_usuario DROP CONSTRAINT IF EXISTS pk_rol_usuario;
ALTER TABLE IF EXISTS ONLY public.rol DROP CONSTRAINT IF EXISTS pk_rol;
ALTER TABLE IF EXISTS ONLY public.productosporfactura DROP CONSTRAINT IF EXISTS pk_productosporfactura;
ALTER TABLE IF EXISTS ONLY public.producto DROP CONSTRAINT IF EXISTS pk_producto;
ALTER TABLE IF EXISTS ONLY public.persona DROP CONSTRAINT IF EXISTS pk_persona;
ALTER TABLE IF EXISTS ONLY public.factura DROP CONSTRAINT IF EXISTS pk_factura;
ALTER TABLE IF EXISTS ONLY public.empresa DROP CONSTRAINT IF EXISTS pk_empresa;
ALTER TABLE IF EXISTS ONLY public.cliente DROP CONSTRAINT IF EXISTS pk_cliente;
ALTER TABLE IF EXISTS public.vendedor ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.ruta ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.rol ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.factura ALTER COLUMN numero DROP DEFAULT;
ALTER TABLE IF EXISTS public.cliente ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.vendedor_id_seq;
DROP TABLE IF EXISTS public.vendedor;
DROP TABLE IF EXISTS public.usuario;
DROP TABLE IF EXISTS public.rutarol;
DROP SEQUENCE IF EXISTS public.ruta_id_seq;
DROP TABLE IF EXISTS public.ruta;
DROP TABLE IF EXISTS public.rol_usuario;
DROP SEQUENCE IF EXISTS public.rol_id_seq;
DROP TABLE IF EXISTS public.rol;
DROP TABLE IF EXISTS public.productosporfactura;
DROP TABLE IF EXISTS public.producto;
DROP TABLE IF EXISTS public.persona;
DROP SEQUENCE IF EXISTS public.factura_numero_seq;
DROP TABLE IF EXISTS public.factura;
DROP TABLE IF EXISTS public.empresa;
DROP SEQUENCE IF EXISTS public.cliente_id_seq;
DROP TABLE IF EXISTS public.cliente;
DROP PROCEDURE IF EXISTS public.verificar_acceso_ruta(IN p_email character varying, IN p_fkidruta integer, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.sp_listar_facturas_y_productosporfactura(INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.sp_insertar_factura_y_productosporfactura(IN p_fkidcliente integer, IN p_fkidvendedor integer, IN p_productos json, IN p_minimo_detalle integer, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.sp_consultar_factura_y_productosporfactura(IN p_numero integer, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.sp_borrar_factura_y_productosporfactura(IN p_numero integer, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.sp_anular_factura(IN p_numero integer, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.sp_actualizar_factura_y_productosporfactura(IN p_numero integer, IN p_fkidcliente integer, IN p_fkidvendedor integer, IN p_productos json, IN p_minimo_detalle integer, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.listar_usuarios_con_roles(INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.listar_rutarol(INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.eliminar_usuario_con_roles(IN p_email character varying, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.eliminar_rutarol(IN p_fkidruta integer, IN p_fkidrol integer, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.crear_usuario_con_roles(IN p_email character varying, IN p_contrasena character varying, IN p_roles_json json, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.crear_rutarol(IN p_fkidruta integer, IN p_fkidrol integer, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.consultar_usuario_con_roles(IN p_email character varying, INOUT p_resultado json);
DROP PROCEDURE IF EXISTS public.actualizar_usuario_con_roles(IN p_email character varying, IN p_contrasena character varying, IN p_roles json, INOUT p_resultado json);
DROP FUNCTION IF EXISTS public.actualizar_totales_y_stock();
DROP PROCEDURE IF EXISTS public.actualizar_roles_usuario(IN p_email character varying, IN p_roles_json json, INOUT p_resultado json);
--
-- Name: actualizar_roles_usuario(character varying, json, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.actualizar_roles_usuario(IN p_email character varying, IN p_roles_json json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item JSON;
    v_idrol INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE email = p_email) THEN
        RAISE EXCEPTION 'Usuario % no existe', p_email;
    END IF;

    -- Eliminar los roles anteriores
    DELETE FROM rol_usuario WHERE fkemail = p_email;

    -- Insertar los nuevos roles
    FOR v_item IN SELECT * FROM json_array_elements(p_roles_json)
    LOOP
        v_idrol := (v_item->>'fkidrol')::INTEGER;
        INSERT INTO rol_usuario (fkemail, fkidrol) VALUES (p_email, v_idrol);
    END LOOP;

    -- Retornar resultado
    SELECT json_build_object(
        'email', p_email,
        'roles', (
            SELECT json_agg(json_build_object('idrol', r.id, 'nombre', r.nombre))
            FROM rol_usuario ru
            JOIN rol r ON r.id = ru.fkidrol
            WHERE ru.fkemail = p_email
        )
    ) INTO p_resultado;
END;
$$;


ALTER PROCEDURE public.actualizar_roles_usuario(IN p_email character varying, IN p_roles_json json, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: actualizar_totales_y_stock(); Type: FUNCTION; Schema: public; Owner: paradigmas
--

CREATE FUNCTION public.actualizar_totales_y_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Validar stock suficiente
        IF (SELECT stock FROM producto WHERE codigo = NEW.fkcodproducto) < NEW.cantidad THEN
            RAISE EXCEPTION 'Stock insuficiente para producto %. Stock disponible: %, cantidad solicitada: %',
                NEW.fkcodproducto,
                (SELECT stock FROM producto WHERE codigo = NEW.fkcodproducto),
                NEW.cantidad;
        END IF;
        NEW.subtotal := NEW.cantidad * (SELECT valorunitario FROM producto WHERE codigo = NEW.fkcodproducto);
        UPDATE producto SET stock = stock - NEW.cantidad WHERE codigo = NEW.fkcodproducto;
        UPDATE factura SET total = (SELECT COALESCE(SUM(subtotal),0) FROM productosporfactura WHERE fknumfactura = NEW.fknumfactura) + NEW.subtotal WHERE numero = NEW.fknumfactura;
        RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        -- Validar stock suficiente (considerando la devolucion del stock anterior)
        IF (SELECT stock FROM producto WHERE codigo = NEW.fkcodproducto) + OLD.cantidad < NEW.cantidad THEN
            RAISE EXCEPTION 'Stock insuficiente para producto %. Stock disponible: %, cantidad solicitada: %',
                NEW.fkcodproducto,
                (SELECT stock FROM producto WHERE codigo = NEW.fkcodproducto) + OLD.cantidad,
                NEW.cantidad;
        END IF;
        NEW.subtotal := NEW.cantidad * (SELECT valorunitario FROM producto WHERE codigo = NEW.fkcodproducto);
        UPDATE producto SET stock = stock + OLD.cantidad - NEW.cantidad WHERE codigo = NEW.fkcodproducto;
        UPDATE factura SET total = (SELECT COALESCE(SUM(subtotal),0) FROM productosporfactura WHERE fknumfactura = NEW.fknumfactura AND fkcodproducto != NEW.fkcodproducto) + NEW.subtotal WHERE numero = NEW.fknumfactura;
        RETURN NEW;
    END IF;
    IF TG_OP = 'DELETE' THEN
        UPDATE producto SET stock = stock + OLD.cantidad WHERE codigo = OLD.fkcodproducto;
        UPDATE factura SET total = (SELECT COALESCE(SUM(subtotal),0) FROM productosporfactura WHERE fknumfactura = OLD.fknumfactura AND fkcodproducto != OLD.fkcodproducto) WHERE numero = OLD.fknumfactura;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.actualizar_totales_y_stock() OWNER TO paradigmas;

--
-- Name: actualizar_usuario_con_roles(character varying, character varying, json, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.actualizar_usuario_con_roles(IN p_email character varying, IN p_contrasena character varying, IN p_roles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item JSON;
    v_idrol INT;
BEGIN
    -- Actualizar la contraseña solo si no está vacía
    IF p_contrasena IS NOT NULL AND p_contrasena != '' THEN
        UPDATE usuario SET contrasena = p_contrasena WHERE email = p_email;
    END IF;

    -- Eliminar los roles anteriores
    DELETE FROM rol_usuario WHERE fkemail = p_email;

    -- Insertar los nuevos roles
    FOR v_item IN SELECT * FROM json_array_elements(p_roles)
    LOOP
        v_idrol := (v_item->>'fkidrol')::INTEGER;
        INSERT INTO rol_usuario (fkemail, fkidrol) VALUES (p_email, v_idrol);
    END LOOP;

    -- Retornar resultado
    SELECT json_build_object(
        'email', p_email,
        'roles', (
            SELECT json_agg(json_build_object('idrol', r.id, 'nombre', r.nombre))
            FROM rol_usuario ru
            JOIN rol r ON r.id = ru.fkidrol
            WHERE ru.fkemail = p_email
        )
    ) INTO p_resultado;
END;
$$;


ALTER PROCEDURE public.actualizar_usuario_con_roles(IN p_email character varying, IN p_contrasena character varying, IN p_roles json, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: consultar_usuario_con_roles(character varying, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.consultar_usuario_con_roles(IN p_email character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE email = p_email) THEN
        RAISE EXCEPTION 'Usuario % no existe', p_email;
    END IF;

    SELECT json_build_object(
        'email', u.email,
        'roles', COALESCE((
            SELECT json_agg(json_build_object('idrol', r.id, 'nombre', r.nombre))
            FROM rol_usuario ru
            JOIN rol r ON r.id = ru.fkidrol
            WHERE ru.fkemail = u.email
        ), '[]'::json)
    ) INTO p_resultado
    FROM usuario u
    WHERE u.email = p_email;
END;
$$;


ALTER PROCEDURE public.consultar_usuario_con_roles(IN p_email character varying, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: crear_rutarol(integer, integer, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.crear_rutarol(IN p_fkidruta integer, IN p_fkidrol integer, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verificar si la ruta existe
    IF NOT EXISTS (SELECT 1 FROM ruta WHERE id = p_fkidruta) THEN
        p_resultado := json_build_object('success', false, 'message', 'La ruta especificada no existe');
        RETURN;
    END IF;

    -- Verificar si el rol existe
    IF NOT EXISTS (SELECT 1 FROM rol WHERE id = p_fkidrol) THEN
        p_resultado := json_build_object('success', false, 'message', 'El rol especificado no existe');
        RETURN;
    END IF;

    -- Verificar si el permiso ya existe
    IF EXISTS (SELECT 1 FROM rutarol WHERE fkidruta = p_fkidruta AND fkidrol = p_fkidrol) THEN
        p_resultado := json_build_object('success', false, 'message', 'El permiso ya existe');
        RETURN;
    END IF;

    INSERT INTO rutarol (fkidruta, fkidrol) VALUES (p_fkidruta, p_fkidrol);
    p_resultado := json_build_object('success', true, 'message', 'Permiso creado exitosamente');
END;
$$;


ALTER PROCEDURE public.crear_rutarol(IN p_fkidruta integer, IN p_fkidrol integer, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: crear_usuario_con_roles(character varying, character varying, json, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.crear_usuario_con_roles(IN p_email character varying, IN p_contrasena character varying, IN p_roles_json json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item JSON;
    v_idrol INT;
BEGIN
    -- Insertar el usuario
    INSERT INTO usuario (email, contrasena)
    VALUES (p_email, p_contrasena);

    -- Insertar los roles del usuario
    FOR v_item IN SELECT * FROM json_array_elements(p_roles_json)
    LOOP
        v_idrol := (v_item->>'fkidrol')::INTEGER;
        INSERT INTO rol_usuario (fkemail, fkidrol) VALUES (p_email, v_idrol);
    END LOOP;

    -- Retornar resultado
    SELECT json_build_object(
        'email', p_email,
        'roles', (
            SELECT json_agg(json_build_object('idrol', r.id, 'nombre', r.nombre))
            FROM rol_usuario ru
            JOIN rol r ON r.id = ru.fkidrol
            WHERE ru.fkemail = p_email
        )
    ) INTO p_resultado;
END;
$$;


ALTER PROCEDURE public.crear_usuario_con_roles(IN p_email character varying, IN p_contrasena character varying, IN p_roles_json json, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: eliminar_rutarol(integer, integer, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.eliminar_rutarol(IN p_fkidruta integer, IN p_fkidrol integer, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verificar si el permiso existe
    IF NOT EXISTS (SELECT 1 FROM rutarol WHERE fkidruta = p_fkidruta AND fkidrol = p_fkidrol) THEN
        p_resultado := json_build_object('success', false, 'message', 'El permiso no existe');
        RETURN;
    END IF;

    DELETE FROM rutarol WHERE fkidruta = p_fkidruta AND fkidrol = p_fkidrol;
    p_resultado := json_build_object('success', true, 'message', 'Permiso eliminado exitosamente');
END;
$$;


ALTER PROCEDURE public.eliminar_rutarol(IN p_fkidruta integer, IN p_fkidrol integer, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: eliminar_usuario_con_roles(character varying, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.eliminar_usuario_con_roles(IN p_email character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE email = p_email) THEN
        RAISE EXCEPTION 'Usuario % no existe', p_email;
    END IF;

    -- Eliminar roles del usuario primero (FK sin CASCADE)
    DELETE FROM rol_usuario WHERE fkemail = p_email;
    DELETE FROM usuario WHERE email = p_email;

    p_resultado := json_build_object(
        'mensaje', 'Usuario eliminado exitosamente',
        'email_eliminado', p_email
    );
END;
$$;


ALTER PROCEDURE public.eliminar_usuario_con_roles(IN p_email character varying, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: listar_rutarol(json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.listar_rutarol(INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT COALESCE(json_agg(
        json_build_object(
            'fkidruta', rr.fkidruta,
            'ruta', rt.ruta,
            'fkidrol', rr.fkidrol,
            'rol', r.nombre
        )
        ORDER BY rt.ruta, r.nombre
    ), '[]'::json) INTO p_resultado
    FROM rutarol rr
    JOIN ruta rt ON rt.id = rr.fkidruta
    JOIN rol r ON r.id = rr.fkidrol;
END;
$$;


ALTER PROCEDURE public.listar_rutarol(INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: listar_usuarios_con_roles(json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.listar_usuarios_con_roles(INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT COALESCE(json_agg(sub), '[]'::json) INTO p_resultado
    FROM (
        SELECT json_build_object(
            'email', u.email,
            'roles', COALESCE((
                SELECT json_agg(json_build_object('idrol', r.id, 'nombre', r.nombre))
                FROM rol_usuario ru
                JOIN rol r ON r.id = ru.fkidrol
                WHERE ru.fkemail = u.email
            ), '[]'::json)
        ) AS sub
        FROM usuario u
        ORDER BY u.email
    ) t(sub);
END;
$$;


ALTER PROCEDURE public.listar_usuarios_con_roles(INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: sp_actualizar_factura_y_productosporfactura(integer, integer, integer, json, integer, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.sp_actualizar_factura_y_productosporfactura(IN p_numero integer, IN p_fkidcliente integer, IN p_fkidvendedor integer, IN p_productos json, IN p_minimo_detalle integer DEFAULT 1, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item JSON;
    v_codigo VARCHAR;
    v_cantidad INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM factura WHERE factura.numero = p_numero) THEN
        RAISE EXCEPTION 'Factura % no existe', p_numero;
    END IF;

    -- Validar minimo de productos
    -- NULLIF(p_minimo_detalle, 0): la API envia 0 cuando no se pasa el parametro, NULLIF lo convierte a NULL
    -- COALESCE(..., 1): si es NULL usa 1 como default
    IF p_productos IS NULL OR json_array_length(p_productos) < COALESCE(NULLIF(p_minimo_detalle, 0), 1) THEN
        RAISE EXCEPTION 'La factura requiere minimo % producto(s).', COALESCE(NULLIF(p_minimo_detalle, 0), 1);
    END IF;

    -- Eliminar detalle anterior (el trigger restaura stock y recalcula total)
    DELETE FROM productosporfactura WHERE fknumfactura = p_numero;

    -- Insertar nuevos productos (el trigger calcula subtotal, descuenta stock, actualiza total)
    FOR v_item IN SELECT * FROM json_array_elements(p_productos)
    LOOP
        v_codigo := v_item->>'codigo';
        v_cantidad := (v_item->>'cantidad')::INTEGER;

        INSERT INTO productosporfactura (fknumfactura, fkcodproducto, cantidad, subtotal)
        VALUES (p_numero, v_codigo, v_cantidad, 0);
    END LOOP;

    -- Actualizar cliente y vendedor de la factura
    UPDATE factura
    SET fkidcliente = p_fkidcliente,
        fkidvendedor = p_fkidvendedor
    WHERE factura.numero = p_numero;

    -- Retornar resultado como JSON
    SELECT json_build_object(
        'factura', (
            SELECT row_to_json(fac) FROM (
                SELECT f.numero, f.fecha, f.total, f.estado, f.fkidcliente, f.fkidvendedor
                FROM factura f WHERE f.numero = p_numero
            ) fac
        ),
        'productos', (
            SELECT json_agg(row_to_json(det)) FROM (
                SELECT pf.fkcodproducto AS codigo_producto, pr.nombre AS nombre_producto,
                       pf.cantidad, pr.valorunitario, pf.subtotal
                FROM productosporfactura pf
                JOIN producto pr ON pr.codigo = pf.fkcodproducto
                WHERE pf.fknumfactura = p_numero
            ) det
        )
    ) INTO p_resultado;
END;
$$;


ALTER PROCEDURE public.sp_actualizar_factura_y_productosporfactura(IN p_numero integer, IN p_fkidcliente integer, IN p_fkidvendedor integer, IN p_productos json, IN p_minimo_detalle integer, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: sp_anular_factura(integer, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.sp_anular_factura(IN p_numero integer, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC;
    v_cantidad_productos BIGINT;
    v_estado VARCHAR(10);
BEGIN
    -- Validar que la factura existe
    IF NOT EXISTS (SELECT 1 FROM factura WHERE factura.numero = p_numero) THEN
        RAISE EXCEPTION 'Factura % no existe', p_numero;
    END IF;

    -- Validar que no esté ya anulada
    SELECT estado INTO v_estado FROM factura WHERE factura.numero = p_numero;
    IF v_estado = 'anulada' THEN
        RAISE EXCEPTION 'Factura % ya está anulada', p_numero;
    END IF;

    -- Restaurar stock de todos los productos de la factura
    UPDATE producto p
    SET stock = p.stock + pf.cantidad
    FROM productosporfactura pf
    WHERE p.codigo = pf.fkcodproducto AND pf.fknumfactura = p_numero;

    -- Guardar info para la respuesta
    SELECT COUNT(*) INTO v_cantidad_productos
    FROM productosporfactura WHERE fknumfactura = p_numero;

    SELECT f.total INTO v_total FROM factura f WHERE f.numero = p_numero;

    -- Cambiar estado a 'anulada'
    UPDATE factura SET estado = 'anulada' WHERE factura.numero = p_numero;

    -- Retornar resultado como JSON
    p_resultado := json_build_object(
        'mensaje', 'Factura anulada exitosamente',
        'numero_anulado', p_numero,
        'total_anulado', v_total,
        'productos_afectados', v_cantidad_productos,
        'estado', 'anulada'
    );
END;
$$;


ALTER PROCEDURE public.sp_anular_factura(IN p_numero integer, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: sp_borrar_factura_y_productosporfactura(integer, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.sp_borrar_factura_y_productosporfactura(IN p_numero integer, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC;
    v_cantidad_productos BIGINT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM factura WHERE factura.numero = p_numero) THEN
        RAISE EXCEPTION 'Factura % no existe', p_numero;
    END IF;

    -- Guardar info antes de borrar para el JSON de respuesta
    SELECT COUNT(*) INTO v_cantidad_productos
    FROM productosporfactura WHERE fknumfactura = p_numero;

    SELECT f.total INTO v_total FROM factura f WHERE f.numero = p_numero;

    -- Borrar factura (ON DELETE CASCADE borra productosporfactura,
    -- y el trigger restaura stock por cada producto eliminado)
    DELETE FROM factura WHERE factura.numero = p_numero;

    -- Retornar resultado como JSON
    p_resultado := json_build_object(
        'mensaje', 'Factura eliminada exitosamente',
        'numero_eliminado', p_numero,
        'total_eliminado', v_total,
        'productos_eliminados', v_cantidad_productos
    );
END;
$$;


ALTER PROCEDURE public.sp_borrar_factura_y_productosporfactura(IN p_numero integer, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: sp_consultar_factura_y_productosporfactura(integer, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.sp_consultar_factura_y_productosporfactura(IN p_numero integer, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM factura WHERE factura.numero = p_numero) THEN
        RAISE EXCEPTION 'Factura % no existe', p_numero;
    END IF;

    SELECT json_build_object(
        'factura', json_build_object(
            'numero', f.numero,
            'fecha', f.fecha,
            'total', f.total,
            'estado', f.estado,
            'fkidcliente', f.fkidcliente,
            'nombre_cliente', pc.nombre,
            'fkidvendedor', f.fkidvendedor,
            'nombre_vendedor', pv.nombre
        ),
        'productos', (
            SELECT json_agg(json_build_object(
                'codigo_producto', pr.codigo,
                'nombre_producto', pr.nombre,
                'cantidad', pf.cantidad,
                'valorunitario', pr.valorunitario,
                'subtotal', pf.subtotal
            ))
            FROM productosporfactura pf
            JOIN producto pr ON pr.codigo = pf.fkcodproducto
            WHERE pf.fknumfactura = f.numero
        )
    ) INTO p_resultado
    FROM factura f
    JOIN cliente c ON c.id = f.fkidcliente
    JOIN persona pc ON pc.codigo = c.fkcodpersona
    JOIN vendedor v ON v.id = f.fkidvendedor
    JOIN persona pv ON pv.codigo = v.fkcodpersona
    WHERE f.numero = p_numero;
END;
$$;


ALTER PROCEDURE public.sp_consultar_factura_y_productosporfactura(IN p_numero integer, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: sp_insertar_factura_y_productosporfactura(integer, integer, json, integer, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.sp_insertar_factura_y_productosporfactura(IN p_fkidcliente integer, IN p_fkidvendedor integer, IN p_productos json, IN p_minimo_detalle integer DEFAULT 1, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_numero INTEGER;
    v_item JSON;
    v_codigo VARCHAR;
    v_cantidad INTEGER;
BEGIN
    -- Validar minimo de productos
    -- NULLIF(p_minimo_detalle, 0): la API envia 0 cuando no se pasa el parametro, NULLIF lo convierte a NULL
    -- COALESCE(..., 1): si es NULL usa 1 como default
    IF p_productos IS NULL OR json_array_length(p_productos) < COALESCE(NULLIF(p_minimo_detalle, 0), 1) THEN
        RAISE EXCEPTION 'La factura requiere minimo % producto(s).', COALESCE(NULLIF(p_minimo_detalle, 0), 1);
    END IF;

    -- Crear la factura con total 0 (el trigger actualiza el total)
    INSERT INTO factura (fkidcliente, fkidvendedor, total)
    VALUES (p_fkidcliente, p_fkidvendedor, 0)
    RETURNING factura.numero INTO v_numero;

    -- Recorrer cada producto del JSON e insertar detalle
    -- El trigger calcula subtotal, descuenta stock y actualiza total
    FOR v_item IN SELECT * FROM json_array_elements(p_productos)
    LOOP
        v_codigo := v_item->>'codigo';
        v_cantidad := (v_item->>'cantidad')::INTEGER;

        INSERT INTO productosporfactura (fknumfactura, fkcodproducto, cantidad, subtotal)
        VALUES (v_numero, v_codigo, v_cantidad, 0);
    END LOOP;

    -- Retornar resultado como JSON
    SELECT json_build_object(
        'factura', (
            SELECT row_to_json(fac) FROM (
                SELECT f.numero, f.fecha, f.total, f.estado, f.fkidcliente, f.fkidvendedor
                FROM factura f WHERE f.numero = v_numero
            ) fac
        ),
        'productos', (
            SELECT json_agg(row_to_json(det)) FROM (
                SELECT pf.fkcodproducto AS codigo_producto, pr.nombre AS nombre_producto,
                       pf.cantidad, pr.valorunitario, pf.subtotal
                FROM productosporfactura pf
                JOIN producto pr ON pr.codigo = pf.fkcodproducto
                WHERE pf.fknumfactura = v_numero
            ) det
        )
    ) INTO p_resultado;
END;
$$;


ALTER PROCEDURE public.sp_insertar_factura_y_productosporfactura(IN p_fkidcliente integer, IN p_fkidvendedor integer, IN p_productos json, IN p_minimo_detalle integer, INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: sp_listar_facturas_y_productosporfactura(json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.sp_listar_facturas_y_productosporfactura(INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT json_agg(factura_completa ORDER BY numero) INTO p_resultado
    FROM (
        SELECT f.numero, json_build_object(
            'numero', f.numero,
            'fecha', f.fecha,
            'total', f.total,
            'estado', f.estado,
            'fkidcliente', f.fkidcliente,
            'nombre_cliente', pc.nombre,
            'fkidvendedor', f.fkidvendedor,
            'nombre_vendedor', pv.nombre,
            'productos', (
                SELECT json_agg(json_build_object(
                    'codigo_producto', pr.codigo,
                    'nombre_producto', pr.nombre,
                    'cantidad', pf.cantidad,
                    'valorunitario', pr.valorunitario,
                    'subtotal', pf.subtotal
                ))
                FROM productosporfactura pf
                JOIN producto pr ON pr.codigo = pf.fkcodproducto
                WHERE pf.fknumfactura = f.numero
            )
        ) AS factura_completa
        FROM factura f
        JOIN cliente c ON c.id = f.fkidcliente
        JOIN persona pc ON pc.codigo = c.fkcodpersona
        JOIN vendedor v ON v.id = f.fkidvendedor
        JOIN persona pv ON pv.codigo = v.fkcodpersona
    ) sub;
END;
$$;


ALTER PROCEDURE public.sp_listar_facturas_y_productosporfactura(INOUT p_resultado json) OWNER TO paradigmas;

--
-- Name: verificar_acceso_ruta(character varying, integer, json); Type: PROCEDURE; Schema: public; Owner: paradigmas
--

CREATE PROCEDURE public.verificar_acceso_ruta(IN p_email character varying, IN p_fkidruta integer, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tiene_acceso BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM usuario u
        INNER JOIN rol_usuario ur ON u.email = ur.fkemail
        INNER JOIN rutarol rr ON ur.fkidrol = rr.fkidrol
        WHERE u.email = p_email AND rr.fkidruta = p_fkidruta
    ) INTO v_tiene_acceso;

    p_resultado := json_build_object(
        'tiene_acceso', v_tiene_acceso,
        'email', p_email,
        'fkidruta', p_fkidruta
    );
END;
$$;


ALTER PROCEDURE public.verificar_acceso_ruta(IN p_email character varying, IN p_fkidruta integer, INOUT p_resultado json) OWNER TO paradigmas;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cliente; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.cliente (
    id integer NOT NULL,
    credito numeric DEFAULT 0 NOT NULL,
    fkcodpersona character varying(10) NOT NULL,
    fkcodempresa character varying(10)
);


ALTER TABLE public.cliente OWNER TO paradigmas;

--
-- Name: cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: paradigmas
--

CREATE SEQUENCE public.cliente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_id_seq OWNER TO paradigmas;

--
-- Name: cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paradigmas
--

ALTER SEQUENCE public.cliente_id_seq OWNED BY public.cliente.id;


--
-- Name: empresa; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.empresa (
    codigo character varying(10) NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE public.empresa OWNER TO paradigmas;

--
-- Name: factura; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.factura (
    numero integer NOT NULL,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total numeric DEFAULT 0 NOT NULL,
    estado character varying(10) DEFAULT 'activa'::character varying NOT NULL,
    fkidcliente integer NOT NULL,
    fkidvendedor integer NOT NULL
);


ALTER TABLE public.factura OWNER TO paradigmas;

--
-- Name: factura_numero_seq; Type: SEQUENCE; Schema: public; Owner: paradigmas
--

CREATE SEQUENCE public.factura_numero_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.factura_numero_seq OWNER TO paradigmas;

--
-- Name: factura_numero_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paradigmas
--

ALTER SEQUENCE public.factura_numero_seq OWNED BY public.factura.numero;


--
-- Name: persona; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.persona (
    codigo character varying(10) NOT NULL,
    nombre character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    telefono character varying(20) NOT NULL
);


ALTER TABLE public.persona OWNER TO paradigmas;

--
-- Name: producto; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.producto (
    codigo character varying(10) NOT NULL,
    nombre character varying(100) NOT NULL,
    stock integer NOT NULL,
    valorunitario numeric NOT NULL
);


ALTER TABLE public.producto OWNER TO paradigmas;

--
-- Name: productosporfactura; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.productosporfactura (
    fknumfactura integer NOT NULL,
    fkcodproducto character varying(10) NOT NULL,
    cantidad integer NOT NULL,
    subtotal numeric DEFAULT 0 NOT NULL
);


ALTER TABLE public.productosporfactura OWNER TO paradigmas;

--
-- Name: rol; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.rol (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL
);


ALTER TABLE public.rol OWNER TO paradigmas;

--
-- Name: rol_id_seq; Type: SEQUENCE; Schema: public; Owner: paradigmas
--

CREATE SEQUENCE public.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rol_id_seq OWNER TO paradigmas;

--
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paradigmas
--

ALTER SEQUENCE public.rol_id_seq OWNED BY public.rol.id;


--
-- Name: rol_usuario; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.rol_usuario (
    fkemail character varying(100) NOT NULL,
    fkidrol integer NOT NULL
);


ALTER TABLE public.rol_usuario OWNER TO paradigmas;

--
-- Name: ruta; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.ruta (
    id integer NOT NULL,
    ruta character varying(100) NOT NULL,
    descripcion character varying(200) NOT NULL
);


ALTER TABLE public.ruta OWNER TO paradigmas;

--
-- Name: ruta_id_seq; Type: SEQUENCE; Schema: public; Owner: paradigmas
--

CREATE SEQUENCE public.ruta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ruta_id_seq OWNER TO paradigmas;

--
-- Name: ruta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paradigmas
--

ALTER SEQUENCE public.ruta_id_seq OWNED BY public.ruta.id;


--
-- Name: rutarol; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.rutarol (
    fkidruta integer NOT NULL,
    fkidrol integer NOT NULL
);


ALTER TABLE public.rutarol OWNER TO paradigmas;

--
-- Name: usuario; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.usuario (
    email character varying(100) NOT NULL,
    contrasena character varying(200) NOT NULL
);


ALTER TABLE public.usuario OWNER TO paradigmas;

--
-- Name: vendedor; Type: TABLE; Schema: public; Owner: paradigmas
--

CREATE TABLE public.vendedor (
    id integer NOT NULL,
    carnet integer NOT NULL,
    direccion character varying(100) NOT NULL,
    fkcodpersona character varying(10) NOT NULL
);


ALTER TABLE public.vendedor OWNER TO paradigmas;

--
-- Name: vendedor_id_seq; Type: SEQUENCE; Schema: public; Owner: paradigmas
--

CREATE SEQUENCE public.vendedor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vendedor_id_seq OWNER TO paradigmas;

--
-- Name: vendedor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paradigmas
--

ALTER SEQUENCE public.vendedor_id_seq OWNED BY public.vendedor.id;


--
-- Name: cliente id; Type: DEFAULT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id SET DEFAULT nextval('public.cliente_id_seq'::regclass);


--
-- Name: factura numero; Type: DEFAULT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.factura ALTER COLUMN numero SET DEFAULT nextval('public.factura_numero_seq'::regclass);


--
-- Name: rol id; Type: DEFAULT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.rol ALTER COLUMN id SET DEFAULT nextval('public.rol_id_seq'::regclass);


--
-- Name: ruta id; Type: DEFAULT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.ruta ALTER COLUMN id SET DEFAULT nextval('public.ruta_id_seq'::regclass);


--
-- Name: vendedor id; Type: DEFAULT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.vendedor ALTER COLUMN id SET DEFAULT nextval('public.vendedor_id_seq'::regclass);


--
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.cliente (id, credito, fkcodpersona, fkcodempresa) FROM stdin;
1	520000	P001	E001
2	250000	P003	E002
3	400000	P005	E001
5	700000	P006	E001
\.


--
-- Data for Name: empresa; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.empresa (codigo, nombre) FROM stdin;
E001	Comercial Los Andes S.A.
E002	Distribuciones El Centro S.A.
E999	Empresa Test
\.


--
-- Data for Name: factura; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.factura (numero, fecha, total, estado, fkidcliente, fkidvendedor) FROM stdin;
1	2025-12-03 12:57:19.27592	5000000	activa	1	1
2	2025-12-03 12:57:19.27592	1250000	activa	2	2
3	2025-12-03 12:57:19.27592	2030000	activa	3	3
4	2025-12-03 13:04:59.028613	950000	activa	1	1
5	2025-12-03 13:05:17.874385	2740000	activa	2	2
6	2025-12-03 13:05:35.02846	4850000	activa	3	3
\.


--
-- Data for Name: persona; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.persona (codigo, nombre, email, telefono) FROM stdin;
P001	Ana Torres	ana.torres@correo.com	3011111111
P002	Carlos Pérez	carlos.perez@correo.com	3022222222
P003	María Gómez	maria.gomez@correo.com	3033333333
P004	Juan Díaz	juan.diaz@correo.com	3044444444
P005	Laura Rojas	laura.rojas@correo.com	3055555555
P006	Pedro Castillo	pedro.castillo@correo.com	3066666666
\.


--
-- Data for Name: producto; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.producto (codigo, nombre, stock, valorunitario) FROM stdin;
PR001	Laptop Lenovo IdeaPad	17	2500000
PR002	Monitor Samsung 24"	27	800000
PR003	Teclado Logitech K380	42	150000
PR004	Mouse HP	55	90000
PR005	Impresora Epson EcoTank1	14	1100000
PR006	Auriculares Sony WH-CH510	23	240000
PR007	Tablet Samsung Tab A9	15	950000
PR008	Disco Duro Seagate 1TB	32	280000
\.


--
-- Data for Name: productosporfactura; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.productosporfactura (fknumfactura, fkcodproducto, cantidad, subtotal) FROM stdin;
1	PR001	2	5000000
2	PR002	1	800000
2	PR003	3	450000
3	PR004	5	450000
3	PR005	1	1100000
3	PR006	2	480000
4	PR007	1	950000
5	PR007	2	1900000
5	PR008	3	840000
6	PR001	1	2500000
6	PR002	2	1600000
6	PR003	5	750000
\.


--
-- Data for Name: rol; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.rol (id, nombre) FROM stdin;
1	Administrador
2	Vendedor
3	Cajero
4	Contador
5	Cliente
\.


--
-- Data for Name: rol_usuario; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.rol_usuario (fkemail, fkidrol) FROM stdin;
admin@correo.com	1
vendedor1@correo.com	2
vendedor1@correo.com	3
jefe@correo.com	1
jefe@correo.com	3
jefe@correo.com	4
cliente1@correo.com	5
test_encript@correo.com	1
nuevo@correo.com	1
nuevo@correo.com	2
nuevo@correo.com	3
carlos.castro@usbmed.edu.co	1
carlos.castro@usbmed.edu.co	2
carlos.castro@usbmed.edu.co	3
carlos.castro@usbmed.edu.co	4
carlos.castro@usbmed.edu.co	5
carloscastro5033@correo.itm.edu.co	1
carloscastro5033@correo.itm.edu.co	2
carloscastro5033@correo.itm.edu.co	3
carloscastro5033@correo.itm.edu.co	4
carloscastro5033@correo.itm.edu.co	5
\.


--
-- Data for Name: ruta; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.ruta (id, ruta, descripcion) FROM stdin;
1	/home	Página principal - Dashboard
2	/usuario	Gestión de usuarios
3	/factura	Gestión de facturas
4	/cliente	Gestión de clientes
5	/vendedor	Gestión de vendedores
6	/persona	Gestión de personas
7	/empresa	Gestión de empresas
8	/producto	Gestión de productos
9	/rol	Gestión de roles
10	/permiso	Gestión de permisos (asignación rol-ruta)
11	/permiso/crear	Crear permiso (POST)
12	/permiso/eliminar	Eliminar permiso (POST)
13	/ruta	Gestión de rutas del sistema
14	/ruta/crear	Crear ruta (POST)
15	/ruta/eliminar	Eliminar ruta (POST)
\.


--
-- Data for Name: rutarol; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.rutarol (fkidruta, fkidrol) FROM stdin;
1	1
2	1
3	1
4	1
5	1
6	1
7	1
8	1
9	1
10	1
11	1
12	1
13	1
14	1
15	1
1	2
3	2
4	2
1	3
3	3
1	4
4	4
8	4
1	5
8	5
\.


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.usuario (email, contrasena) FROM stdin;
admin@correo.com	$2a$12$3UgI.Eof.FhzsYUWESI9n.qFaqkV2JPhvW3L/1GTKowNJnGaD8F.G
vendedor1@correo.com	$2a$12$Dgog4VaHqMzhliPVJy1BcOMd6.izEGNeRDtZ.O7SPmBLc6UVthVTG
jefe@correo.com	jefe123
cliente1@correo.com	cli123
test_encript@correo.com	$2a$11$Ci0J2yBltDgQHfjadgkl0OtbcF5pUf97vTq/4Xr0KEU/86l8ybjBe
nuevo@correo.com	$2a$11$cmtGBxllwc7MCzpnKVSWuumiOgCaG6PaKWcN1z9N0bjjnkobbFDzO
carlos.castro@usbmed.edu.co	$2a$10$YYl6bHCflCnk8suUrms3ie.rnpLvfD9nHJtehZwhcSkINelGwt6iC
carloscastro5033@correo.itm.edu.co	$2a$10$YYl6bHCflCnk8suUrms3ie.rnpLvfD9nHJtehZwhcSkINelGwt6iC
\.


--
-- Data for Name: vendedor; Type: TABLE DATA; Schema: public; Owner: paradigmas
--

COPY public.vendedor (id, carnet, direccion, fkcodpersona) FROM stdin;
1	1001	Calle 10 #5-33	P002
2	1002	Carrera 15 #7-20	P004
3	1003	Avenida 30 #18-09	P006
\.


--
-- Name: cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: paradigmas
--

SELECT pg_catalog.setval('public.cliente_id_seq', 5, true);


--
-- Name: factura_numero_seq; Type: SEQUENCE SET; Schema: public; Owner: paradigmas
--

SELECT pg_catalog.setval('public.factura_numero_seq', 6, true);


--
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: public; Owner: paradigmas
--

SELECT pg_catalog.setval('public.rol_id_seq', 5, true);


--
-- Name: ruta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: paradigmas
--

SELECT pg_catalog.setval('public.ruta_id_seq', 15, true);


--
-- Name: vendedor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: paradigmas
--

SELECT pg_catalog.setval('public.vendedor_id_seq', 3, true);


--
-- Name: cliente pk_cliente; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (id);


--
-- Name: empresa pk_empresa; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT pk_empresa PRIMARY KEY (codigo);


--
-- Name: factura pk_factura; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT pk_factura PRIMARY KEY (numero);


--
-- Name: persona pk_persona; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT pk_persona PRIMARY KEY (codigo);


--
-- Name: producto pk_producto; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT pk_producto PRIMARY KEY (codigo);


--
-- Name: productosporfactura pk_productosporfactura; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.productosporfactura
    ADD CONSTRAINT pk_productosporfactura PRIMARY KEY (fknumfactura, fkcodproducto);


--
-- Name: rol pk_rol; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT pk_rol PRIMARY KEY (id);


--
-- Name: rol_usuario pk_rol_usuario; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.rol_usuario
    ADD CONSTRAINT pk_rol_usuario PRIMARY KEY (fkemail, fkidrol);


--
-- Name: ruta pk_ruta; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.ruta
    ADD CONSTRAINT pk_ruta PRIMARY KEY (id);


--
-- Name: rutarol pk_rutarol; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.rutarol
    ADD CONSTRAINT pk_rutarol PRIMARY KEY (fkidruta, fkidrol);


--
-- Name: usuario pk_usuario; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT pk_usuario PRIMARY KEY (email);


--
-- Name: vendedor pk_vendedor; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.vendedor
    ADD CONSTRAINT pk_vendedor PRIMARY KEY (id);


--
-- Name: ruta uq_ruta; Type: CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.ruta
    ADD CONSTRAINT uq_ruta UNIQUE (ruta);


--
-- Name: productosporfactura trg_actualizar_totales_y_stock; Type: TRIGGER; Schema: public; Owner: paradigmas
--

CREATE TRIGGER trg_actualizar_totales_y_stock BEFORE INSERT OR DELETE OR UPDATE ON public.productosporfactura FOR EACH ROW EXECUTE FUNCTION public.actualizar_totales_y_stock();


--
-- Name: cliente fk_cliente_empresa; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT fk_cliente_empresa FOREIGN KEY (fkcodempresa) REFERENCES public.empresa(codigo);


--
-- Name: cliente fk_cliente_persona; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (fkcodpersona) REFERENCES public.persona(codigo);


--
-- Name: factura fk_factura_cliente; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT fk_factura_cliente FOREIGN KEY (fkidcliente) REFERENCES public.cliente(id);


--
-- Name: factura fk_factura_vendedor; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT fk_factura_vendedor FOREIGN KEY (fkidvendedor) REFERENCES public.vendedor(id);


--
-- Name: productosporfactura fk_prodfact_factura; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.productosporfactura
    ADD CONSTRAINT fk_prodfact_factura FOREIGN KEY (fknumfactura) REFERENCES public.factura(numero) ON DELETE CASCADE;


--
-- Name: productosporfactura fk_prodfact_producto; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.productosporfactura
    ADD CONSTRAINT fk_prodfact_producto FOREIGN KEY (fkcodproducto) REFERENCES public.producto(codigo);


--
-- Name: rol_usuario fk_rolusuario_rol; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.rol_usuario
    ADD CONSTRAINT fk_rolusuario_rol FOREIGN KEY (fkidrol) REFERENCES public.rol(id);


--
-- Name: rol_usuario fk_rolusuario_usuario; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.rol_usuario
    ADD CONSTRAINT fk_rolusuario_usuario FOREIGN KEY (fkemail) REFERENCES public.usuario(email);


--
-- Name: rutarol fk_rutarol_rol; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.rutarol
    ADD CONSTRAINT fk_rutarol_rol FOREIGN KEY (fkidrol) REFERENCES public.rol(id) ON DELETE CASCADE;


--
-- Name: rutarol fk_rutarol_ruta; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.rutarol
    ADD CONSTRAINT fk_rutarol_ruta FOREIGN KEY (fkidruta) REFERENCES public.ruta(id) ON DELETE CASCADE;


--
-- Name: vendedor fk_vendedor_persona; Type: FK CONSTRAINT; Schema: public; Owner: paradigmas
--

ALTER TABLE ONLY public.vendedor
    ADD CONSTRAINT fk_vendedor_persona FOREIGN KEY (fkcodpersona) REFERENCES public.persona(codigo);


--
-- PostgreSQL database dump complete
--

\unrestrict 7eq0Cko6nE1Sw8hzdDjhx6dwgBla3sQmps4jXlG1gheWmCUY3ebbCDu4BHrnS1b

