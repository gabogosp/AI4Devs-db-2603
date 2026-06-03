Eres un ingeniero backend senior especializado en modelado de datos relacionales y migraciones de Prisma.
Traduce el ERD del ATS de reclutamiento proporcionado a un esquema de PostgreSQL listo para producción, alinéalo con la capa de base de datos existente del proyecto y entrega la expansión exclusivamente a través de migraciones de Prisma, aplicando la tercera forma normal (3FN) e indexación más allá de lo que especifica el ERD.
ERD de Origen (Mermaid erDiagram — conjunto autorizado de entidades/relaciones)
Fragmento de código
erDiagram
     COMPANY {
         int id PK
         string name
     }
     EMPLOYEE {
         int id PK
         int company_id FK
         string name
         string email
         string role
         boolean is_active
     }
     POSITION {
         int id PK
         int company_id FK
         int interview_flow_id FK
         string title
         text description
         string status
         boolean is_visible
         string location
         text job_description
         text requirements
         text responsibilities
         numeric salary_min
         numeric salary_max
         string employment_type
         text benefits
         text company_description
         date application_deadline
         string contact_info
     }
     INTERVIEW_FLOW {
         int id PK
         string description
     }
     INTERVIEW_STEP {
         int id PK
         int interview_flow_id FK
         int interview_type_id FK
         string name
         int order_index
     }
     INTERVIEW_TYPE {
         int id PK
         string name
         text description
     }
     CANDIDATE {
         int id PK
         string firstName
         string lastName
         string email
         string phone
         string address
     }
     APPLICATION {
         int id PK
         int position_id FK
         int candidate_id FK
         date application_date
         string status
         text notes
     }
     INTERVIEW {
         int id PK
         int application_id FK
         int interview_step_id FK
         int employee_id FK
         date interview_date
         string result
         int score
         text notes
     }

     COMPANY ||--o{ EMPLOYEE : employs
     COMPANY ||--o{ POSITION : offers
     POSITION ||--|| INTERVIEW_FLOW : assigns
     INTERVIEW_FLOW ||--o{ INTERVIEW_STEP : contains
     INTERVIEW_STEP ||--|| INTERVIEW_TYPE : uses
     POSITION ||--o{ APPLICATION : receives
     CANDIDATE ||--o{ APPLICATION : submits
     APPLICATION ||--o{ INTERVIEW : has
     INTERVIEW ||--|| INTERVIEW_STEP : consists_of
     EMPLOYEE ||--o{ INTERVIEW : conducts
Necesito los cambios del modelo y los archivos de migración .sql en la carpeta backend/prisma

Voy a empezar explorando el estado actual de la capa de base de datos del proyecto (backend/prisma) para alinear la expansión
  con lo que ya existe, antes de diseñar el esquema y las migraciones.

¡Listo! Implementación completa y verificada de punta a punta. ✅

  Resultado

  Esquema (backend/prisma/schema.prisma) — el ERD completo traducido a Prisma:
  - 8 modelos nuevos: Company, Employee, Position, InterviewFlow, InterviewStep, InterviewType, Application, Interview.
  - 5 enums PostgreSQL en lugar de los string del ERD: EmployeeRole, PositionStatus, EmploymentType, ApplicationStatus,
  InterviewResult.
  - Candidate conserva sus relaciones (educations/workExperiences/resumes) y gana applications[].

  Migración (backend/prisma/migrations/20260603010208_init_ats_schema/migration.sql) — generada y aplicada con prisma migrate
  dev. Baseline inicial limpio: 13 tablas + _prisma_migrations.

  Mejoras sobre el ERD

  ┌──────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────┐
  │      Categoría       │                                           Qué se hizo                                           │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 3FN                  │ company_description movido de Position → Company (eliminada dependencia transitiva)             │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Tipos                │ salary_min/max → DECIMAL(12,2); fechas → DATE; categóricos → enum                               │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Auditoría            │ createdAt/updatedAt en todas las tablas nuevas                                                  │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Integridad           │ FKs con ON DELETE explícito (CASCADE para hijos dependientes, RESTRICT para historia:           │
  │                      │ Interview→Employee/Step, Position→Flow)                                                         │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Únicos               │ Employee.email, (interviewFlowId, orderIndex), (positionId, candidateId)                        │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Índices (más allá    │ Todas las FKs (Postgres no las indexa solo) + filtros frecuentes: Position.status,              │
  │ del ERD)             │ Position.isVisible, Application.status, Interview.result                                        │
  └──────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────┘

  Verificación

  - prisma migrate status → "Database schema is up to date!"
  - psql \dt → 13 tablas creadas; \d Position confirma enums, numeric(12,2), índices y FKs.
  - npx tsc --noEmit → exit 0 (código existente sigue compilando).
  - npm test → 37/37 tests en 4 suites pasando.

  Notas:
  - La DB del repo quedó levantada en ai4devs-db-2603-db-1 (localhost:5432, LTIdb).
  - No toqué código TypeScript: al conservar Education/WorkExperience/Resume, nada se rompió.

✻ Sautéed for 5m 54s

❯ 3F era 3 forma normal a nivel e normalizacion asegura eso.. ademas Revisa la migración generada y dime: ¿hay DROP COLUMN,
  DROP TABLE, CREATE UNIQUE sobre datos existentes, o ALTER TYPE que pueda truncar? Para cada caso, dime el riesgo y cómo
  hacerlo sin pérdida de datos. y revisa los indices que esten optimos

Buenas preguntas. Reviso las dos cosas: la 3FN real tabla por tabla y el escaneo de operaciones destructivas + índices.

  1. ¿Está garantizada la 3FN?

  Sí. Las tres condiciones se cumplen en cada tabla:

  - 1FN — todos los atributos son atómicos (no hay listas/repeticiones en columnas).
  - 2FN — toda tabla tiene PK de una sola columna (id surrogate), así que no existen dependencias parciales por definición.
  - 3FN — ningún atributo no-clave depende de otro atributo no-clave (sin dependencias transitivas).

  El único punto que rompía la 3FN en el ERD original era company_description en POSITION: dependía de company_id, no de la PK
  de la posición (position → company → company_description). Lo moví a Company.description, eliminando esa transitividad. El
  resto ya estaba limpio:

  ┌──────────────────────────────────────────────────────────────────────────┬─────────────────────────────────┬───────────┐
  │                                  Tabla                                   │  Atributos no-clave dependen    │ Veredicto │
  │                                                                          │           solo de id            │           │
  ├──────────────────────────────────────────────────────────────────────────┼─────────────────────────────────┼───────────┤
  │ Company, Employee, Position, InterviewFlow, InterviewStep,               │ sí (tras mover                  │ 3FN ✓     │
  │ InterviewType, Candidate, Application, Interview                         │ company_description)            │           │
  └──────────────────────────────────────────────────────────────────────────┴─────────────────────────────────┴───────────┘

  ⚠️ Un matiz que la normalización NO cubre (no es violación de 3FN, sino integridad inter-tabla): un Interview.interviewStepId
  debería pertenecer al InterviewFlow de la Position de su Application. Las FKs no lo garantizan. Si lo quieres blindar, hace
  falta un trigger o validación en la capa de aplicación — dímelo y lo añado.

  2. Escaneo de operaciones destructivas

  Revisé migration.sql completo. No hay ninguna de las cuatro operaciones de riesgo:

  ┌──────────────────────────────────┬────────────────────────────────────────────────────────────────────────────┬────────┐
  │        Operación buscada         │                                 ¿Presente?                                 │  Por   │
  │                                  │                                                                            │  qué   │
  ├──────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┼────────┤
  │ DROP COLUMN                      │ ❌ No                                                                      │ —      │
  ├──────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┼────────┤
  │ DROP TABLE                       │ ❌ No                                                                      │ —      │
  ├──────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┼────────┤
  │ CREATE UNIQUE sobre datos        │ ⚠️ Hay 4 CREATE UNIQUE INDEX, pero sobre tablas recién creadas y vacías →  │        │
  │ existentes                       │ riesgo cero                                                                │        │
  ├──────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┼────────┤
  │ ALTER TYPE que trunque           │ ❌ No                                                                      │ —      │
  └──────────────────────────────────┴────────────────────────────────────────────────────────────────────────────┴────────┘

  Razón de fondo: es una migración inicial (greenfield) contra una base vacía. Solo contiene CREATE TYPE (enums), CREATE TABLE,
  CREATE INDEX y ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY. Todo aditivo, sobre cero filas. No hay posibilidad de pérdida
  de datos en esta migración.

  Como pediste el riesgo y el procedimiento seguro para cada caso, aquí está la guía para cuando estas operaciones sí aparezcan
  en migraciones futuras (cuando ya haya datos):

  DROP COLUMN — Riesgo: pérdida irreversible del dato. Patrón seguro (expand/contract en 2 deploys):
  1. Dejar de leer/escribir la columna en el código (deploy A).
  2. Verificar que nada la usa (logs/métricas) por un periodo.
  3. DROP COLUMN en una migración posterior (deploy B). Backup/snapshot antes.

  DROP TABLE — Riesgo: pérdida total. Igual que arriba: primero quitar todas las FKs/referencias y dejar de usarla; renombrarla
  (ALTER TABLE x RENAME TO x_deprecated) como "papelera" temporal antes del DROP definitivo; snapshot previo.

  CREATE UNIQUE INDEX sobre datos existentes — Riesgo: la migración falla si ya hay duplicados, y en producción CREATE UNIQUE
  INDEX (no concurrente) bloquea escrituras. Procedimiento:
  1. Detectar duplicados antes: SELECT positionId, candidateId, COUNT(*) FROM "Application" GROUP BY 1,2 HAVING COUNT(*)>1;
  2. Limpiarlos (merge/borrado) en una migración de datos previa.
  3. Crear el índice sin bloquear: CREATE UNIQUE INDEX CONCURRENTLY ... (en Prisma, esto requiere editar el SQL a mano y marcar
  la migración; CONCURRENTLY no puede ir en transacción).

  ALTER TYPE que trunca (p. ej. VARCHAR(255)→VARCHAR(50), TEXT→VARCHAR, o quitar un valor de enum) — Riesgo: trunca/rechaza
  datos que no caben. Procedimiento:
  1. Verificar que ningún dato excede: SELECT MAX(LENGTH(col)) FROM t; o SELECT DISTINCT enumcol FROM t;
  2. Migrar/normalizar los valores fuera de rango primero.
  3. Aplicar el cambio. Para enums, PostgreSQL no permite quitar valores directamente: hay que crear un tipo nuevo, ALTER TABLE
  ... TYPE con un USING que mapee, y dropear el viejo.

  3. Revisión de índices — 2 redundancias detectadas

  Los índices de FK y los únicos están bien, pero hay dos índices redundantes y algunas mejoras de cardinalidad:

  🔴 Redundantes (un índice compuesto ya cubre el prefijo):
  - Application_positionId_idx → redundante: el único Application(positionId, candidateId) ya indexa positionId como columna
  líder.
  - InterviewStep_interviewFlowId_idx → redundante: el único InterviewStep(interviewFlowId, orderIndex) ya cubre
  interviewFlowId.

  Postgres usa el prefijo del índice compuesto para esas búsquedas, así que estos dos solo añaden coste de escritura y
  almacenamiento. Recomiendo eliminarlos.

  🟡 Baja cardinalidad (valor cuestionable como índice de una sola columna):
  - Position_isVisible_idx (boolean, 2 valores), Position_status_idx, Application_status_idx, Interview_result_idx (enums de ~4
  valores).

  Un btree de una columna sobre 2–4 valores rara vez ayuda al planner. Suelen rendir mejor como compuestos alineados al patrón
  de acceso real o como índices parciales. Ejemplos:
  - Job board público "vacantes visibles y abiertas" → índice parcial: Position(companyId) WHERE isVisible AND status = 'OPEN',
  o compuesto Position(status, isVisible).
  - "Postulaciones de una vacante en cierto estado" → Application(positionId, status) en lugar de Application(status) suelto.

  ¿Quieres que ajuste el schema.prisma (quitar los 2 redundantes + cambiar los de baja cardinalidad por compuestos/parciales) y
  regenere la migración? Como aún es la migración inicial y nadie la ha aplicado en otro entorno, puedo regenerarla limpia. Te
  propongo:

  User answered Claude's questions:
  ⎿  · ¿Cómo ajusto los índices? → Quitar redundantes + compuestos
     · ¿Añado el blindaje de integridad inter-tabla (step pertenece al flow de la position)? → Sí, añadir trigger
Perfecto. Hago las dos cosas: (1) reescribo los índices (quitar redundantes + compuestos), regenero la migración inicial
  limpia; (2) añado una segunda migración con el trigger de integridad.

  Nota técnica importante sobre "parciales": Prisma no puede modelar índices parciales (WHERE ...) en el schema, y si los añado
  por SQL crudo, migrate dev los detecta como drift y querría borrarlos. Así que uso compuestos nativos de Prisma que cubren
  los mismos patrones de acceso sin ese conflicto. El trigger sí va por SQL crudo (en su propia migración).
Estado final

  - 2 migraciones en backend/prisma/migrations/: …_init_ats_schema y …_interview_step_flow_guard (trigger).
  - prisma migrate status → up to date · tsc --noEmit → exit 0 · npm test → 37/37.
  - Trigger probado: rechaza el step de flujo equivocado, acepta el correcto.