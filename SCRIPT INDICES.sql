
-- Ya tenemos creada la clave primaria de la tabla USUARIO
-- Sentencia: ALTER TABLE Usuario ADD CONSTRAINT Usuario_PK...

-- Crear indices sobre los atributos mas comunes de la tabla Usuario

-- Los indices deben residir en TS_INDICES

-- Al menos uno de los índices debe ser sobre una función.


-- CREACION DE INDICES ADICIONALES:

CREATE INDEX Usuario_NombreUsuario_IDX ON Usuario(NombreUsuario) TABLESPACE TS_INDICES;

CREATE INDEX Usuario_NombreCompletoUpper_IDX ON Usuario(UPPER(NombreCompleto)) TABLESPACE TS_INDICES;

CREATE INDEX Usuario_CorreoTelefono_IDX ON Usuario(CorreoElectronico, Telefono) TABLESPACE TS_INDICES;


-- CONSULTA A USER_INDEXES:

SELECT index_name, index_type, tablespace_name FROM USER_INDEXES WHERE table_name = 'USUARIO';

-- CONSULTA DEL TABLESPACE DE LA TABLA E ÍNDICES:

SELECT table_name, tablespace_name FROM USER_TABLES WHERE table_name = 'USUARIO';

-- CREACIÓN DE ÍNDICE BITMAP:
-- El BITMAP debe ser sobre el atributo que indica la cuenta en la tabla USUARIO

CREATE BITMAP INDEX Usuario_CuentaId_BIDX ON Usuario(Cuenta_Id) TABLESPACE TS_INDICES;
--                                                       /
--                                                Indica la cuenta

-- VERIFICACIÓN DEL ÍNDICE BITMAP:

SELECT index_name, index_type FROM USER_INDEXES WHERE table_name = 'USUARIO' AND index_name = 'USUARIO_CUENTAID_BIDX';


-- INDICES ADICIONALES SOBRE FUNCIONES:

-- Para búsquedas case-insensitive de nombres de usuario, nombre en minúscula
CREATE INDEX Usuario_NombreUsuarioLower_IDX ON Usuario(LOWER(NombreUsuario)) TABLESPACE TS_INDICES;

CREATE INDEX Usuario_DominioCorreoElectronico_IDX ON Usuario(SUBSTR(CorreoElectronico, INSTR(CorreoElectronico, '@') + 1)) TABLESPACE TS_INDICES;













