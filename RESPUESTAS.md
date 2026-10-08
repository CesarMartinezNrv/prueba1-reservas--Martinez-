## Escenarios que elegí y por qué

Probé intervalos idénticos, solapamientos parciales en ambos sentidos y ambas formas de
contención para cubrir todos los cruces entre la reserva existente y la solicitada
(`specs/001-reservas-sala/spec.md:24`, `specs/001-reservas-sala/spec.md:27`,
`specs/001-reservas-sala/spec.md:30`, `specs/001-reservas-sala/spec.md:33`,
`specs/001-reservas-sala/spec.md:36`, `test/crear_reserva_test.dart:81`,
`test/crear_reserva_test.dart:89`, `test/crear_reserva_test.dart:103`,
`test/crear_reserva_test.dart:112`, `test/crear_reserva_test.dart:124`). También comprobé que
se permiten horarios contiguos y el mismo horario en salas distintas
(`specs/001-reservas-sala/spec.md:39`, `specs/001-reservas-sala/spec.md:42`,
`specs/001-reservas-sala/spec.md:45`, `test/crear_reserva_test.dart:132`,
`test/crear_reserva_test.dart:141`, `test/crear_reserva_test.dart:150`).

## Riesgo más grave del repositorio

La versión inicial indicaba usar `service_role` en Flutter (`README.md@39cb2a7:20`) y guardaba
su valor en el código (`lib/data/supabase_config.dart@39cb2a7:4`). El valor sigue en los cuatro
commits que preceden esta corrección; conservé el historial tal como se pidió. Ahora Flutter
requiere una clave publishable en tiempo de compilación (`lib/data/supabase_config.dart:5`,
`lib/main.dart:16`) y la pantalla obtiene el ID del usuario desde Auth
(`lib/presentation/reserva_page.dart:48`, `lib/presentation/reserva_page.dart:62`). La clave
antigua debe desactivarse manualmente en Supabase; el cambio de código no la revoca.

## ¿La regla protege la app real?

La pantalla llama `CrearReserva` y el caso de uso revisa los horarios antes de guardar
(`lib/presentation/reserva_page.dart:59`, `lib/domain/crear_reserva.dart:16`,
`lib/domain/crear_reserva.dart:28`). La base también impide solapamientos directos o
concurrentes con una restricción de exclusión (`supabase/migracion.sql:31`,
`supabase/migracion.sql:32`). RLS limita la lectura a las reservas propias y exige que
`usuario_id` coincida con `auth.uid()` al insertar (`supabase/migracion.sql:52`,
`supabase/migracion.sql:59`). Esto protege la aplicación cuando se ejecuta la migración en
Supabase; las pruebas Flutter verifican el dominio, no las políticas del proyecto remoto
(`test/crear_reserva_test.dart:9`).
