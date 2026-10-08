# Feature Specification: Reservas de sala

**Feature Branch**: `001-reservas-sala`
**Created**: 2026-10-01
**Status**: Draft

## User Scenarios & Testing

### User Story 1 — Reservar una sala (Priority: P1)

Como estudiante autenticado, quiero reservar una sala de estudio por un intervalo de tiempo
para tener dónde trabajar con mi grupo.

**Why this priority**: sin reservas, la app no tiene propósito.

**Independent Test**: se puede probar creando una reserva y comprobando que queda registrada.

**Acceptance Scenarios**:

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

### Edge Cases

- Dos reservas de la misma sala se solapan cuando comparten algún instante ocupado; el instante
  de fin queda libre y puede coincidir con el inicio de otra reserva.
- La regla de solapamiento solo compara reservas de la misma sala.

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

### Key Entities

- **Reserva**: sala, estudiante, inicio y fin.
- **Sala**: identificada por su nombre (Sala A, Sala B, Sala C).

## Success Criteria

- **SC-001**: Un estudiante completa una reserva en menos de 30 segundos.
