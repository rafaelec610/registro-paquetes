import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';


class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _index = 0;

  final List<Widget> _screens = [
    const UsuariosScreen(),
    const ActividadScreen(),
    const CrearUsuarioScreen(),
    AdminMetricasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Actividad'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Crear'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Métricas'),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////
/// USUARIOS
//////////////////////////////////////////////////////

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final u = users[i];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          u['nombres'][0],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),

                       Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${u['nombres']} ${u['apellidos']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Doc: ${u['documento']}'),
                            const SizedBox(height: 6),
                            Chip(
                              label: Text(u['rol'].toUpperCase()),
                              backgroundColor: u['rol'] == 'admin'
                              ? Colors.red.shade100
                              : u['rol'] == 'cajero'
                                ? Colors.blue.shade100
                                : Colors.green.shade100,
                            ),
                          ],
                        ),
                      ),

                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditarUsuarioScreen(
                                uid: u.id,
                                data: u.data(),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: () async {
                        await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(u.id)
                          .delete();
                        },
                      ),
                    ],
                  )
                ],
              ),
           ),
          );
          },
        );
      },
    );
  }
}

//////////////////////////////////////////////////////
/// EDITAR USUARIO
//////////////////////////////////////////////////////

class EditarUsuarioScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;

  const EditarUsuarioScreen({super.key, required this.uid, required this.data});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  late TextEditingController nombres;
  late TextEditingController apellidos;
  late String rol;

  @override
  void initState() {
    super.initState();
    nombres = TextEditingController(text: widget.data['nombres']);
    apellidos = TextEditingController(text: widget.data['apellidos']);
    rol = widget.data['rol'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nombres, decoration: const InputDecoration(labelText: 'Nombres')),
            TextField(controller: apellidos, decoration: const InputDecoration(labelText: 'Apellidos')),

            DropdownButton<String>(
              value: rol,
              items: const [
                DropdownMenuItem(value: 'cajero', child: Text('Cajero')),
                DropdownMenuItem(value: 'repartidor', child: Text('Repartidor')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (v) => setState(() => rol = v!),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.uid)
                    .update({
                  'nombres': nombres.text,
                  'apellidos': apellidos.text,
                  'rol': rol,
                });

                Navigator.pop(context);
              },
              child: const Text('Guardar cambios'),
            )
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
/// CREAR USUARIO
//////////////////////////////////////////////////////

class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombres = TextEditingController();
  final apellidos = TextEditingController();
  final documento = TextEditingController();
  final correo = TextEditingController();
  final password = TextEditingController();

  String rol = 'cajero';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextField(controller: nombres, decoration: const InputDecoration(labelText: 'Nombres')),
            TextField(controller: apellidos, decoration: const InputDecoration(labelText: 'Apellidos')),
            TextField(controller: documento, decoration: const InputDecoration(labelText: 'Documento')),
            TextField(controller: correo, decoration: const InputDecoration(labelText: 'Correo')),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),

            DropdownButton<String>(
              value: rol,
              items: const [
                DropdownMenuItem(value: 'cajero', child: Text('Cajero')),
                DropdownMenuItem(value: 'repartidor', child: Text('Repartidor')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (v) => setState(() => rol = v!),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final cred = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                  email: correo.text,
                  password: password.text,
                );

                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(cred.user!.uid)
                    .set({
                  'nombres': nombres.text,
                  'apellidos': apellidos.text,
                  'documento': documento.text,
                  'correo': correo.text,
                  'rol': rol,
                  'fechaRegistro': Timestamp.now(),
                  'activo': true,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuario creado correctamente')),
                );
              },
              child: const Text('Crear usuario'),
            )
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
/// ACTIVIDAD
//////////////////////////////////////////////////////

class ActividadScreen extends StatelessWidget {
  const ActividadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('actividad')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, i) {
            final l = logs[i];

            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(l['accion']),
              subtitle: Text('Usuario: ${l['uid']}'),
              trailing: Text(l['fecha'].toDate().toString()),
            );
          },
        );
      },
    );
  }
}

class AdminMetricasScreen extends StatelessWidget {
  AdminMetricasScreen({super.key});

  Future<void> generarMetricas(BuildContext context) async {
    const url =
        'https://us-central1-registro-paquetes.cloudfunctions.net/generarMetricasDiariasManual';

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Métricas generadas correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar métricas')),
      );
    }
  }

  Widget _card(String title, dynamic value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget graficaBarras(Map<String, dynamic> total) {
    double d(dynamic v) => (v ?? 0).toDouble();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(toY: d(total['entradas']), color: Colors.blue),
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(toY: d(total['entregas']), color: Colors.green),
            ]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(toY: d(total['devoluciones']), color: Colors.orange),
            ]),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Entradas');
                    case 1:
                      return const Text('Entregas');
                    case 2:
                      return const Text('Devoluciones');
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );  
  }
  Widget graficaPorRol(Map<String, dynamic> data) {
    double d(dynamic v) => (v ?? 0).toDouble();

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: d(data['cajero']?['entregas']),
              title: 'Cajero',
              color: Colors.blue,
            ),
            PieChartSectionData(
              value: d(data['repartidor']?['entregas']),
              title: 'Repartidor',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  
  Widget graficaMensual(List<QueryDocumentSnapshot> docs) {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: docs.asMap().entries.map((e) {
                final total = e.value['total'];
                return FlSpot(
                  e.key.toDouble(),
                  total['entregas'].toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Generar métricas ahora'),
            onPressed: () => generarMetricas(context),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('metricas_diarias')
                .orderBy('fecha', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No hay métricas registradas'),
                );
              }

              final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
              final QueryDocumentSnapshot doc = docs.first;
              final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              final Map<String, dynamic> total = data['total'];

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    '📅 Métricas del día ${data['fecha']}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _card('Entradas', total['entradas'], Colors.blue),
                      _card('Entregas', total['entregas'], Colors.green),
                      _card('Devoluciones', total['devoluciones'], Colors.orange),
                      _card('Oficina', total['oficina'], Colors.purple),
                      _card('Domicilio', total['domicilio'], Colors.teal),
                      _card('🟢 Verdes', total['verde'], Colors.green),
                      _card('🟡 Amarillos', total['amarillo'], Colors.amber),
                      _card('🔴 Rojos', total['rojo'], Colors.red),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '📊 Actividad del día',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  graficaBarras(total),

                  const SizedBox(height: 20),
                  const Text(
                    '👥 Distribución por rol',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  graficaPorRol(data),

                  const SizedBox(height: 20),
                  const Text(
                    '📈 Tendencia mensual',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  graficaMensual(docs),


                  const SizedBox(height: 20),

                  const Text(
                    '👥 Por Rol',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: ListTile(
                      title: const Text('Cajero'),
                      subtitle: Text(
                        'Entradas: ${data['cajero']['entradas']} | '
                        'Entregas: ${data['cajero']['entregas']} | '
                        'Devoluciones: ${data['cajero']['devoluciones']}',
                      ),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      title: const Text('Repartidor'),
                      subtitle: Text(
                        'Entregas: ${data['repartidor']['entregas']} | '
                        'Devoluciones: ${data['repartidor']['devoluciones']}',
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.analytics),
                    label: const Text(
                      'Generar métricas del día',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => generarMetricas(context),
                  ),

                ],
              );
            },
          ),
        ),

      ],
    );
  }
}
