-- CREAMOS EL PAQUETE PKG_ADMIN_PRODUCTOS_AVANZADO QUE VA A CONTENER LOS PROCEDIMIENTOS Y FUNCIONES

CREATE OR REPLACE PACKAGE PKG_ADMIN_PRODUCTOS_AVANZADO AS

    -- FUNCIONES

    FUNCTION F_VALIDAR_PLAN_SUFICIENTE(p_cuenta_id IN CUENTA.ID%TYPE) RETURN VARCHAR2;
    
    FUNCTION  F_LISTA_CATEGORIAS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, 
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) RETURN VARCHAR2;

    -- PROCEDIMIENTOS

    PROCEDURE P_MIGRAR_PRODUCTOS_A_CATEGORIA(p_cuenta_id IN CUENTA.ID%TYPE, 
    p_categoria_origen_id IN CATEGORIA.ID%TYPE, p_categoria_destino_id IN 
    CATEGORIA.ID%TYPE) ;

    PROCEDURE P_REPLICAR_ATRIBUTOS(p_cuenta_id IN CUENTA.ID%TYPE, p_producto_gtin_origen IN 
    PRODUCTO.GTIN%TYPE, p_producto_gtin_destino IN PRODUCTO.GTIN%TYPE);
    
END PKG_ADMIN_PRODUCTOS_AVANZADO;
/

-- CREAMOS EL CUERPO DEL PAQUETE PKG_ADMIN_PRODUCTOS_AVANZADO QUE VA A CONTENER LOS PROCEDIMIENTOS Y FUNCIONES
CREATE OR REPLACE PACKAGE BODY PKG_ADMIN_PRODUCTOS_AVANZADO AS

    -- FUNCIONES

    FUNCTION F_VALIDAR_PLAN_SUFICIENTE(p_cuenta_id IN CUENTA.ID%TYPE) RETURN VARCHAR2 IS
        V_RES VARCHAR2;
        v_plan_actual PLAN%ROWTYPE;
        v_cant_productos NUMBER;
        v_cant_activos NUMBER;
        v_cant_categorias_producto NUMBER;
        v_cant_categorias_activos NUMBER;
        v_cant_relaciones NUMBER;

    BEGIN

        -- COMPROBAMOS SI LA CUENTA EXISTE
        
        SELECT COUNT(*) INTO v_cuenta FROM CUENTA WHERE ID = p_cuenta_id;
        IF v_cuenta = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        v_plan_actual := F_OBTENER_PLAN_CUENTA(p_cuenta_id);

        v_cant_productos := SELECT COUNT(*) FROM PRODUCTO WHERE CUENTA_ID = p_cuenta_id;
        v_cant_activos := SELECT COUNT(*) FROM ACTIVO WHERE CUENTA_ID = p_cuenta_id;
        v_cant_categorias_producto := SELECT COUNT(*) FROM CATEGORIA WHERE CUENTA_ID = p_cuenta_id;
        v_cant_categorias_activos := SELECT COUNT(*) FROM Categoria_Activos WHERE CUENTA_ID = p_cuenta_id;
        v_cant_relaciones := SELECT COUNT(*) FROM RELACIONES WHERE CUENTA_ID = PRODUCTO_CUENTA_ID;

        -- COMPROBAMOS LOS CONTEOS CON LOS LIMITES PERMITIDOS POR EL PLAN
        V_RES := 'SUFICIENTE';

        IF v_cant_productos > v_plan_actual.PRODUCTOS THEN
            V_RES := 'INSUFICIENTE: PRODUCTOS';
        ELSIF v_cant_activos > v_plan_actual.ACTIVOS THEN
            V_RES := 'INSUFICIENTE: ACTIVOS';
        ELSIF v_cant_categorias_producto > v_plan_actual.CATEGORIASPRODUCTO THEN
            V_RES := 'INSUFICIENTE: CATEGORIAS PRODUCTO';
        ELSIF v_cant_categorias_activos > v_plan_actual.CATEGORIASACTIVOS THEN
            V_RES := 'INSUFICIENTE: CATEGORIAS ACTIVOS';
        ELSIF v_cant_relaciones > v_plan_actual.RELACIONES THEN
            V_RES := 'INSUFICIENTE: RELACIONES';
        END IF;

        RETURN V_RES;
    
    END F_VALIDAR_PLAN_SUFICIENTE;

    FUNCTION F_LISTA_CATEGORIAS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) RETURN VARCHAR2 IS
        CURSOR C_CATEGORIAS IS SELECT CATEGORIA_ID FROM REL_PROD_CATEG WHERE CUENTA_ID = PRODUCTO_CUENTA_ID;
        V_PRODUCTO NUMBER;
        V_CUENTA NUMBER;
        V_RES VARCHAR2;
        V_CATEGORIA_NOMBRE VARCHAR2(100);

    BEGIN
        -- COMPROBAMOS SI LA CUENTA EXISTE
        SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE ID = p_cuenta_id;

        IF V_CUENTA = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe la cuenta
        END IF;

        -- COMPROBAMOS SI EL PRODUCTO EXISTE
        SELECT COUNT(*) INTO V_PRODUCTO FROM PRODUCTO WHERE GTIN = p_producto_gtin AND CUENTA_ID = p_cuenta_id;

        IF V_PRODUCTO = 0 THEN
            RAISE NO_DATA_FOUND; -- Lanza la excepción personalizada si no existe el producto
        END IF;

        V_RES := '';

        -- RECORREMOS LAS CATEGORIAS DEL PRODUCTO
        FOR cat IN C_CATEGORIAS LOOP

            V_CATEGORIA_NOMBRE := SELECT NOMBRE FROM CATEGORIA WHERE ID = c.CATEGORIA_ID;
            V_RES := V_RES || V_CATEGORIA_NOMBRE || '; ';

        END LOOP;

        RETURN V_RES;

    END F_LISTA_CATEGORIAS_PRODUCTO;

END PKG_ADMIN_PRODUCTOS_AVANZADO;
/
    


-----------------------------------------------------------------------------------------------------------------------------

-- JOBS

-- J_LIMPIA_TRAZA: Limpia las entradas de la tabla TRAZA que tengan más de 1 año.
-- Para probarlo se pueden hacer con las que tengan más de un minuto y luego modificarlo.

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'J_LIMPIA_TRAZA',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN
                          -- Eliminar registros con más de 1 año de antigüedad
                          DELETE FROM TRAZA 
                          WHERE FECHA < ADD_MONTHS(SYSDATE, -12);
                          
                          -- Para pruebas: eliminar registros con más de 1 minuto
                          -- DELETE FROM TRAZA 
                          -- WHERE FECHA < SYSDATE - (1/1440); -- 1 minuto
                          
                          COMMIT;
                          DBMS_OUTPUT.PUT_LINE(''Registros eliminados: '' || SQL%ROWCOUNT);
                       EXCEPTION
                          WHEN OTHERS THEN
                             DBMS_OUTPUT.PUT_LINE(''Error en J_LIMPIA_TRAZA: '' || SQLERRM);
                             INSERT INTO TRAZA 
                             VALUES (SYSDATE, USER, ''J_LIMPIA_TRAZA'', 
                                     SQLCODE || '' - '' || SUBSTR(SQLERRM, 1, 200));
                             COMMIT;
                       END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=2', -- Ejecución diaria a las 2 AM
    enabled         => TRUE,
    comments        => 'Job para limpiar registros antiguos de la tabla TRAZA');
END;
/

----------------------------------------------------------------------------------------------------------------

-- J_ACTUALIZA_PRODUCTOS. Actualiza desde la tabla de productos externos los productos
-- de la tabla Productos para todas las cuentas de la base de datos llamando a P_ACTUALIZAR_PRODUCTOS.

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'J_ACTUALIZA_PRODUCTOS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'DECLARE
                          CURSOR c_productos_ext IS 
                            SELECT 
                              TO_NUMBER(REPLACE(sku, ''P'', '''')) AS gtin,
                              sku,
                              nombre,
                              textocorto,
                              creado,
                              TO_NUMBER(cuenta_id) AS cuenta_id
                            FROM productos_ext
                            WHERE REGEXP_LIKE(cuenta_id, ''^[0-9]+$'');
                            
                          v_contador_actualizados NUMBER := 0;
                          v_contador_insertados NUMBER := 0;
                          v_total NUMBER := 0;
                       BEGIN
                          -- Obtener total de productos externos para registro
                          SELECT COUNT(*) INTO v_total FROM productos_ext
                          WHERE REGEXP_LIKE(cuenta_id, ''^[0-9]+$'');
                          
                          DBMS_OUTPUT.PUT_LINE(''Iniciando actualización de '' || v_total || '' productos'');
                          
                          -- Procesar cada producto externo
                          FOR r_prod IN c_productos_ext LOOP
                             BEGIN
                                -- Verificar si el producto ya existe
                                DECLARE
                                   v_existe NUMBER := 0;
                                BEGIN
                                   SELECT COUNT(*) INTO v_existe
                                   FROM Producto
                                   WHERE GTIN = r_prod.gtin
                                   AND Cuenta_Id = r_prod.cuenta_id;
                                   
                                   IF v_existe > 0 THEN
                                      -- Actualizar producto existente
                                      UPDATE Producto SET
                                        SKU = r_prod.sku,
                                        Nombre = r_prod.nombre,
                                        TextoCorto = r_prod.textocorto,
                                        Modificado = SYSDATE
                                      WHERE GTIN = r_prod.gtin
                                      AND Cuenta_Id = r_prod.cuenta_id;
                                      
                                      v_contador_actualizados := v_contador_actualizados + 1;
                                   ELSE
                                      -- Insertar nuevo producto
                                      INSERT INTO Producto (
                                        GTIN,
                                        SKU,
                                        Nombre,
                                        TextoCorto,
                                        Creado,
                                        Cuenta_Id
                                      ) VALUES (
                                        r_prod.gtin,
                                        r_prod.sku,
                                        r_prod.nombre,
                                        r_prod.textocorto,
                                        NVL(r_prod.creado, SYSDATE),
                                        r_prod.cuenta_id
                                      );
                                      
                                      v_contador_insertados := v_contador_insertados + 1;
                                   END IF;
                                END;
                                
                                -- Commit cada 100 registros para evitar bloques largos
                                IF MOD(v_contador_actualizados + v_contador_insertados, 100) = 0 THEN
                                   COMMIT;
                                   DBMS_OUTPUT.PUT_LINE(''Procesados '' || (v_contador_actualizados + v_contador_insertados) || '' de '' || v_total || '' productos'');
                                END IF;
                             EXCEPTION
                                WHEN OTHERS THEN
                                   DBMS_OUTPUT.PUT_LINE(''Error procesando producto SKU: '' || r_prod.sku || '', Cuenta: '' || r_prod.cuenta_id || '': '' || SQLERRM);
                                   INSERT INTO TRAZA 
                                   VALUES (SYSDATE, USER, ''J_ACTUALIZA_PRODUCTOS'', 
                                           ''Producto '' || r_prod.sku || '' (Cuenta '' || r_prod.cuenta_id || ''): '' || SQLCODE || '' - '' || SUBSTR(SQLERRM, 1, 200));
                             END;
                          END LOOP;
                          
                          COMMIT;
                          DBMS_OUTPUT.PUT_LINE(''Actualización completada. Productos actualizados: '' || v_contador_actualizados || '', insertados: '' || v_contador_insertados);
                          
                          -- Registrar éxito en TRAZA
                          INSERT INTO TRAZA 
                          VALUES (SYSDATE, USER, ''J_ACTUALIZA_PRODUCTOS'', 
                                  ''Actualización completada. Actualizados: '' || v_contador_actualizados || '', Insertados: '' || v_contador_insertados || ''/'' || v_total);
                          COMMIT;
                       EXCEPTION
                          WHEN OTHERS THEN
                             DBMS_OUTPUT.PUT_LINE(''Error general en J_ACTUALIZA_PRODUCTOS: '' || SQLERRM);
                             INSERT INTO TRAZA 
                             VALUES (SYSDATE, USER, ''J_ACTUALIZA_PRODUCTOS'', 
                                     SQLCODE || '' - '' || SUBSTR(SQLERRM, 1, 200));
                             COMMIT;
                             RAISE;
                       END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=HOURLY; INTERVAL=4', -- Ejecución cada 4 horas
    enabled         => TRUE,
    comments        => 'Job para actualizar productos desde la tabla externa productos_ext');
END;
/


------------------------------------------------------------------------------------------------------------------------------

-- PROCEDIMIENTOS DE PRUEBA 
-- Comprobamos que funcionan correctamente los JOBS

CREATE OR REPLACE PROCEDURE TEST_JOBS_ADMIN_PRODUCTOS AS
BEGIN
  -- Preparar datos de prueba en productos_ext (simulado)
  DBMS_OUTPUT.PUT_LINE('=== PREPARANDO DATOS DE PRUEBA ===');
  
  -- Ejecutar job de limpieza
  DBMS_OUTPUT.PUT_LINE('=== EJECUTANDO J_LIMPIA_TRAZA ===');
  DBMS_SCHEDULER.RUN_JOB('J_LIMPIA_TRAZA');
  
  -- Ejecutar job de actualización de productos
  DBMS_OUTPUT.PUT_LINE('=== EJECUTANDO J_ACTUALIZA_PRODUCTOS ===');
  DBMS_SCHEDULER.RUN_JOB('J_ACTUALIZA_PRODUCTOS');
  
  -- Verificar resultados
  DBMS_OUTPUT.PUT_LINE('=== RESULTADOS ===');
  DBMS_OUTPUT.PUT_LINE('Registros en Producto: ' || 
    (SELECT COUNT(*) FROM Producto));
  DBMS_OUTPUT.PUT_LINE('Registros en productos_ext: ' || 
    (SELECT COUNT(*) FROM productos_ext WHERE REGEXP_LIKE(cuenta_id, '^[0-9]+$')));
  
  -- Mostrar últimos registros de TRAZA
  DBMS_OUTPUT.PUT_LINE('=== ÚLTIMOS EVENTOS EN TRAZA ===');
  FOR t IN (SELECT * FROM (
              SELECT fecha, modulo, mensaje 
              FROM TRAZA 
              ORDER BY fecha DESC) 
            WHERE ROWNUM <= 5) LOOP
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(t.fecha, 'DD/MM/YY HH24:MI') || ' - ' || 
                         t.modulo || ': ' || t.mensaje);
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en TEST_JOBS_ADMIN_PRODUCTOS: ' || SQLERRM);
    INSERT INTO TRAZA VALUES(SYSDATE, USER, 'TEST_JOBS', SQLERRM);
    COMMIT;
    RAISE;
END TEST_JOBS_ADMIN_PRODUCTOS;
/



