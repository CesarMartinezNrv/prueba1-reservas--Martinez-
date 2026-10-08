## Escenarios que elegí y por qué

Elegí probar horarios iguales, horarios que se cruzan en una parte y reservas que quedan dentro de otra. Los elegí porque en todos esos casos se estaría ocupando la misma sala al mismo tiempo.

También comprobé que una reserva pueda empezar justo cuando termina otra y que se pueda reservar el mismo horario en salas distintas. Así se evitan los cruces sin rechazar reservas que sí deberían permitirse.

Además, probé reservas del mismo estudiante y varios horarios registrados en distinto orden, para comprobar que se revisen todas las reservas de la sala.

## Riesgo más grave del repositorio

El riesgo más grave que encontré y la IA me ayudo a identificarlo, fue que la app tenía una clave con permisos de administrador. Si alguien la conseguía, podía acceder a datos o hacer cambios que no le correspondían.

Ahora la app usa una clave pública, pero la anterior sigue en el historial del proyecto. Por eso, quitarla del código no es suficiente: también hay que confirmar que esté desactivada en Supabase.

## ¿La regla protege la app real?

La regla ayuda, pero se queuda corta. La app revisa los horarios antes de guardar, aunque dos personas podrían intentar reservar al mismo tiempo y cada una solo puede consultar sus propias reservas.

Por eso, la base de datos también debe impedir los cruces. Esa protección está preparada en el proyecto, pero debe estar aplicada en Supabase para proteger la app real.

Las pruebas pasaron y comprobaron la lógica de las reservas. Como no usaron Supabase, no puedo asegurarme con esas pruebas que la base de datos real ya tenga esa protección activa.
