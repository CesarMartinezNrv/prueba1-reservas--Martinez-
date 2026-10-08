import 'package:flutter_test/flutter_test.dart';
import 'package:reservas_sala/domain/crear_reserva.dart';
import 'package:reservas_sala/domain/reserva.dart';

import 'support/reservas_en_memoria.dart';

DateTime hora(int h, [int m = 0]) => DateTime(2026, 10, 14, h, m);

void main() {
  late ReservasEnMemoria repositorio;
  late CrearReserva crearReserva;

  setUp(() {
    repositorio = ReservasEnMemoria();
    crearReserva = CrearReserva(repositorio);
  });

  void ocuparSala({
    String salaId = 'Sala A',
    required int inicio,
    int minutoInicio = 0,
    required int fin,
    int minutoFin = 0,
  }) {
    repositorio.reservas.add(Reserva(
      id: 'existente-${repositorio.reservas.length + 1}',
      salaId: salaId,
      usuarioId: 'u0',
      inicio: hora(inicio, minutoInicio),
      fin: hora(fin, minutoFin),
    ));
  }

  Future<ResultadoReserva> solicitarReserva({
    String salaId = 'Sala A',
    required int inicio,
    int minutoInicio = 0,
    required int fin,
    int minutoFin = 0,
  }) {
    return crearReserva(SolicitudReserva(
      salaId: salaId,
      usuarioId: 'u1',
      inicio: hora(inicio, minutoInicio),
      fin: hora(fin, minutoFin),
    ));
  }

  void esperarRechazoPorSolapamiento(ResultadoReserva resultado) {
    expect(resultado.aceptada, isFalse);
    expect(resultado.mensaje, 'La sala ya está reservada en ese horario.');
    expect(repositorio.reservas, hasLength(1));
  }

  test('acepta una reserva válida y la guarda', () async {
    final resultado = await crearReserva(SolicitudReserva(
      salaId: 'Sala A',
      usuarioId: 'u1',
      inicio: hora(9),
      fin: hora(10),
    ));

    expect(resultado.aceptada, isTrue);
    expect(repositorio.reservas, hasLength(1));
  });

  test('rechaza una reserva cuyo fin no es posterior al inicio', () async {
    final resultado = await crearReserva(SolicitudReserva(
      salaId: 'Sala A',
      usuarioId: 'u1',
      inicio: hora(10),
      fin: hora(9),
    ));

    expect(resultado.aceptada, isFalse);
    expect(
        resultado.mensaje, 'La hora de fin debe ser posterior a la de inicio');
    expect(repositorio.reservas, isEmpty);
  });

  test('rechaza una reserva con el mismo intervalo de la misma sala', () async {
    ocuparSala(inicio: 9, fin: 10);

    final resultado = await solicitarReserva(inicio: 9, fin: 10);

    esperarRechazoPorSolapamiento(resultado);
  });

  test('rechaza una reserva que empieza durante otra y termina después',
      () async {
    ocuparSala(inicio: 9, fin: 10);

    final resultado = await solicitarReserva(
      inicio: 9,
      minutoInicio: 30,
      fin: 10,
      minutoFin: 30,
    );

    esperarRechazoPorSolapamiento(resultado);
  });

  test('rechaza una reserva que empieza antes de otra y termina durante ella',
      () async {
    ocuparSala(inicio: 9, minutoInicio: 30, fin: 10, minutoFin: 30);

    final resultado = await solicitarReserva(inicio: 9, fin: 10);

    esperarRechazoPorSolapamiento(resultado);
  });

  test('rechaza una reserva contenida dentro de otra', () async {
    ocuparSala(inicio: 9, fin: 11);

    final resultado = await solicitarReserva(
      inicio: 10,
      fin: 10,
      minutoFin: 30,
    );

    esperarRechazoPorSolapamiento(resultado);
  });

  test('rechaza una reserva que contiene completamente otra', () async {
    ocuparSala(inicio: 9, minutoInicio: 30, fin: 10);

    final resultado = await solicitarReserva(inicio: 9, fin: 11);

    esperarRechazoPorSolapamiento(resultado);
  });

  test('acepta una reserva que empieza cuando termina la anterior', () async {
    ocuparSala(inicio: 9, fin: 10);

    final resultado = await solicitarReserva(inicio: 10, fin: 11);

    expect(resultado.aceptada, isTrue);
    expect(repositorio.reservas, hasLength(2));
  });

  test('acepta una reserva que termina cuando empieza la siguiente', () async {
    ocuparSala(inicio: 10, fin: 11);

    final resultado = await solicitarReserva(inicio: 9, fin: 10);

    expect(resultado.aceptada, isTrue);
    expect(repositorio.reservas, hasLength(2));
  });

  test('acepta el mismo intervalo si corresponde a otra sala', () async {
    ocuparSala(salaId: 'Sala A', inicio: 9, fin: 10);

    final resultado = await solicitarReserva(
      salaId: 'Sala B',
      inicio: 9,
      fin: 10,
    );

    expect(resultado.aceptada, isTrue);
    expect(repositorio.reservas, hasLength(2));
  });
}
