import 'package:alertzone/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OcurrenceCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> item;

  const OcurrenceCard({required this.docId, required this.item});

  @override
  State<OcurrenceCard> createState() => _OcurrenceCardState();
}

class _OcurrenceCardState extends State<OcurrenceCard> {
  bool _isExpanded = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> get _details => widget.item['occurrenceDetails'] ?? {};
  GeoPoint get _coords => widget.item['coordinates'] as GeoPoint;

  String _formatDateTime() {
    final Timestamp timestamp = _details['fullDateTime'] as Timestamp;
    final DateTime dateTime = timestamp.toDate();
    final date = DateFormat('dd/MM/yyyy').format(dateTime);
    final time = DateFormat('HH:mm').format(dateTime);
    return '$date às $time';
  }

  void _onEditTapped() {
    context.goNamed('form',
      queryParameters: {'mode': 'edit'},
      extra: {
      'docIdToEdit': widget.docId,
      'initialData': widget.item,
    });
  }

  Future<void> _onDeleteTapped() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja apagar esta ocorrência?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('map_markers').doc(widget.docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocorrência apagada com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao apagar ocorrência.')),
        );
      }
    }
  }

  Widget _buildBOPill(bool comBO) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: comBO ? Colors.green.shade600 : Colors.red.shade600,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        comBO ? 'SIM' : 'NÃO',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 0),
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 10),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 10),
                )),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Data/horário: ${_formatDateTime()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Text('Com B.O?', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          _buildBOPill(_details['hasBo'] ?? false),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 15),

                  if (_details['occurredBus'] == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('Linha/Ônibus: ${_details['busLine'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),

                  Text('Endereço: ${widget.item['addressFull'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Descrição: ${_details['description'] ?? 'N/A'}'),
                ],
              ),
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            height: _isExpanded ? 55 : 0,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _onEditTapped,
                    icon: Icon(Icons.edit, color: _isExpanded ? Colors.white : Colors.transparent),
                    label: const Text('EDITAR', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _onDeleteTapped,
                    icon: Icon(Icons.delete, color: _isExpanded ? Colors.white : Colors.transparent),
                    label: const Text('APAGAR', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}