import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/item.dart';
import '../routes/app_routes.dart';
import '../services/app_session.dart';
import '../services/device_image_picker.dart';
import '../services/location_service.dart';
import '../utils/campus_locations.dart';
import '../utils/validators.dart';
import 'campus_location_picker_screen.dart';

class AddReportScreen extends StatefulWidget {
  final bool isFound; // parameter untuk menentukan apakah laporan ini untuk barang yang ditemukan atau hilang

  const AddReportScreen({super.key, required this.isFound});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  static const _green = Color(0xFF045436);
  static const _categories = [
    'Elektronik',
    'Dompet & Kartu',
    'Tas & Ransel',
    'Kunci & Kendaraan',
    'Dokumen & Perlengkapan Kuliah',
    'Pakaian & Aksesori',
    'Botol & Perlengkapan Makan',
    'Perlengkapan Ibadah',
    'Perlengkapan Olahraga',
    'Dokumen',
    'Aksesori',
    'Lainnya',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _colorController = TextEditingController();
  final _brandController = TextEditingController();
  final _verificationController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _imagePicker = const DeviceImagePicker();

  String? _category;
  bool _hasAttemptedSubmit = false;
  bool _isSubmitting = false;
  bool _isPickingPhoto = false;
  bool _isDetectingLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _errorMessage;
  Uint8List? _imageData;
  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _colorController.dispose();
    _brandController.dispose();
    _verificationController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    try {
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: _eventDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (!mounted) return;
      if (selectedDate != null) {
        setState(() => _eventDate = selectedDate);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memilih tanggal: $error');
    }
  }

  Future<void> _selectTime() async {
    try {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: _eventTime,
      );
      if (!mounted) return;
      if (selectedTime != null) {
        setState(() => _eventTime = selectedTime);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memilih waktu: $error');
    }
  }

  Future<void> _selectPhoto() async {
    if (_isPickingPhoto || _isSubmitting) return;
    setState(() {
      _isPickingPhoto = true;
      _errorMessage = null;
    });
    try {
      final imageData = await _imagePicker.pickImage();
      if (!mounted) return;
      if (imageData != null) setState(() => _imageData = imageData);
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memilih foto: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memilih foto: $error');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _detectGpsLocation() async {
    if (_isDetectingLocation || _isSubmitting) return;
    setState(() => _isDetectingLocation = true);
    try {
      const locationService = LocationService();
      final res = await locationService.determinePosition();
      if (!mounted) return;
      if (res.isSuccess && res.position != null) {
        final landmark = CampusLocations.getNearestLandmark(res.position!);
        setState(() {
          _locationController.text = landmark;
          _selectedLatitude = res.position!.latitude;
          _selectedLongitude = res.position!.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi terdeteksi: $landmark'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _openCampusLocationPicker() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    final result = await Navigator.pushNamed<CampusLocationResult>(
      context,
      AppRoutes.locationPicker,
      arguments: {
        'initialLocationName': _locationController.text.trim(),
        'initialCenter': _selectedLatitude != null && _selectedLongitude != null
            ? LatLng(_selectedLatitude!, _selectedLongitude!)
            : null,
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _locationController.text = result.locationName;
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lokasi terpilih: ${result.locationName}'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _hasAttemptedSubmit = true);
      return;
    }

    setState(() {
      _hasAttemptedSubmit = true;
      _isSubmitting = true;
      _errorMessage = null;
    });

    late final Item item;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      final eventDateTime = DateTime(
        _eventDate.year,
        _eventDate.month,
        _eventDate.day,
        _eventTime.hour,
        _eventTime.minute,
      );

      final verificationText = _verificationController.text.trim();
      final verificationDetails = verificationText.isEmpty
          ? const <String>[]
          : [verificationText];

      item = Item(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nameItem:
            _nameController.text.trim()[0].toUpperCase() +
            _nameController.text.trim().substring(1),
        subtitle:
            '${widget.isFound ? 'Ditemukan' : 'Hilang'} di sekitar '
            '${_locationController.text.trim()}',
        description:
            _descriptionController.text.trim()[0].toUpperCase() +
            _descriptionController.text.trim().substring(1),
        location:
            _locationController.text.trim()[0].toUpperCase() +
            _locationController.text.trim().substring(1),
        isFound: widget.isFound,
        category: _category!,
        eventDate: eventDateTime,
        imageData: _imageData,
        isOwner: true,
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        reporter: AppSession.userId != null ? 'Saya' : 'Pelapor',
        ownerId: AppSession.userId ?? 'user:local',
        verificationDetails: verificationDetails,
        whatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        latitude: _selectedLatitude ??
            CampusLocations.getCoordinates(_locationController.text.trim()).latitude,
        longitude: _selectedLongitude ??
            CampusLocations.getCoordinates(_locationController.text.trim()).longitude,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Laporan gagal dikirim: $error');
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: _green, size: 42),
          title: const Text('Laporan berhasil dikirim'),
          content: const Text(
            'Laporan barang sudah ditambahkan ke daftar laporan.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Kembali ke daftar'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop<Item>(context, item);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Laporan gagal dikirim: $error');
    }
  }

  String get _formattedDate {
    final day = _eventDate.day.toString().padLeft(2, '0');
    final month = _eventDate.month.toString().padLeft(2, '0');
    return '$day/$month/${_eventDate.year}';
  }

  String get _formattedTime {
    return '${_eventTime.hour.toString().padLeft(2, '0')}:'
        '${_eventTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Item>(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          title: Text(
            widget.isFound
                ? 'Buat Laporan Barang Ditemukan'
                : 'Buat Laporan Barang Hilang',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MaterialBanner(
                    content: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red.shade700,
                    actions: [
                      TextButton(
                        onPressed: () => setState(() => _errorMessage = null),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              Form(
                key: _formKey,
                autovalidateMode: _hasAttemptedSubmit
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldLabel('Nama Barang', required: true),
                    const SizedBox(height: 7),
                    TextFormField(
                      key: const Key('report-name'),
                      controller: _nameController,
                      enabled: !_isSubmitting,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      validator: Validators.reportName,
                      decoration: _inputDecoration(
                        widget.isFound
                            ? 'Contoh: Dompet Kulit Coklat'
                            : 'Contoh: Tumbler Corkcicle',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Kategori', required: true),
                    const SizedBox(height: 7),
                    DropdownButtonFormField<String>(
                      key: const Key('report-category'),
                      initialValue: _category,
                      decoration: _inputDecoration('Pilih kategori'),
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(() => _category = value),
                      validator: Validators.reportCategory,
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel(
                      widget.isFound ? 'Lokasi Ditemukan' : 'Lokasi Terakhir Dilihat',
                      required: true,
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      key: const Key('report-location'),
                      controller: _locationController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      validator: Validators.reportLocation,
                      decoration: _inputDecoration(
                        'Contoh: Gedung Kuliah Bersama, Gedung B, Library...',
                      ).copyWith(
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Deteksi GPS',
                              icon: _isDetectingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _green,
                                      ),
                                    )
                                  : const Icon(Icons.my_location, color: _green),
                              onPressed: _isDetectingLocation || _isSubmitting
                                  ? null
                                  : _detectGpsLocation,
                            ),
                            IconButton(
                              tooltip: 'Pilih di Peta Kampus',
                              icon: const Icon(Icons.map_outlined, color: _green),
                              onPressed: _isSubmitting
                                  ? null
                                  : _openCampusLocationPicker,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedLatitude != null && _selectedLongitude != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x33045436)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: _green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Titik terhubung di peta: ${_selectedLatitude!.toStringAsFixed(4)}, ${_selectedLongitude!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _openCampusLocationPicker,
                              child: const Text(
                                'Ubah',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _green,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: const Icon(Icons.map, size: 14, color: _green),
                              label: const Text(
                                'Pilih di Peta',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: _isSubmitting ? null : _openCampusLocationPicker,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: const Icon(Icons.my_location, size: 14, color: _green),
                              label: const Text('GPS Terdekat', style: TextStyle(fontSize: 11)),
                              onPressed: _isDetectingLocation || _isSubmitting
                                  ? null
                                  : _detectGpsLocation,
                            ),
                          ),
                          ...CampusLocations.landmarkNames.take(8).map((landmark) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(landmark, style: const TextStyle(fontSize: 11)),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        setState(() {
                                          _locationController.text = landmark;
                                          final coords = CampusLocations.landmarks[landmark];
                                          if (coords != null) {
                                            _selectedLatitude = coords.latitude;
                                            _selectedLongitude = coords.longitude;
                                          }
                                        });
                                      },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Deskripsi', required: true),
                    const SizedBox(height: 7),
                    TextFormField(
                      key: const Key('report-description'),
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      maxLines: 3,
                      maxLength: 150,
                      validator: Validators.reportDescription,
                      decoration: _inputDecoration(
                        'Ciri khusus, kondisi barang, dll.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Warna'),
                              const SizedBox(height: 7),
                              TextFormField(
                                controller: _colorController,
                                enabled: !_isSubmitting,
                                decoration: _inputDecoration('Contoh: Hitam'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Merek / Brand'),
                              const SizedBox(height: 7),
                              TextFormField(
                                controller: _brandController,
                                enabled: !_isSubmitting,
                                decoration: _inputDecoration('Contoh: Samsung'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Detail Pembeda Rahasia (Opsional)'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _verificationController,
                      enabled: !_isSubmitting,
                      decoration: _inputDecoration(
                        'Hanya digunakan untuk verifikasi klaim kepemilikan',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Waktu Kejadian'),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _selectDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(_formattedDate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _selectTime,
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(_formattedTime),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('WhatsApp (Opsional)'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _whatsappController,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Contoh: 08123456789'),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Foto Barang'),
                    const SizedBox(height: 7),
                    InkWell(
                      onTap: _isSubmitting ? null : _selectPhoto,
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: _imageData != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      _imageData!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        onPressed: _isSubmitting
                                            ? null
                                            : () => setState(
                                                () => _imageData = null,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 38,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unggah Foto Barang',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        key: const Key('submit-report'),
                        onPressed: _isSubmitting ? null : _submitReport,
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Mengirim laporan...'),
                                ],
                              )
                            : const Text(
                                'Kirim Laporan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: _green,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
    );
  }
}
