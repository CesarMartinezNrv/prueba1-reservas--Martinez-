# Reservas de sala

App Flutter para que un estudiante autenticado reserve una sala de estudio por un intervalo
de tiempo. Los datos viven en Supabase.

## Correr las pruebas

```bash
flutter pub get
flutter test
```

Las pruebas de `test/` no necesitan red ni Supabase: usan un repositorio en memoria
(`test/support/reservas_en_memoria.dart`).

## Correr la app

1. Crea un proyecto en Supabase y ejecuta `supabase/migracion.sql` en el SQL Editor.
   Cada usuario solo puede leer sus propias reservas y crear reservas con su ID de sesión.
   La base bloquea solapamientos de la misma sala incluso ante escrituras directas o
   concurrentes. Si ya existe la tabla con datos, primero comprueba que no haya solapamientos:

   ```sql
   select a.id, b.id, a.sala_id
   from public.reservas a
   join public.reservas b
     on a.sala_id = b.sala_id
    and a.id < b.id
    and tstzrange(a.inicio, a.fin, '[)') && tstzrange(b.inicio, b.fin, '[)');
   ```

   Si aparecen filas, la migración no añadirá la restricción y no borrará datos; resuelve esas
   reservas antes de ejecutarla de nuevo.
2. La app asume que el estudiante ya tiene una sesión de Supabase Auth, como indica la
   consigna; el inicio de sesión se realiza fuera de este repositorio. La pantalla toma el ID
   de la sesión y no permite escribirlo manualmente.
3. Obtén la clave **publishable** del proyecto (antes llamada `anon`) y pásala al ejecutar:

   ```bash
   flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```

   También puedes definir `SUPABASE_PUBLISHABLE_KEY` en la configuración de compilación de
   tu entorno. `lib/data/supabase_config.dart` contiene únicamente la URL y lee la clave del
   entorno de compilación; no guardes claves en el repositorio.

La clave `service_role` o cualquier clave `secret` nunca debe usarse en Flutter, en una app
móvil/web ni en este repositorio: omite las políticas RLS. No se necesita ninguna operación
administrativa para reservar salas. La app usa la sesión de Supabase Auth y las políticas de
`supabase/migracion.sql` limitan cada inserción al usuario autenticado.

Si una versión anterior usó o publicó una clave `service_role`, cambiar el código no la
revoca. Revisa **Project Settings → API Keys** en Supabase y desactiva la clave heredada cuando
hayas comprobado que ningún servicio de servidor aún dependa de ella. Si un servidor sí la
necesita, migra ese servicio a una clave `secret` guardada solo en el servidor antes de
desactivar la anterior.

## Estructura

```text
lib/
├── domain/        reglas de negocio (Dart puro)
├── data/          acceso a Supabase
└── presentation/  pantallas
specs/001-reservas-sala/   spec y plan (GitHub Spec Kit)
supabase/                  esquema de la base
test/                      pruebas de dominio
```
