import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/item.dart';
import '../routes/app_routes.dart';
import '../services/device_image_picker.dart';
import '../utils/validators.dart';
import '../utils/campus_locations.dart';
import '../services/location_service.dart';
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
  final _imagePicker = const DeviceImagePicker();

  String? _category;
  bool _hasAttemptedSubmit = false;
  bool _isSubmitting = false;
  bool _isPickingPhoto = false;
  bool _isDetectingLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedBuildingName;
  String? _errorMessage;
  Uint8List? _imageData;
  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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
    if (_isPickingPhoto || _isSubmitting) return; // Mencegah pemilihan foto berulang atau saat laporan sedang dikirim
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
          _selectedBuildingName = landmark;
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
      _selectedBuildingName = result.buildingName;
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
      Navigator.pop<Item>(context, item); //
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
      //widget PopScope digunakan untuk menangani navigasi kembali dengan hasil tertentu
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            // lea
            tooltip: 'Kembali',
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),

          title: Text(
            'Buat Laporan Barang ${widget.isFound ? 'Ditemukan' : 'Hilang'}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          titleSpacing: 0,
        ),

        body: SafeArea(
          //widget SafeArea digunakan untuk memastikan konten tidak tertutup oleh elemen sistem seperti notch atau status bar
          top: false,
          child: Form(
            key: _formKey,
            autovalidateMode: _hasAttemptedSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: ListView(
              //widget ListView digunakan untuk membuat daftar yang dapat digulir
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                const Text(
                  'Informasi Barang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isFound
                      ? 'Catat barang yang Anda temukan agar pemiliknya dapat mengambil kembali.'
                      : 'Laporkan barang yang hilang agar orang lain dapat membantu menemukannya.',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Nama Barang', required: true),
                const SizedBox(height: 7),
                TextFormField(
                  key: const Key('report-name'),
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.sentences, // t
                  textInputAction: TextInputAction.next,
                  validator: Validators.reportName,
                  decoration: _inputDecoration('Contoh: Dompet Kulit'),
                ),
                const SizedBox(height: 12),
                _fieldLabel('Kategori', required: true),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  key: const Key('report-category'),
                  initialValue: _category,
                  hint: const Text('Pilih Kategori'),
                  decoration: _inputDecoration(null),
                  validator: Validators.reportCategory,
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged:
                      _isSubmitting // m
                      ? null
                      : (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 12),
                _fieldLabel('Deskripsi', required: true),
                const SizedBox(height: 7),
                TextFormField(
                  key: const Key('report-description'),
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  minLines: 3,
                  maxLines: 4,
                  //maxLength: 50,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.reportDescription,
                  decoration: _inputDecoration(
                    'Jelaskan ciri-ciri barang secara detail',
                  ),
                ),
                const SizedBox(height: 12),
                _fieldLabel('Waktu Kejadian'),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        key: const Key('report-date'),
                        onPressed: _isSubmitting ? null : _selectDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(_formattedDate),
                        style: _pickerButtonStyle(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        key: const Key('report-time'),
                        onPressed: _isSubmitting ? null : _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_formattedTime),
                        style: _pickerButtonStyle(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _fieldLabel(
                      widget.isFound ? 'Lokasi Ditemukan' : 'Lokasi Terakhir',
                      required: true,
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: _green,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed:
                          _isSubmitting ? null : _openCampusLocationPicker,
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text(
                        'Pilih di Peta Kampus',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                TextFormField(
                  key: const Key('report-location'),
                  controller: _locationController,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  validator: Validators.reportLocation,
                  onChanged: (val) {
                    if (_selectedBuildingName != null &&
                        val != _selectedBuildingName) {
                      setState(() {
                        _selectedLatitude = null;
                        _selectedLongitude = null;
                        _selectedBuildingName = null;
                      });
                    }
                  },
                  decoration: _inputDecoration(
                    widget.isFound
                        ? 'Contoh: Kantin Fakultas Teknik'
                        : 'Contoh: Perpustakaan Pusat',
                  ).copyWith(
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Pilih di Peta Kampus',
                          icon: const Icon(Icons.map_outlined, color: _green, size: 20),
                          onPressed: _isSubmitting
                              ? null
                              : _openCampusLocationPicker,
                        ),
                        IconButton(
                          tooltip: 'Deteksi GPS Sekarang',
                          icon: _isDetectingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location, color: _green, size: 20),
                          onPressed: _isDetectingLocation || _isSubmitting
                              ? null
                              : _detectGpsLocation,
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
                                        _selectedBuildingName = landmark;
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
                _fieldLabel('Foto Barang'),
                const SizedBox(height: 7),
                OutlinedButton.icon(
                  key: const Key('report-photo'),
                  onPressed: _isSubmitting || _isPickingPhoto
                      ? null
                      : _selectPhoto,
                  icon: _isPickingPhoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    _isPickingPhoto
                        ? 'Memilih foto...'
                        : _imageData == null
                        ? 'Foto Barang'
                        : 'Ganti Foto Barang',
                  ),
                  style: _pickerButtonStyle(),
                ),
                if (_imageData != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _imageData!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    key: const Key('report-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 28),
                Center(
                  child: FilledButton(
                    key: const Key('submit-report'),
                    onPressed: _isSubmitting ? null : _submitReport,
                    child: _isSubmitting
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
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
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 12),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF999999)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF999999)),
      ),
    );
  }

  ButtonStyle _pickerButtonStyle() {
    // Mengatur gaya tombol untuk pemilihan tanggal, waktu, dan foto
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      side: const BorderSide(color: Color(0xFF999999)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
