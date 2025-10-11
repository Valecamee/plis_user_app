import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisViajesScreen extends StatelessWidget {
  const MisViajesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mis viajes")),
        body: const Center(child: Text("Debes iniciar sesión.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mis viajes programados")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('travels')
            .where('usuarios.${user.uid}', isGreaterThan: 0)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tienes viajes reservados aún."));
          }

          final viajes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: viajes.length,
            itemBuilder: (context, index) {
              final viaje = viajes[index];
              final data = viaje.data() as Map<String, dynamic>;
              final plazasReservadas = data['usuarios'][user.uid];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${data['origen']} → ${data['destino']}"),
                  subtitle: Text(
                    "Plazas reservadas: $plazasReservadas\nFecha: ${data['fechaViaje'].toDate()}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
