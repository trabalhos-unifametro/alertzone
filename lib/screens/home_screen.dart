import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;

  static const LatLng _fortalezaLocation = LatLng(-3.732778, -38.526944);
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _fortalezaLocation,
    zoom: 12.0,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LatLng? _currentPosition;
  String _statusMessage = "Carregando mapa...";

  final Set<Polygon> _polygons = {};

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
    // _loadMapElements();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFortalezaAsDefault('Serviços de localização desabilitados.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setFortalezaAsDefault(
            'Acesso à localização negado. Mapa centralizado em Fortaleza.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final newPosition = LatLng(position.latitude, position.longitude);

      _markers.removeWhere((m) => m.markerId.value == 'myLocation');
      _markers.add(
        Marker(
          markerId: const MarkerId('myLocation'),
          position: newPosition,
          infoWindow: const InfoWindow(title: 'Você está aqui!'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _statusMessage = "Localização obtida com sucesso.";
        if (mapController != null) {
          mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_currentPosition!, 16.0));
        }
      });
    } catch (e) {
      _setFortalezaAsDefault('Não foi possível obter a localização atual. Exibindo Fortaleza.');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllPointOccurrences() async {
    final querySnapshot = await _firestore
        .collection('map_markers')
        .where('type', isEqualTo: 'point')
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool isInside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      LatLng vertexI = polygon[i];
      LatLng vertexJ = polygon[j];

      bool intersect = ((vertexI.longitude > point.longitude) !=
          (vertexJ.longitude > point.longitude)) &&
          (point.latitude <
              (vertexJ.latitude - vertexI.latitude) *
                  (point.longitude - vertexI.longitude) /
                  (vertexJ.longitude - vertexI.longitude) +
                  vertexI.latitude);

      if (intersect) {
        isInside = !isInside;
      }
    }
    return isInside;
  }

  void _setFortalezaAsDefault(String message) {
    setState(() {
      _currentPosition = _fortalezaLocation;
      _statusMessage = message;
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(_fortalezaLocation, 12.0));
    });
  }

  Stream<List<Marker>> getMapElementsStream() {
    return _firestore.collection('map_markers').snapshots().map((snapshot) {
      final Set<Marker> firestoreMarkers = {};
      final Set<Polygon> firestorePolygons = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String itemId = doc.id;
        final String title = data['title'] ?? 'Ocorrência';
        final String type = data['type'] ?? 'point';

        try {

          if (type == 'area') {
            if (data['coordinates'] is List) {
              final List<LatLng> polygonPoints = [];
              for (final pointRaw in data['coordinates'] as List) {
                if (pointRaw is GeoPoint) {
                  polygonPoints.add(LatLng(pointRaw.latitude, pointRaw.longitude));
                }
              }

              if (polygonPoints.isNotEmpty) {
                firestorePolygons.add(
                  Polygon(
                    polygonId: PolygonId(itemId),
                    points: polygonPoints,
                    strokeWidth: 3,
                    strokeColor: Colors.red.shade900,
                    fillColor: Colors.red.shade900.withOpacity(0.35),
                    consumeTapEvents: true,
                    onTap: () => _showDetailsModal(itemId),
                  ),
                );
              }
            }
          }
          else if (type == 'point' || type.isEmpty) {
            if (data['coordinates'] is GeoPoint) {
              final GeoPoint geoPointRaw = data['coordinates'] as GeoPoint;
              final LatLng position = LatLng(geoPointRaw.latitude, geoPointRaw.longitude);

              final BitmapDescriptor icon = (data['occurrenceDetails']['occurredBus'] == true)
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

              firestoreMarkers.add(
                Marker(
                  markerId: MarkerId(itemId),
                  position: position,
                  infoWindow: InfoWindow(
                    title: title,
                    snippet: data['addressFull'] ?? 'Clique para ver detalhes',
                  ),
                  icon: icon,
                  onTap: () => _showDetailsModal(itemId),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Erro ao processar documento $itemId: $e');
        }
      }

      if (mounted) {
        _polygons
          ..clear()
          ..addAll(firestorePolygons);
      }
      return firestoreMarkers.toList();
    });
  }

  Occurrence _convertSingleOccurrence(Map<String, dynamic> firestoreData) {
    final details = firestoreData['occurrenceDetails'] as Map<String, dynamic>;
    final DateTime fullDateTime = (details['fullDateTime'] as Timestamp).toDate();

    final String cep = firestoreData['cep'] ?? 'Não Informado';
    final String street = firestoreData['street'] ?? 'Não Informado';
    final String number = firestoreData['number'] ?? '';
    final String neighborhood = firestoreData['neighborhood'] ?? 'Não Informado';
    final String city = firestoreData['city'] ?? 'Não Informado';
    final String state = firestoreData['state'] ?? 'NI';

    return Occurrence(
      date: DateFormat('dd/MM/yyyy').format(fullDateTime),
      time: DateFormat('HH:mm').format(fullDateTime),
      hasBo: details['hasBo'] ?? false,
      description: details['description'] ?? 'Sem descrição.',
      busLine: details['busLine'],
      cep: cep,
      street: street,
      number: number,
      neighborhood: neighborhood,
      city: city,
      state: state,
    );
  }

  Occurrence _convertAreaDescriptionToOccurrence(Map<String, dynamic> firestoreData) {
    final String description = firestoreData['description'] ?? 'Área de Atenção Geral sem ocorrências de ponto registradas.';

    return Occurrence(
      date: 'N/A',
      time: 'N/A',
      hasBo: false,
      description: description,
      busLine: null,
      cep: firestoreData['cep'] ?? 'Não Informado',
      street: firestoreData['street'] ?? firestoreData['title'] ?? 'Área de Atenção',
      number: '',
      neighborhood: firestoreData['neighborhood'] ?? 'Não Informado',
      city: firestoreData['city'] ?? 'Não Informado',
      state: firestoreData['state'] ?? 'NI',
    );
  }

  Future<void> _showDetailsModal(String itemId) async {
    final doc = await _firestore.collection('map_markers').doc(itemId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final String type = data['type'] ?? 'point';

    List<Occurrence> occurrences = [];
    String title = data['title'] ?? 'Detalhes';
    String addressFull = data['addressFull'] ?? 'Endereço Completo Indisponível';


    if (type == 'area') {
      final List<Map<String, dynamic>> allPointDocs = await _fetchAllPointOccurrences();
      final List<LatLng> areaPolygon = [];

      if (data['coordinates'] is List) {
        for (final pointRaw in data['coordinates'] as List) {
          if (pointRaw is GeoPoint) {
            areaPolygon.add(LatLng(pointRaw.latitude, pointRaw.longitude));
          }
        }
      }

      for (final pointData in allPointDocs) {
        if (pointData['coordinates'] is GeoPoint) {
          final GeoPoint pointGeo = pointData['coordinates'] as GeoPoint;
          final LatLng markerPosition = LatLng(pointGeo.latitude, pointGeo.longitude);

          if (_isPointInPolygon(markerPosition, areaPolygon)) {
            occurrences.add(_convertSingleOccurrence(pointData));
          }
        }
      }

      if (occurrences.isEmpty) {
        occurrences.add(_convertAreaDescriptionToOccurrence(data));
      }

    } else {
      occurrences.add(_convertSingleOccurrence(data));
    }

    final MapItemData mapData = MapItemData(
      id: itemId,
      title: title,
      addressFull: addressFull,
      occurrences: occurrences,
    );

    _onMapItemTapped(mapData);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_currentPosition != null) {
      final zoom = (_currentPosition == _fortalezaLocation) ? 12.0 : 16.0;
      controller.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, zoom));
    }
  }

  void _onMapItemTapped(MapItemData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildOccurrencesBottomSheet(context, data);
      },
    );
  }

  Widget _buildOccurrencesBottomSheet(BuildContext context, MapItemData data) {
    final Occurrence mainOccurrence = data.occurrences.first;

    String displayAddress = "${mainOccurrence.street}";
    if (mainOccurrence.number.isNotEmpty) {
      displayAddress += ", N° ${mainOccurrence.number}";
    }
    displayAddress += ", ${mainOccurrence.neighborhood}";

    String cityStateCep = "${mainOccurrence.city} - ${mainOccurrence.state} / CEP: ${mainOccurrence.cep}";

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              data.title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 15),

            Text(
              "📍 Endereço Principal do ${data.occurrences.length > 1 ? 'Ponto/Área' : 'Local'}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),

            Text(displayAddress, style: const TextStyle(fontSize: 16)),

            Text(cityStateCep, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 25),

            Text(
              "🚨 Ocorrências Encontradas (${data.occurrences.length})",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),

            ...data.occurrences.map((occurrence) {
              return _buildOccurrenceCard(context, occurrence);
            }).toList(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildOccurrenceCard(BuildContext context, Occurrence occurrence) {
    String displayAddress = "${occurrence.street}";
    if (occurrence.number.isNotEmpty) {
      displayAddress += ", N° ${occurrence.number}";
    }
    displayAddress += ", ${occurrence.neighborhood}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Data/horário: ${occurrence.date} às ${occurrence.time}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: occurrence.hasBo ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "B.O.? ${occurrence.hasBo ? 'SIM' : 'NÃO'}",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 15, color: Colors.grey),
            Text("Local: $displayAddress", style: const TextStyle(fontSize: 14)),
            const Divider(height: 15, color: Colors.grey),
            if (occurrence.busLine != null && occurrence.busLine!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🚌 Linha/ônibus: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(occurrence.busLine!)),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📝 Descrição: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(occurrence.description)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        StreamBuilder<List<Marker>>(
          stream: getMapElementsStream(),
          builder: (context, snapshot) {
            final bool isDataLoading = snapshot.connectionState == ConnectionState.waiting;

            if (isDataLoading) {
              return Stack(
                children: [
                  _buildGoogleMap(markers: _markers, polygons: _polygons),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
            }

            final Set<Marker> firestoreMarkers = snapshot.data?.toSet() ?? {};
            final Set<Marker> finalMarkers = {...firestoreMarkers, ..._markers};

            return _buildGoogleMap(markers: finalMarkers, polygons: _polygons);
          },
        ),

        // TODO: DESENVOLVER FUNÇÃO DEPOIS...
        // Positioned(
        //   bottom: 16.0,
        //   right: 16.0,
        //   child: FloatingActionButton.extended(
        //     onPressed: () {},
        //     label: const Text('ÔNIBUS'),
        //     icon: const Icon(Icons.directions_bus),
        //     backgroundColor: const Color(0xFF4268b3),
        //     foregroundColor: Colors.white,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildGoogleMap({required Set<Marker> markers, required Set<Polygon> polygons}) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: _currentPosition != null
          ? CameraPosition(target: _currentPosition!, zoom: 12.0)
          : _initialCameraPosition,
      mapType: MapType.normal,
      myLocationEnabled: _currentPosition != _fortalezaLocation,
      compassEnabled: true,
      markers: markers,
      polygons: polygons,
      padding: const EdgeInsets.only(bottom: 80.0),
    );
  }
}

class Occurrence {
  final String date;
  final String time;
  final bool hasBo;
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final String cep;
  final String description;
  final String? busLine;

  Occurrence({
    required this.date,
    required this.time,
    required this.hasBo,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
    required this.description,
    this.busLine,
  });
}

class MapItemData {
  final String id;
  final String title;
  final String addressFull;
  final List<Occurrence> occurrences;

  MapItemData({
    required this.id,
    required this.title,
    required this.addressFull,
    required this.occurrences,
  });
}
