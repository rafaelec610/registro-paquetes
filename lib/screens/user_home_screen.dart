import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fcm_service.dart';

import 'profile_screen.dart';
import 'entrada_paquetes_screen.dart';
import 'entrega_paquetes_screen.dart';
import 'devolucion_paquetes_screen.dart';
import 'cuadre_diario_screen.dart';
import '../widgets/animated_button.dart';
import '../utils/page_transitions.dart';
import 'historial_paquetes_screen.dart';
import 'todos_los_paquetes_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  Widget _card(String titulo, dynamic valor, IconData icono, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Stream<DocumentSnapshot<Map<String, dynamic>>> metricasHoy() {
    final hoy = DateTime.now();
    final fecha =
        "${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";

    return FirebaseFirestore.instance
        .collection('metricas_diarias')
        .doc(fecha)
        .snapshots();
  }

  String nombre = 'Usuario';
  String? fotoUrl;
  String rol = '';

  final user = FirebaseAuth.instance.currentUser;
  late AnimationController _controller;

  Future<void> loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    setState(() {
      nombre = doc['nombres'] ?? 'Usuario';
      fotoUrl = doc['foto'];
      rol = doc['rol'] ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FCMService.initialize(context);
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedItem(
    int index,
    String title,
    Widget? screen,
    IconData icon, {
    bool isLogout = false,
  }) {
    final animation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.1 * index,
          1,
          curve: Curves.easeOut,
        ),
      ),
    );

    return SlideTransition(
      position: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: AnimatedButton(
          text: title,
          icon: icon,
          color: isLogout ? Colors.red : Colors.white,
          onPressed: () async {
            Navigator.pop(context);

            if (isLogout) {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            } else {
              Navigator.push(context, routeSlide(screen!));

            }
          },
        ),
      ),
    );
  }
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Usuario')),

      drawer: Drawer(
        child: Column(
          children: [

            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedScale(
                    scale: 1,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          fotoUrl != null ? NetworkImage(fotoUrl!) : null,
                      child: fotoUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nombre,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    rol,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            _animatedItem(1, 'Mi Perfil', const ProfileScreen(), Icons.person),
            _animatedItem(2, 'Entrada de paquetes', const EntradaPaquetesScreen(), Icons.qr_code),
            _animatedItem(3, 'Entrega de paquetes', const EntregaPaquetesScreen(), Icons.local_shipping),
            _animatedItem(4, 'Devolución de paquetes', const DevolucionPaquetesScreen(), Icons.undo),
            
            if (rol == 'Cajero')
              _animatedItem(5, 'Cuadre diario', const CuadreDiarioScreen(), Icons.attach_money),

            const Divider(),
            _animatedItem(6, 'Paquetes del día', HistorialPaquetesScreen(), Icons.table_chart),
            _animatedItem(7,'Todos los paquetes',const TodosLosPaquetesScreen(), Icons.inventory),

            _animatedItem(8, 'Cerrar sesión', null, Icons.logout, isLogout: true),
            


          ],
        ),
      ),

      body: FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Bienvenido, $nombre',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Rol: $rol',
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: metricasHoy(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.data() == null) {
                      return const Center(
                        child: Text(
                          'No hay métricas registradas hoy',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final total = data['total'] ?? data;


                    return GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      children: [
                        _card("Entradas", total['entradas'], Icons.inbox, Colors.blue),
                        _card("Entregas", total['entregas'], Icons.local_shipping, Colors.green),
                        _card("Devoluciones", total['devoluciones'], Icons.undo, Colors.orange),
                        _card("Oficina", total['oficina'], Icons.store, Colors.purple),
                        _card("Domicilio", total['domicilio'], Icons.home, Colors.teal),
                        _card("🟢 Verdes", total['verde'], Icons.circle, Colors.green),
                        _card("🟡 Amarillos", total['amarillo'], Icons.circle, Colors.amber),
                        _card("🔴 Rojos", total['rojo'], Icons.circle, Colors.red),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Actividad reciente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Paquete entregado'),
                      subtitle: Text('Hace 10 minutos'),
                    ),
                    ListTile(
                      leading: Icon(Icons.inbox, color: Colors.blue),
                      title: Text('Nuevo paquete registrado'),
                      subtitle: Text('Hace 1 hora'),
                    ),
                    ListTile(
                      leading: Icon(Icons.undo, color: Colors.orange),
                      title: Text('Paquete devuelto'),
                      subtitle: Text('Ayer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),

    );
  }
}
