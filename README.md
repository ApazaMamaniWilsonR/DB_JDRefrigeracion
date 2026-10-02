# Base de Datos - JD Refrigeración S.A.C.

Este repositorio almacena todos los recursos, scripts y modelos relacionados con la implementación de la base de datos para el sistema ERP de **JD Refrigeración S.A.C.** en Oracle 21c XE.

## 📂 Contenido del Directorio

| Archivo / Documento | Descripción |
| :--- | :--- |
| `BD_Implementacion_JDRefrigeracion.md` | Documentación técnica oficial. Contiene el Diccionario de Datos, DDL, DML (Población inicial), Procedimientos Almacenados, Funciones y Triggers. |
| `BD_Implementacion_JDRefrigeracion.pdf` | Versión en PDF de la documentación oficial. |
| `JD_Refrigeracion.sql` | Script SQL principal que contiene la creación de las **15 tablas**, la inserción de datos de prueba y la programación en base de datos. |
| `Admin_Local.sql` | Script SQL con permisos de DBA para la creación del usuario del proyecto (`jdrefrigeracion`). |
| `JDRefrigeracion_modelo.architect` | Proyecto de **SQL Power Architect** que contiene el diagrama relacional completo (Tablas, Columnas, Primary Keys y Foreign Keys) listo para su visualización. |
| `JDRefrigeracion.json` | Archivo de configuración exportado con las conexiones locales de **Oracle SQL Developer** (`Admin_Local` y `JD_Refrigeracion`). |

## ⚙️ Instrucciones de Despliegue (Local)

1. **Creación del Usuario:** En Oracle SQL Developer, conéctese como administrador (ej. `system`) a la base de datos conectable `XEPDB1` y ejecute el archivo `Admin_Local.sql`.
2. **Implementación de Tablas:** Conéctese a la nueva conexión `JD_Refrigeracion` y ejecute el archivo `JD_Refrigeracion.sql` para crear la estructura e insertar la data inicial.
3. **Diagrama Relacional:** Abra el archivo `.architect` usando SQL Power Architect para visualizar y exportar el modelo entidad-relación.
