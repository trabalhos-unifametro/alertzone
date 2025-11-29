import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alertzone/service/auth_service.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? _currentUser!.displayName ?? '';
      _phoneController.text = data['phone'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _photoUrl = data['photoUrl'] ?? _currentUser!.photoURL;
    } else {
      _nameController.text = _currentUser!.displayName ?? '';
      _photoUrl = _currentUser!.photoURL;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveUserData() async {
    if (_currentUser == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateProfileData(
        uid: _currentUser!.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        contact: _contactController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _changeProfilePhoto() async {
    if (_isLoading) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() => _isLoading = true);
      final url = await _authService.uploadProfileImage(image, _currentUser!.uid);

      if (mounted && url != null) {
        setState(() {
          _photoUrl = url;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada!')),
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao enviar foto.')),
        );
      }
    }
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 30),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _photoUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          Center(
            child: GestureDetector(
              onTap: _changeProfilePhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blueGrey,
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black26)],
                      ),
                      child: _isLoading ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)
                      ) : const Icon(Icons.edit, color: Color(0xFF4268b3), size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text('Clique na foto de perfil para alterá-la.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),

          _buildEditableField(label: 'Nome', controller: _nameController, hint: 'Nome de usuário'),
          _buildEditableField(label: 'Telefone', controller: _phoneController, hint: '(##) # ####-####', keyboardType: TextInputType.phone),
          _buildEditableField(label: 'Contato', controller: _contactController, hint: 'Campo livre'),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveUserData,
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_isLoading ? 'SALVANDO...' : 'SALVAR ALTERAÇÕES'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4268b3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'OBS: As informações acima, serão armazenadas com segurança e não serão divulgadas, elas servirão apenas para um possível contato futuro caso seja necessário.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}