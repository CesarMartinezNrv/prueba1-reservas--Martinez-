# Feature Specification: Reservas de sala

**Feature Branch**: `prueba/solapamiento`
**Created**: 2026-10-01
**Status**: Especificada

## Alcance y significado de los intervalos

El estudiante ya está autenticado. Esta regla se aplica al crear reservas; quedan fuera de
alcance el inicio de sesión, las cancelaciones y la modificación de reservas.

- Cada intervalo incluye su inicio y excluye su fin: **[inicio, fin)**. Debe tener duración
  estrictamente positiva.
- Se comparan fechas y horas completas como instantes, sin redondear a minutos. Dos horas
  con distinto huso horario que representan el mismo instante son equivalentes.
- Dos intervalos válidos se solapan si el inicio de la solicitud es anterior al fin de la
  reserva existente **y** el fin de la solicitud es posterior al inicio de la existente.
  Esto incluye la igualdad completa y la coincidencia de solo uno de los extremos.
- La comparación abarca todas las reservas de la misma sala, sin importar su orden ni si
  pertenecen al mismo estudiante o a otro. Las salas distintas no se bloquean entre sí.
- Primero se valida la duración. Si no es positiva, ese rechazo tiene prioridad sobre el
  solapamiento, incluso cuando existe una reserva que ocupa ese horario.
- Todo rechazo deja las reservas existentes intactas y no registra una nueva. Una solicitud
  aceptada registra exactamente una reserva con la sala, estudiante, inicio y fin solicitados.

## User Scenarios & Testing

### User Story 1 — Reservar una sala (Priority: P1)

Como estudiante autenticado, quiero reservar una sala de estudio por un intervalo de tiempo
para tener dónde trabajar con mi grupo.

**Why this priority**: sin reservas, la app no tiene propósito.

**Independent Test**: se puede probar creando una reserva y comprobando que queda registrada.

**Acceptance Scenarios**:

Salvo que se indique otra fecha o huso horario, las horas de cada escenario corresponden al
14 de octubre de 2026 en UTC-05:00. En los escenarios de aceptación no existen otras reservas
de la sala solicitada además de las indicadas. Cada escenario es independiente.

1. **Dado** que la sala A está libre, **Cuando** la reservo de 09:00 a 10:00, **Entonces** la
   reserva queda registrada a mi nombre.
2. **Dado** que elijo como inicio las 10:00 y como fin las 09:00, **Cuando** intento reservar,
   **Entonces** la reserva se rechaza con el mensaje "La hora de fin debe ser posterior a la de inicio".
3. **Dado** que la sala A ya está reservada de 09:00 a 10:00, **Cuando** solicito esa misma
   sala de 09:00 a 10:00, **Entonces** la solicitud se rechaza con el mensaje
   "La sala ya está reservada en ese horario." y no se registra otra reserva.
4. **Dado** que la sala A ya está reservada de 09:00 a 10:00, **Cuando** solicito esa misma
   sala de 09:30 a 10:30, **Entonces** la solicitud se rechaza con el mensaje
   "La sala ya está reservada en ese horario."
5. **Dado** que la sala A ya está reservada de 09:30 a 10:30, **Cuando** solicito esa misma
   sala de 09:00 a 10:00, **Entonces** la solicitud se rechaza con el mensaje
   "La sala ya está reservada en ese horario."
6. **Dado** que la sala A ya está reservada de 09:00 a 11:00, **Cuando** solicito esa misma
   sala de 10:00 a 10:30, **Entonces** la solicitud se rechaza con el mensaje
   "La sala ya está reservada en ese horario."
7. **Dado** que la sala A ya está reservada de 09:30 a 10:00, **Cuando** solicito esa misma
   sala de 09:00 a 11:00, **Entonces** la solicitud se rechaza con el mensaje
   "La sala ya está reservada en ese horario."
8. **Dado** que la sala A ya está reservada de 09:00 a 10:00, **Cuando** solicito esa misma
   sala de 10:00 a 11:00, **Entonces** la solicitud se acepta porque empieza cuando termina
   la reserva anterior.
9. **Dado** que la sala A ya está reservada de 10:00 a 11:00, **Cuando** solicito esa misma
   sala de 09:00 a 10:00, **Entonces** la solicitud se acepta porque termina cuando empieza
   la reserva anterior.
10. **Dado** que la sala A está reservada de 09:00 a 10:00, **Cuando** solicito la sala B de
    09:00 a 10:00, **Entonces** la solicitud se acepta porque las reservas son de salas distintas.
11. **Dado** que la sala A está reservada de 09:00 a 11:00, **Cuando** solicito esa sala de
    09:00 a 10:00 o de 09:00 a 12:00 (solicitudes independientes), **Entonces** cada solicitud
    se rechaza con "La sala ya está reservada en ese horario.", aunque solo coincida el inicio.
12. **Dado** que la sala A está reservada de 09:00 a 11:00, **Cuando** solicito esa sala de
    10:00 a 11:00 o de 08:00 a 11:00 (solicitudes independientes), **Entonces** cada solicitud
    se rechaza con "La sala ya está reservada en ese horario.", aunque solo coincida el fin.
13. **Dado** que la sala A está reservada de 09:00 a 11:00, **Cuando** solicito esa sala de
    07:00 a 08:00 o de 12:00 a 13:00 (solicitudes independientes), **Entonces** cada solicitud
    se acepta porque hay separación entre los intervalos.
14. **Dado** que yo mismo reservé la sala A de 09:00 a 10:00, **Cuando** vuelvo a solicitar
    ese intervalo, **Entonces** se rechaza con "La sala ya está reservada en ese horario."
    y se conserva únicamente la reserva original.
15. **Dado** que la sala A tiene varias reservas y solo una se cruza con mi solicitud,
    **Cuando** intento reservar, **Entonces** se rechaza con
    "La sala ya está reservada en ese horario.", independientemente del orden de las reservas.
16. **Dado** que la sala A está reservada de 08:00 a 09:00 y de 10:00 a 11:00,
    **Cuando** solicito esa sala de 09:00 a 10:00, **Entonces** se acepta y las dos reservas
    existentes permanecen intactas.
17. **Dado** que la sala A está reservada el 14 de octubre de 09:00 a 10:00,
    **Cuando** solicito esa sala el 15 de octubre de 09:00 a 10:00, **Entonces** se acepta
    porque son instantes diferentes.
18. **Dado** que la sala A está reservada del 14 de octubre a las 23:30 al 15 a las 00:30,
    **Cuando** solicito esa sala el 15 de 00:00 a 01:00, **Entonces** se rechaza con
    "La sala ya está reservada en ese horario."; cambiar de fecha no elimina el cruce.
19. **Dado** que la sala A está reservada de 09:00 a 10:00 en UTC-05:00,
    **Cuando** solicito esa sala de 14:30 a 15:30 UTC, **Entonces** se rechaza con
    "La sala ya está reservada en ese horario." porque los instantes se solapan.
20. **Dado** que la sala A está reservada de 09:00 a 10:00 en UTC-05:00,
    **Cuando** solicito esa sala de 15:00 a 16:00 UTC, **Entonces** se acepta porque el
    inicio coincide exactamente con el fin de la reserva existente.
21. **Dado** que la sala A está reservada de 09:00 a 10:00, **Cuando** solicito esa sala de
    09:59:59.999999 a 10:30, **Entonces** se rechaza con
    "La sala ya está reservada en ese horario."; compartir un solo microsegundo ya es solapamiento.
22. **Dado** que la sala A está reservada de 09:00 a 11:00, **Cuando** solicito esa sala con
    inicio y fin a las 10:00, o de 10:00 a 09:30 (solicitudes independientes), **Entonces**
    se rechaza con "La hora de fin debe ser posterior a la de inicio", sin cambiar la
    reserva existente ni mostrar el mensaje de solapamiento.
23. **Dado** que la sala A está libre, **Cuando** se acepta una reserva y después se solicita
    otra con los mismos instantes, **Entonces** solo queda registrada la primera y la segunda
    se rechaza con "La sala ya está reservada en ese horario.".

### Edge Cases

- Dos reservas de la misma sala se solapan cuando comparten algún instante ocupado; el instante
  de fin queda libre y puede coincidir con el inicio de otra reserva.
- La regla de solapamiento solo compara reservas de la misma sala.
- Compartir inicio o fin con una reserva no equivale a ser contiguas: si comparten tiempo
  ocupado, se rechaza la solicitud.
- La regla también se aplica a intervalos que cruzan medianoche o duran varios días.

## Requirements

### Functional Requirements

- **FR-001**: El estudiante puede elegir una sala y un intervalo de tiempo.
- **FR-002**: El sistema registra una reserva válida a nombre del estudiante autenticado.
- **FR-003**: La hora de fin debe ser posterior a la hora de inicio; de lo contrario, el sistema
  rechaza la solicitud con el mensaje "La hora de fin debe ser posterior a la de inicio".
- **FR-004**: El sistema rechaza una solicitud cuyo intervalo se solapa con otra reserva de la
  misma sala, e informa el rechazo con el mensaje exacto "La sala ya está reservada en ese horario."
- **FR-005**: Las reservas de salas distintas pueden ocupar el mismo intervalo.
- **FR-006**: Una reserva puede empezar cuando termina otra reserva de la misma sala o terminar
  cuando empieza otra reserva de la misma sala.
- **FR-007**: El rechazo por duración no positiva precede al rechazo por solapamiento.
- **FR-008**: Todo rechazo conserva las reservas existentes sin crear otra; toda aceptación
  registra exactamente una reserva a nombre del estudiante autenticado.
- **FR-009**: La regla compara instantes completos, sin redondeos, y se aplica también a las
  reservas del propio estudiante y a cualquier reserva de la misma sala, sea cual sea su orden.

### Key Entities

- **Reserva**: sala, estudiante, inicio y fin.
- **Sala**: identificada por su nombre (Sala A, Sala B, Sala C).

## Success Criteria

- **SC-001**: Un estudiante completa una reserva en menos de 30 segundos.
- **SC-002**: Todos los escenarios de aceptación producen el resultado y el mensaje exactos
  especificados. La contigüidad se acepta; cualquier tiempo ocupado compartido se rechaza.
- **SC-003**: Ninguna solicitud rechazada crea, modifica ni elimina reservas.
