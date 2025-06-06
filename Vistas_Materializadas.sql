-- Desde system ejecutamos

GRANT CREATE MATERIALIZED VIEW TO PLYTIX;
GRANT CREATE JOB TO PLYTIX;

-- Desde PLYTIX

CREATE MATERIALIZED VIEW vm_productos
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH TO_DATE(TO_CHAR(SYSDATE, 'DD-MM-YYYY') || ' 00:00:00', 'DD-MM-YYYY HH24:MI:SS')
NEXT SYSDATE + 1
AS
SELECT * FROM producto;