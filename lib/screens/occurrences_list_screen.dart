import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../components/ocurrence_card.dart';

class OccurrencesListScreen extends StatefulWidget {
  const OccurrencesListScreen({super.key});

  @override
  State<OccurrencesListScreen> createState() => _OccurrencesListScreenState();
}

class _OccurrencesListScreenState extends State<OccurrencesListScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot> _getUserOccurrences() {
    if (_currentUser == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('map_markers')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text("Faça login para ver suas ocorrências."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getUserOccurrences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Você não registrou nenhuma ocorrência ainda."));
        }

        final List<DocumentSnapshot> ocorrencias = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(15.0),
          itemCount: ocorrencias.length,
          itemBuilder: (context, index) {
            final doc = ocorrencias[index];
            return OcurrenceCard(
              docId: doc.id,
              item: doc.data() as Map<String, dynamic>,
            );
          },
        );
      },
    );
  }
}