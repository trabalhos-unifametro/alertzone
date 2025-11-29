import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:math' show cos, sin, pi;

class GeocodeResult {
  final LatLng center;
  final List<LatLng>? boundingBox;

  GeocodeResult({required this.center, this.boundingBox});
}

class RegisterOccurrenceScreen extends StatefulWidget {
  final LatLng? initialCoordinates;
  final String? docIdToEdit;
  final Map<String, dynamic>? initialData;
  const RegisterOccurrenceScreen({
    super.key,
    this.initialCoordinates,
    this.docIdToEdit,
    this.initialData,
  });

  @override
  State<RegisterOccurrenceScreen> createState() => _RegisterOccurrenceScreenState();
}

class _RegisterOccurrenceScreenState extends State<RegisterOccurrenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _registrationType = 'point';

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _busLineController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  bool _cepValidated = false;

  bool _houveBO = false;
  bool _ocorreuOnibus = false;
  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isDataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.docIdToEdit != null && !_isDataLoaded) {
      _loadInitialData(widget.initialData!);
      _isDataLoaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCoordinates != null && widget.docIdToEdit == null) {
      _reverseGeocodeAddress(widget.initialCoordinates!);
    }
  }

  void _loadInitialData(Map<String, dynamic> data) {
    final details = data['occurrenceDetails'] as Map<String, dynamic>;
    _registrationType = data['type'] ?? 'point';

    _descriptionController.text = details['description'] ?? '';
    _busLineController.text = details['busLine'] ?? '';
    _houveBO = details['hasBo'] ?? false;
    _ocorreuOnibus = details['occurredBus'] ?? false;
    _cepController.text = data['cep'] ?? '';
    _streetController.text = data['street'] ?? '';
    _numberController.text = data['number'] ?? '';
    _neighborhoodController.text = data['neighborhood'] ?? '';
    _cityController.text = data['city'] ?? '';
    _stateController.text = data['state'] ?? '';
    _countryController.text = data['country'] ?? '';

    if (details['fullDateTime'] is Timestamp) {
      final DateTime fullDateTime = (details['fullDateTime'] as Timestamp).toDate();
      _selectedDate = DateTime(fullDateTime.year, fullDateTime.month, fullDateTime.day);
      _selectedTime = TimeOfDay.fromDateTime(fullDateTime);

      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }

    if (_selectedTime != null) {
      _timeController.text = _selectedTime!.format(context);
    }
    if (_cepController.text.isNotEmpty) {
      _cepValidated = true;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _busLineController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _searchCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cep.length != 8) {
      _clearAddressFields(clearNumber: false);
      return;
    }

    setState(() {
      _isLoading = true;
      _cepValidated = false;
      _clearAddressFields(clearNumber: false);
    });

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data.containsKey('cep') && data['erro'] != true) {
        _streetController.text = data['logradouro'] ?? '';
        _neighborhoodController.text = data['bairro'] ?? '';
        _cityController.text = data['localidade'] ?? '';
        _stateController.text = data['uf'] ?? '';
        _countryController.text = 'Brasil';

        _cepValidated = true;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        FocusScope.of(context).nextFocus();
      } else {
        _cepValidated = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CEP não encontrado ou inválido.')),
        );
      }
    } catch (e) {
      _cepValidated = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao buscar CEP.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearAddressFields({bool clearNumber = true}) {
    _streetController.clear();
    _neighborhoodController.clear();
    _cityController.clear();
    _stateController.clear();
    _countryController.clear();
    if (clearNumber) {
      _numberController.clear();
    }
  }

  Future<void> _reverseGeocodeAddress(LatLng coords) async {
    setState(() => _isLoading = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      );

      if (placemarks.isNotEmpty) {
        final street = placemarks.first.thoroughfare ?? placemarks.first.street ?? '';
        final cep = placemarks.first.postalCode?.replaceAll('-', '') ?? '';

        _cepController.text = cep;
        if (cep.length == 8) {
          await _searchCep();
          if (_cepValidated && _numberController.text.isEmpty) {
            _streetController.text = street;
          }
        } else {
          _streetController.text = street;
        }
      }
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  Future<GeocodeResult?> _geocodeAddress(String address) async {
    try {
      if (kIsWeb) {
        return await _geocodeWeb(address);
      } else {
        return await _geocodeMobile(address);
      }
    } catch (e) {
      print("Erro ao geocodificar: $e");
      return null;
    }
  }

  Future<GeocodeResult?> _geocodeMobile(String address) async {
    final locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      final loc = locations.first;
      final center = LatLng(loc.latitude, loc.longitude);
      return GeocodeResult(center: center);
    }
    return null;
  }

  Future<GeocodeResult?> _geocodeWeb(String address) async {
    // final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    const String googleMapsApiKey = String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: ''
    );
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleMapsApiKey");

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data["status"] == "OK" && data["results"].isNotEmpty) {
      final result = data["results"][0];
      final location = result["geometry"]["location"];
      final center = LatLng(location["lat"] as double, location["lng"] as double);

      final bounds = result["geometry"]["bounds"];

      if (bounds != null) {
        final northeast = bounds["northeast"];
        final southwest = bounds["southwest"];

        final boundingBoxPoints = [
          LatLng(northeast["lat"] as double, southwest["lng"] as double),
          LatLng(northeast["lat"] as double, northeast["lng"] as double),
          LatLng(southwest["lat"] as double, northeast["lng"] as double),
          LatLng(southwest["lat"] as double, southwest["lng"] as double),
        ];
        return GeocodeResult(center: center, boundingBox: boundingBoxPoints);
      }

      return GeocodeResult(center: center);
    }

    return null;
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;

          _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
          _timeController.text = pickedTime.format(context);
        });
      }
    }
  }

  Future<void> _registerOccurrence() async {
    final isEditing = widget.docIdToEdit != null;
    final isArea = _registrationType == 'area';

    if (!_formKey.currentState!.validate() || _isLoading || _currentUser == null || !_cepValidated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(!_cepValidated ? 'O endereço deve ser validado pelo CEP antes de prosseguir.' : 'Por favor, preencha todos os campos obrigatórios e faça login.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String addressForGeocoding = isArea
        ? '${_neighborhoodController.text}, ${_cityController.text}, ${_stateController.text}, ${_countryController.text}'
        : '${_streetController.text}, ${_numberController.text.isNotEmpty ? "Nº ${_numberController.text}, " : ""}'
        '${_neighborhoodController.text}, ${_cityController.text}, '
        '${_stateController.text}, CEP ${_cepController.text}, ${_countryController.text}';

    final fullAddress = addressForGeocoding;

    LatLng? centerCoordinates;
    List<LatLng> polygonPoints = [];
    GeocodeResult? geocodeResult;


    if (isEditing && widget.initialData != null) {
      final dynamic originalGeo = widget.initialData!['coordinates'];

      if (originalGeo is GeoPoint) {
        centerCoordinates = LatLng(originalGeo.latitude, originalGeo.longitude);
      } else if (originalGeo is List) {
        polygonPoints = originalGeo.map((p) => LatLng(p.latitude, p.longitude)).toList();
        if (polygonPoints.isNotEmpty) {
          centerCoordinates = polygonPoints.first;
        }
      }
    }

    if (centerCoordinates == null || (isArea && polygonPoints.isEmpty)) {
      geocodeResult = await _geocodeAddress(addressForGeocoding);
      centerCoordinates = geocodeResult?.center;
    }


    if (centerCoordinates == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível determinar a localização do endereço. Verifique o CEP/Bairro.')),
      );
      return;
    }

    if (isArea && polygonPoints.isEmpty) {
      if (geocodeResult?.boundingBox != null) {
        polygonPoints = geocodeResult!.boundingBox!;
      } else {
        const double offsetDegree = 0.02;

        polygonPoints = [
          LatLng(centerCoordinates.latitude + offsetDegree, centerCoordinates.longitude - offsetDegree),
          LatLng(centerCoordinates.latitude + offsetDegree, centerCoordinates.longitude + offsetDegree),
          LatLng(centerCoordinates.latitude - offsetDegree, centerCoordinates.longitude + offsetDegree),
          LatLng(centerCoordinates.latitude - offsetDegree, centerCoordinates.longitude - offsetDegree),
        ];
      }
    }

    try {
      final fullDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);

      final dynamic coordinatesToSave = isArea
          ? polygonPoints.map((p) => GeoPoint(p.latitude, p.longitude)).toList()
          : GeoPoint(centerCoordinates.latitude, centerCoordinates.longitude);

      final Map<String, dynamic> dataToSave = {
        'cep': _cepController.text.trim(),
        'street': _streetController.text.trim(),
        'number': _numberController.text.trim(),
        'neighborhood': _neighborhoodController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'addressFull': fullAddress,
        'type': _registrationType,
        'coordinates': coordinatesToSave,
        'occurrenceDetails': {
          'description': _descriptionController.text.trim(),
          'fullDateTime': fullDateTime,
          'hasBo': _houveBO,
          'occurredBus': _ocorreuOnibus,
          'busLine': _ocorreuOnibus ? _busLineController.text.trim() : null,
        }
      };

      if (isEditing) {
        await _firestore.collection('map_markers').doc(widget.docIdToEdit).set(
          dataToSave,
          SetOptions(merge: true),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocorrência atualizada com sucesso!')),
        );

      } else {
        final occurrenceId = _firestore.collection('map_markers').doc().id;

        dataToSave.addAll({
          'markerId': occurrenceId,
          'title': isArea ? 'Área de Risco: ${_neighborhoodController.text}' : 'Ocorrência registrada por ${_auth.currentUser!.displayName ?? 'Usuário'}',
          'userId': _auth.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('map_markers').doc(occurrenceId).set(dataToSave);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArea ? 'Área de risco registrada com sucesso!' : 'Ocorrência registrada com sucesso!')),
        );
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/home');
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar ocorrência: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.docIdToEdit != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_isLoading && widget.initialCoordinates != null)
              const LinearProgressIndicator(),

            const Text('Tipo de Registro', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Ponto (Marker)'),
                    value: 'point',
                    groupValue: _registrationType,
                    onChanged: isEditing ? null : (String? value) {
                      setState(() {
                        _registrationType = value!;
                        _clearAddressFields(clearNumber: true);
                        _cepValidated = false;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Área (Polígono)'),
                    value: 'area',
                    groupValue: _registrationType,
                    onChanged: isEditing ? null : (String? value) {
                      setState(() {
                        _registrationType = value!;
                        _clearAddressFields(clearNumber: true);
                        _cepValidated = false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório.' : null,
              decoration: const InputDecoration(
                hintText: 'Descreva o que ocorreu...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Data e Horário', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    validator: (v) => v!.isEmpty ? 'Data obrigatória.' : null,
                    decoration: InputDecoration(
                      hintText: 'DD/MM/AAAA HH:MM',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: _selectDateTime,
                      ),
                    ),
                  ),
                ),
                if (_timeController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Houve Registro de B.O?', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: _houveBO,
                  onChanged: (bool value) {
                    setState(() {
                      _houveBO = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('CEP', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'CEP é obrigatório.' : null,
              decoration: InputDecoration(
                hintText: '00000-000',
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading ?
                const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)) :
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchCep,
                ),
              ),
              onEditingComplete: _searchCep,
            ),
            const SizedBox(height: 20),

            if (_registrationType == 'point') ...[
              const Text('Número (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Número da residência/estabelecimento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Rua', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _streetController,
                readOnly: true,
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Rua preenchida automaticamente',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: (_cepValidated || isEditing) ? const Color.fromARGB(255, 230, 230, 230) : null,
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text('Bairro', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _neighborhoodController,
              readOnly: true,
              enabled: false,
              validator: (v) => _cepValidated ? null : 'Aguardando validação do CEP.',
              decoration: InputDecoration(
                hintText: 'Bairro preenchido automaticamente',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: (_cepValidated || isEditing) ? const Color.fromARGB(255, 230, 230, 230) : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cidade', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cityController,
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'Cidade',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: (_cepValidated || isEditing) ? const Color.fromARGB(255, 230, 230, 230) : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _stateController,
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'UF',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: (_cepValidated || isEditing) ? const Color.fromARGB(255, 230, 230, 230) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('País', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _countryController,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'País preenchido automaticamente',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: (_cepValidated || isEditing) ? const Color.fromARGB(255, 230, 230, 230) : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Ocorreu dentro de um ônibus?', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: _ocorreuOnibus,
                  onChanged: (bool value) {
                    setState(() {
                      _ocorreuOnibus = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_ocorreuOnibus) ...[
              const Text('Linha do Ônibus', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _busLineController,
                decoration: const InputDecoration(
                  hintText: 'Ex: 000 - Bairro XYZ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerOccurrence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4268b3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEditing ? 'ATUALIZAR' : 'REGISTRAR', style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}