import 'package:flutter/material.dart';
import 'calculator.dart';
import 'package:intl/intl.dart';

void main() => runApp(SkifijaApp());

class SkifijaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дежурный Макс — Расчёт графика',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _kmCtrl = TextEditingController(text: '300');
  final _speedCtrl = TextEditingController(text: '75');
  final _9hCtrl = TextEditingController(text: '3');
  final _10hCtrl = TextEditingController(text: '2');
  bool _comfort = true;

  Map<String, dynamic>? _result;
  DateTime _startTime = DateTime.now();

  void _runCalc() {
    final km = double.tryParse(_kmCtrl.text) ?? 0.0;
    final speed = double.tryParse(_speedCtrl.text) ?? 1.0;
    final nine = int.tryParse(_9hCtrl.text) ?? 0;
    final ten = int.tryParse(_10hCtrl.text) ?? 0;

    final res = calculatePlan(
      remainingKm: km,
      avgSpeed: speed,
      available9h: nine,
      available10h: ten,
      comfortMode: _comfort,
      startTime: _startTime,
    );

    setState(() {
      _result = res;
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('Дежурный Макс — Расчёт')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: _kmCtrl, decoration: InputDecoration(labelText: 'Оставшиеся км'))),
            SizedBox(width: 8),
            Expanded(child: TextField(controller: _speedCtrl, decoration: InputDecoration(labelText: 'Средняя скорость (км/ч)'))),
          ]),
          Row(children: [
            Expanded(child: TextField(controller: _9hCtrl, decoration: InputDecoration(labelText: 'Доступно 9h (шт)'), keyboardType: TextInputType.number)),
            SizedBox(width: 8),
            Expanded(child: TextField(controller: _10hCtrl, decoration: InputDecoration(labelText: 'Доступно 10h (шт)'), keyboardType: TextInputType.number)),
          ]),
          SwitchListTile(title: Text('Комфортный режим'), value: _comfort, onChanged: (v) => setState(() => _comfort = v)),
          SizedBox(height: 8),
          Row(children: [
            ElevatedButton(onPressed: _runCalc, child: Text('Быстрый расчёт')),
            SizedBox(width: 8),
            ElevatedButton(onPressed: _runCalc, child: Text('Комфортный расчёт')),
          ]),
          SizedBox(height: 12),
          Expanded(child: _result == null ? Center(child: Text('Результат появится здесь')) : ResultView(result: _result!)),
        ]),
      ),
    );
  }
}

class ResultView extends StatelessWidget {
  final Map<String, dynamic> result;
  ResultView({required this.result});
  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return iso;
    }
  }

  @override Widget build(BuildContext ctx) {
    final steps = result['steps'] as List<dynamic>;
    return ListView(
      children: [
        Card(child: ListTile(title: Text('Total driving hours: ${result['total_driving_hours']}'))),
        Card(child: ListTile(title: Text('Next break after (hours): ${result['next_break_after_hours']}'))),
        ...steps.map((s) {
          final start = s.containsKey('start_time') ? _fmtDate(s['start_time']) : '-';
          return ListTile(
            leading: Icon(s['action'] == 'drive' ? Icons.drive_eta : Icons.hotel),
            title: Text('${s['action'].toString().toUpperCase()} — ${s['duration_minutes']} мин'),
            subtitle: Text('start: $start, distance: ${s['distance_km'] ?? '-'} km'),
          );
        }),
        if ((result['warnings'] as List).isNotEmpty) ...[
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...((result['warnings'] as List).map((w) => ListTile(title: Text('- $w')))),
        ]
      ],
    );
  }
}