import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/crear_reserva.dart';
import '../domain/reserva.dart';

class ReservaPage extends StatefulWidget {
  const ReservaPage({super.key, required this.crearReserva});

  final CrearReserva crearReserva;

  @override
  State<ReservaPage> createState() => _ReservaPageState();
}

class _ReservaPageState extends State<ReservaPage> {
  static const _salas = ['Sala A', 'Sala B', 'Sala C'];

  String _sala = _salas.first;
  TimeOfDay _inicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _fin = const TimeOfDay(hour: 10, minute: 0);
  String? _mensaje;
  bool _cargando = false;

  DateTime _hoyA(TimeOfDay hora) {
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day, hora.hour, hora.minute);
  }

  Future<void> _elegirHora({required bool esInicio}) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: esInicio ? _inicio : _fin,
    );
    if (hora == null || !mounted) {
      return;
    }
    setState(() {
      if (esInicio) {
        _inicio = hora;
      } else {
        _fin = hora;
      }
    });
  }

  Future<void> _reservar() async {
    final usuario = Supabase.instance.client.auth.currentUser;
    if (usuario == null) {
      setState(() => _mensaje = 'Inicia sesión para crear una reserva.');
      return;
    }

    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      final resultado = await widget.crearReserva(
        SolicitudReserva(
          salaId: _sala,
          usuarioId: usuario.id,
          inicio: _hoyA(_inicio),
          fin: _hoyA(_fin),
        ),
      );
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _mensaje = resultado.aceptada
            ? 'Reserva creada'
            : resultado.mensaje ?? 'No se pudo crear la reserva.';
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _mensaje = e.code == '23P01'
            ? 'La sala ya está reservada en ese horario.'
            : 'No se pudo reservar: ${e.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _mensaje = 'No se pudo crear la reserva. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Reservar sala')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (usuario == null)
              const Text('Inicia sesión para crear una reserva.')
            else
              Text('Sesión: ${usuario.email ?? 'usuario autenticado'}'),
            DropdownButton<String>(
              value: _sala,
              items: _salas
                  .map((sala) =>
                      DropdownMenuItem(value: sala, child: Text(sala)))
                  .toList(),
              onChanged: _cargando
                  ? null
                  : (valor) => setState(() => _sala = valor ?? _sala),
            ),
            ListTile(
              title: Text('Inicio: ${_inicio.format(context)}'),
              trailing: const Icon(Icons.schedule),
              onTap: _cargando ? null : () => _elegirHora(esInicio: true),
            ),
            ListTile(
              title: Text('Fin: ${_fin.format(context)}'),
              trailing: const Icon(Icons.schedule),
              onTap: _cargando ? null : () => _elegirHora(esInicio: false),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _cargando || usuario == null ? null : _reservar,
              child: Text(_cargando ? 'Procesando…' : 'Reservar'),
            ),
            if (_mensaje != null) ...[
              const SizedBox(height: 16),
              Text(_mensaje!),
            ],
          ],
        ),
      ),
    );
  }
}
