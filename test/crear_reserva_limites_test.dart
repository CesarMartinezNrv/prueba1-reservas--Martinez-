import 'package:flutter_test/flutter_test.dart';
import 'package:reservas_sala/domain/crear_reserva.dart';
import 'package:reservas_sala/domain/reserva.dart';

import 'support/reservas_en_memoria.dart';

void main() {
  late ReservasEnMemoria repositorio;
  late CrearReserva crearReserva;

  setUp(() {
    repositorio = ReservasEnMemoria();
    crearReserva = CrearReserva(repositorio);
  });

  void ocupar({
    String sala = 'Sala A',
    String usuario = 'otro-estudiante',
    String inicio = '2026-10-14T09:00:00Z',
    String fin = '2026-10-14T11:00:00Z',
  }) {
    repositorio.reservas.add(Reserva(
      id: 'existente-${repositorio.reservas.length}',
      salaId: sala,
      usuarioId: usuario,
      inicio: DateTime.parse(inicio),
      fin: DateTime.parse(fin),
    ));
  }

  SolicitudReserva solicitud(String inicio, String fin) => SolicitudReserva(
        salaId: 'Sala A',
        usuarioId: 'estudiante-actual',
        inicio: DateTime.parse(inicio),
        fin: DateTime.parse(fin),
      );

  Future<void> comprobarRechazo(
    SolicitudReserva solicitud, {
    String mensaje = 'La sala ya está reservada en ese horario.',
  }) async {
    final originales = List<Reserva>.of(repositorio.reservas);

    final resultado = await crearReserva(solicitud);

    expect(resultado.aceptada, isFalse);
    expect(resultado.mensaje, mensaje);
    expect(resultado.reserva, isNull);
    expect(repositorio.reservas, orderedEquals(originales));
  }

  Future<void> comprobarAceptacion(SolicitudReserva solicitud) async {
    final originales = List<Reserva>.of(repositorio.reservas);

    final resultado = await crearReserva(solicitud);

    expect(resultado.aceptada, isTrue);
    expect(resultado.mensaje, isNull);
    expect(resultado.reserva, isNotNull);
    final creada = resultado.reserva!;
    expect(creada.salaId, solicitud.salaId);
    expect(creada.usuarioId, solicitud.usuarioId);
    expect(creada.inicio, solicitud.inicio);
    expect(creada.fin, solicitud.fin);
    expect(repositorio.reservas, orderedEquals([...originales, creada]));
  }

  group('extremos compartidos con tiempo ocupado', () {
    final casos = [
      (nombre: 'mismo inicio, fin anterior', inicio: '09:00', fin: '10:00'),
      (nombre: 'mismo inicio, fin posterior', inicio: '09:00', fin: '12:00'),
      (nombre: 'mismo fin, inicio posterior', inicio: '10:00', fin: '11:00'),
      (nombre: 'mismo fin, inicio anterior', inicio: '08:00', fin: '11:00'),
    ];

    for (final caso in casos) {
      test('rechaza ${caso.nombre}', () async {
        ocupar();

        await comprobarRechazo(solicitud(
          '2026-10-14T${caso.inicio}:00Z',
          '2026-10-14T${caso.fin}:00Z',
        ));
      });
    }
  });

  group('intervalos separados', () {
    final casos = [
      (
        nombre: 'anterior',
        inicio: '2026-10-14T07:00:00Z',
        fin: '2026-10-14T08:00:00Z',
      ),
      (
        nombre: 'posterior',
        inicio: '2026-10-14T12:00:00Z',
        fin: '2026-10-14T13:00:00Z',
      ),
      (
        nombre: 'mismas horas en otro día',
        inicio: '2026-10-15T09:00:00Z',
        fin: '2026-10-15T11:00:00Z',
      ),
    ];

    for (final caso in casos) {
      test('acepta ${caso.nombre} y conserva todos los datos', () async {
        ocupar();

        await comprobarAceptacion(solicitud(caso.inicio, caso.fin));
      });
    }
  });

  test('rechaza también el solapamiento con una reserva propia', () async {
    ocupar(usuario: 'estudiante-actual');

    await comprobarRechazo(solicitud(
      '2026-10-14T09:00:00Z',
      '2026-10-14T11:00:00Z',
    ));
  });

  for (final invertir in [false, true]) {
    test('revisa todas las reservas aunque estén desordenadas ($invertir)',
        () async {
      ocupar(inicio: '2026-10-14T16:00:00Z', fin: '2026-10-14T17:00:00Z');
      ocupar(sala: 'Sala B');
      ocupar(inicio: '2026-10-14T07:00:00Z', fin: '2026-10-14T08:00:00Z');
      ocupar();
      if (invertir) {
        final invertidas = repositorio.reservas.reversed.toList();
        repositorio.reservas
          ..clear()
          ..addAll(invertidas);
      }

      await comprobarRechazo(solicitud(
        '2026-10-14T10:00:00Z',
        '2026-10-14T12:00:00Z',
      ));
    });
  }

  test('acepta el hueco exacto entre dos reservas e ignora otra sala',
      () async {
    ocupar(inicio: '2026-10-14T10:00:00Z', fin: '2026-10-14T11:00:00Z');
    ocupar(inicio: '2026-10-14T08:00:00Z', fin: '2026-10-14T09:00:00Z');
    ocupar(sala: 'Sala B');

    await comprobarAceptacion(solicitud(
      '2026-10-14T09:00:00Z',
      '2026-10-14T10:00:00Z',
    ));
  });

  test('rechaza un cruce de un solo microsegundo', () async {
    ocupar(fin: '2026-10-14T10:00:00Z');

    await comprobarRechazo(solicitud(
      '2026-10-14T09:59:59.999999Z',
      '2026-10-14T10:30:00Z',
    ));
  });

  test('acepta contigüidad exacta con precisión de microsegundos', () async {
    ocupar(fin: '2026-10-14T10:00:00.000001Z');

    await comprobarAceptacion(solicitud(
      '2026-10-14T10:00:00.000001Z',
      '2026-10-14T10:00:00.000002Z',
    ));
  });

  test('rechaza el cruce de medianoche', () async {
    ocupar(inicio: '2026-10-14T23:30:00Z', fin: '2026-10-15T00:30:00Z');

    await comprobarRechazo(solicitud(
      '2026-10-15T00:00:00Z',
      '2026-10-15T01:00:00Z',
    ));
  });

  test('rechaza la contención dentro de una reserva de varios días', () async {
    ocupar(inicio: '2026-10-13T20:00:00Z', fin: '2026-10-16T06:00:00Z');

    await comprobarRechazo(solicitud(
      '2026-10-14T09:00:00Z',
      '2026-10-14T10:00:00Z',
    ));
  });

  test('compara instantes equivalentes expresados con distinto huso horario',
      () async {
    ocupar(
      inicio: '2026-10-14T09:00:00-05:00',
      fin: '2026-10-14T10:00:00-05:00',
    );

    await comprobarRechazo(solicitud(
      '2026-10-14T14:30:00Z',
      '2026-10-14T15:30:00Z',
    ));
  });

  test('acepta contigüidad entre horarios con distinta zona', () async {
    ocupar(
      inicio: '2026-10-14T09:00:00-05:00',
      fin: '2026-10-14T10:00:00-05:00',
    );

    await comprobarAceptacion(solicitud(
      '2026-10-14T15:00:00Z',
      '2026-10-14T16:00:00Z',
    ));
  });

  test('compara reservas UTC con solicitudes locales por su instante',
      () async {
    ocupar();
    final enUtc = solicitud('2026-10-14T09:30:00Z', '2026-10-14T10:30:00Z');

    await comprobarRechazo(SolicitudReserva(
      salaId: enUtc.salaId,
      usuarioId: enUtc.usuarioId,
      inicio: enUtc.inicio.toLocal(),
      fin: enUtc.fin.toLocal(),
    ));
  });

  for (final fin in ['10:00', '09:30']) {
    test('prioriza duración inválida sobre solapamiento con fin $fin',
        () async {
      ocupar();

      await comprobarRechazo(
        solicitud('2026-10-14T10:00:00Z', '2026-10-14T$fin:00Z'),
        mensaje: 'La hora de fin debe ser posterior a la de inicio',
      );
    });
  }

  test('rechaza duración nula incluso cuando la sala está libre', () async {
    await comprobarRechazo(
      solicitud('2026-10-14T10:00:00Z', '2026-10-14T10:00:00Z'),
      mensaje: 'La hora de fin debe ser posterior a la de inicio',
    );
  });

  test('una reserva recién aceptada bloquea la siguiente solicitud idéntica',
      () async {
    final nueva = solicitud('2026-10-14T09:00:00Z', '2026-10-14T10:00:00Z');

    await comprobarAceptacion(nueva);
    await comprobarRechazo(nueva);
  });
}
