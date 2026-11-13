import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:find_it/core/services/location_service.dart';
import 'package:find_it/core/utils/validators.dart';
import 'package:find_it/features/report/domain/report_rules.dart';
import 'package:find_it/features/report/models/report.dart';
import 'package:find_it/features/report/models/report_category.dart';
import 'package:find_it/features/report/models/report_photo_entry.dart';
import 'package:find_it/features/report/screens/blur_editor_screen.dart';
import 'package:find_it/features/report/services/device_image_picker.dart';
import 'package:find_it/features/report/widgets/report_photo_section.dart';

/// Form buat/ubah laporan. Jika [editItem] diisi, layar berjalan dalam mode
/// edit (FR-R04) dan mengembalikan `Item` hasil perubahan lewat `pop`.
class AddReportScreen extends StatefulWidget {
  final bool isFound;
  final Item? editItem;

  const AddReportScreen({super.key, required this.isFound, this.editItem});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  static const _green = Color(0xFF0A5934);
  static const _ink = Color(0xFF14282C);
  static const _muted = Color(0xFF63777B);
  static const _outline = Color(0xFF9BAEB2);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final _brandController = TextEditingController();
  final _secretDetailController = TextEditingController();
  final _locationController = TextEditingController();
  final _imagePicker = const DeviceImagePicker();
  final _locationService = const LocationService();

  final List<ReportPhotoEntry> _photos = [];

  String? _category;
  String? _category2;
  ItemKeeping? _keeping;
  double? _latitude;
  double? _longitude;
  bool _hasAttemptedSubmit = false;
  bool _isSubmitting = false;
  bool _isPickingPhoto = false;
  bool _isLocating = false;
  String? _errorMessage;
  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = TimeOfDay.now();

  bool get _isEdit => widget.editItem != null;

  /// FR-R09: field inti dikunci saat ada klaim yang sedang diverifikasi.
  bool get _coreLocked =>
      _isEdit && !ReportRules.canEditCoreFields(widget.editItem!);

  bool get _isSensitiveCategory => ReportCategories.isSensitiveName(_category);

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    if (item == null) return;
    _nameController.text = item.nameItem;
    _descriptionController.text = item.description;
    _colorController.text = item.color ?? '';
    _brandController.text = item.brand ?? '';
    _secretDetailController.text = item.secretDetail ?? '';
    _locationController.text = item.location;
    _category = item.category;
    _category2 = item.category2;
    _keeping = item.keeping;
    _latitude = item.latitude;
    _longitude = item.longitude;
    final date = item.eventDate;
    if (date != null) {
      _eventDate = DateTime(date.year, date.month, date.day);
      _eventTime = TimeOfDay(hour: date.hour, minute: date.minute);
    }
    for (final bytes in item.photos) {
      // Foto lama dianggap sudah diproses; tidak divalidasi ulang (FR-R11).
      _photos.add(ReportPhotoEntry(bytes, blurred: true));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _brandController.dispose();
    _secretDetailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- Tanggal/waktu

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

  DateTime get _eventDateTime => DateTime(
    _eventDate.year,
    _eventDate.month,
    _eventDate.day,
    _eventTime.hour,
    _eventTime.minute,
  );

  // ---------------------------------------------------------------- Kategori

  Future<void> _pickSecondCategory() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Kategori kedua (opsional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Untuk barang gabungan, mis. tas berisi laptop'),
            ),
            ListTile(
              title: const Text('Tidak ada'),
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
            for (final category in ReportCategories.all)
              if (category.name != _category)
                ListTile(
                  title: Text(category.name),
                  subtitle: Text(category.examples),
                  selected: category.name == _category2,
                  onTap: () => Navigator.pop(sheetContext, category.name),
                ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    setState(() => _category2 = choice.isEmpty ? null : choice);
  }

  // ------------------------------------------------------------------ Lokasi

  Future<void> _useCurrentLocation() async {
    if (_isLocating || _isSubmitting) return;
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });
    final point = await _locationService.currentPosition();
    if (!mounted) return;
    setState(() {
      _isLocating = false;
      if (point == null) {
        // NFR-03: izin ditolak/GPS mati tidak menghalangi pengisian manual.
        _errorMessage =
            'Lokasi tidak dapat dibaca. Isi nama gedung/area secara manual.';
      } else {
        _latitude = point.latitude;
        _longitude = point.longitude;
      }
    });
  }

  // -------------------------------------------------------------------- Foto

  Future<void> _addPhoto() async {
    if (_isPickingPhoto ||
        _isSubmitting ||
        _photos.length >= ReportRules.maxPhotos) {
      return;
    }
    setState(() {
      _isPickingPhoto = true;
      _errorMessage = null;
    });
    ReportPhotoEntry? added;
    try {
      if (widget.isFound) {
        final shot = await _imagePicker.captureWithCamera();
        if (shot != null) {
          added = ReportPhotoEntry(
            shot.bytes,
            takenAt: shot.takenAt,
            latitude: shot.latitude,
            longitude: shot.longitude,
          );
        }
      } else {
        final bytes = await _imagePicker.pickFromGallery();
        if (bytes != null) added = ReportPhotoEntry(bytes);
      }
      if (!mounted) return;
      if (added != null) setState(() => _photos.add(added!));
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal mengambil foto: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '$error'.replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
    if (!mounted || added == null) return;
    if (_isSensitiveCategory) await _warnSensitive(added);
  }

  /// FR-R07: peringatan wajib untuk kategori sensitif setelah foto ditambah.
  Future<void> _warnSensitive(ReportPhotoEntry photo) async {
    final shouldBlur = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.privacy_tip_outlined, color: _green, size: 36),
        title: const Text('Foto berisi data pribadi?'),
        content: const Text(
          'Kategori ini sering memuat nama, nomor kartu, atau data pribadi. '
          'Samarkan bagian tersebut sebelum laporan dipublikasikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Lanjut tanpa blur'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Samarkan sekarang'),
          ),
        ],
      ),
    );
    if (!mounted || shouldBlur != true) return;
    await _blurPhoto(_photos.indexOf(photo));
  }

  Future<void> _blurPhoto(int index) async {
    if (index < 0 || index >= _photos.length) return;
    final entry = _photos[index];
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => BlurEditorScreen(imageBytes: entry.bytes),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      entry.bytes = result; // hanya hasil blur yang disimpan
      entry.blurred = true;
    });
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  // ------------------------------------------------------------------ Submit

  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _hasAttemptedSubmit = true;
      _errorMessage = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final now = DateTime.now();
    final timeError = ReportRules.validateEventTime(_eventDateTime, now);
    if (timeError != null) {
      setState(() => _errorMessage = timeError);
      return;
    }
    if (widget.isFound && _keeping == null) {
      setState(() => _errorMessage = 'Pilih keberadaan barang saat ini.');
      return;
    }
    if (widget.isFound && _photos.isEmpty) {
      setState(
        () => _errorMessage =
            'Laporan barang ditemukan wajib menyertakan foto dari kamera.',
      );
      return;
    }

    // FR-R11: validasi foto kamera yang baru diambil pada sesi ini.
    if (widget.isFound) {
      final reportLat = _latitude;
      final reportLng = _longitude;
      final rejected = <ReportPhotoEntry>[];
      String? firstError;
      for (final photo in _photos.where((p) => p.takenAt != null)) {
        final error = ReportRules.validateFoundPhoto(
          takenAt: photo.takenAt,
          now: now,
          photoLat: photo.latitude,
          photoLng: photo.longitude,
          reportLat: reportLat,
          reportLng: reportLng,
        );
        if (error != null) {
          rejected.add(photo);
          firstError ??= error;
        }
      }
      if (rejected.isNotEmpty) {
        setState(() {
          _photos.removeWhere(rejected.contains);
          _errorMessage = firstError;
        });
        return;
      }
    }

    // FR-R07: konfirmasi bila kategori sensitif tetapi foto belum diblur.
    if (_isSensitiveCategory && _photos.any((p) => !p.blurred)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Foto belum disamarkan'),
          content: const Text(
            'Ada foto yang belum diblur pada kategori yang rawan data '
            'pribadi. Tetap publikasikan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Periksa lagi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tetap publikasikan'),
            ),
          ],
        ),
      );
      if (!mounted || proceed != true) return;
    }

    setState(() => _isSubmitting = true);

    late final Item item;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      item = _buildItem();
    } catch (error) {
      if (!mounted) return;
      // Isian form tidak dihapus bila gagal kirim (NFR-06).
      setState(() => _errorMessage = 'Laporan gagal dikirim: $error');
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: _green, size: 42),
        title: Text(
          _isEdit ? 'Laporan berhasil diperbarui' : 'Laporan berhasil dikirim',
        ),
        content: Text(
          _isEdit
              ? 'Perubahan laporan sudah disimpan.'
              : 'Laporan barang sudah ditambahkan ke daftar laporan.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_isEdit ? 'Kembali' : 'Kembali ke daftar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop<Item>(context, item);
  }

  Item _buildItem() {
    final name = _capitalize(_nameController.text);
    final location = _capitalize(_locationController.text);
    final description = _capitalize(_descriptionController.text);
    final subtitle =
        '${widget.isFound ? 'Ditemukan' : 'Hilang'} di sekitar $location';

    // Metadata foto kamera pertama pada sesi ini (untuk validasi server).
    ReportPhotoEntry? camera;
    for (final photo in _photos) {
      if (photo.takenAt != null) {
        camera = photo;
        break;
      }
    }
    // Bila titik laporan belum diisi, pakai posisi foto sebagai titik temu.
    final latitude = _latitude ?? camera?.latitude;
    final longitude = _longitude ?? camera?.longitude;
    final photos = _photos.map((p) => p.bytes).toList();

    final existing = widget.editItem;
    if (existing != null) {
      return existing.copyWith(
        nameItem: name,
        subtitle: subtitle,
        description: description,
        location: location,
        category: _category,
        category2: _category2,
        clearCategory2: _category2 == null,
        eventDate: _eventDateTime,
        photos: photos,
        color: _optionalValue(_colorController.text),
        clearColor: _optionalValue(_colorController.text) == null,
        brand: _optionalValue(_brandController.text),
        clearBrand: _optionalValue(_brandController.text) == null,
        secretDetail: _optionalValue(_secretDetailController.text),
        clearSecretDetail: _optionalValue(_secretDetailController.text) == null,
        keeping: _keeping,
        latitude: latitude,
        longitude: longitude,
        photoTakenAt: camera?.takenAt,
        photoLat: camera?.latitude,
        photoLng: camera?.longitude,
      );
    }

    return Item(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nameItem: name,
      subtitle: subtitle,
      description: description,
      location: location,
      isFound: widget.isFound,
      category: _category!,
      category2: _category2,
      eventDate: _eventDateTime,
      photos: photos,
      color: _optionalValue(_colorController.text),
      brand: _optionalValue(_brandController.text),
      secretDetail: _optionalValue(_secretDetailController.text),
      isOwner: true,
      keeping: widget.isFound ? _keeping : null,
      latitude: latitude,
      longitude: longitude,
      photoTakenAt: camera?.takenAt,
      photoLat: camera?.latitude,
      photoLng: camera?.longitude,
    );
  }

  String _capitalize(String value) {
    final text = value.trim();
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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

  // ------------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final locked = _coreLocked;
    return PopScope<Item>(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leadingWidth: 68,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              tooltip: 'Kembali',
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              style: IconButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xFFD4E0E2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          title: Text(
            _isEdit ? 'Ubah Laporan' : 'Buat Laporan',
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          titleSpacing: 12,
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            autovalidateMode: _hasAttemptedSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildReportTypeSelector(),
                if (locked) ...[
                  const SizedBox(height: 12),
                  _infoBanner(
                    'Laporan ini sedang diverifikasi. Kategori, lokasi, dan '
                    'detail pembeda dikunci sampai klaim selesai.',
                  ),
                ],
                const SizedBox(height: 18),
                _fieldLabel('Nama barang', required: true),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('report-name'),
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.reportName(value) ??
                      ReportRules.validateSensitiveTitle(_category, value!),
                  decoration: _inputDecoration('mis. Dompet kulit hitam'),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Kategori utama', required: true),
                const SizedBox(height: 8),
                _buildCategoryChips(locked),
                const SizedBox(height: 8),
                const Text(
                  'Pilih kategori yang paling sesuai dengan barang.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                if (_isSensitiveCategory) ...[
                  const SizedBox(height: 8),
                  _infoBanner(
                    'Kategori ini rawan data pribadi. Jangan tulis nama atau '
                    'nomor kartu pada judul, dan samarkan pada foto.',
                  ),
                ],
                const SizedBox(height: 16),
                _fieldLabel('Kategori kedua (opsional)'),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('report-category2'),
                  onPressed: _isSubmitting || locked
                      ? null
                      : _pickSecondCategory,
                  style: _pickerButtonStyle(),
                  child: Row(
                    children: [
                      Expanded(child: Text(_category2 ?? 'Tidak ada')),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _fieldLabel(
                        widget.isFound ? 'Tanggal ditemukan' : 'Tanggal hilang',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _fieldLabel('Pukul')),
                  ],
                ),
                const SizedBox(height: 8),
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
                    const SizedBox(width: 10),
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
                const SizedBox(height: 6),
                const Text(
                  'Pilih tanggal dan waktu kejadian.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Deskripsi / ciri-ciri', required: true),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('report-description'),
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  minLines: 3,
                  maxLines: 4,
                  maxLength: ReportRules.maxDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.reportDescription,
                  decoration: _inputDecoration(
                    'Warna, merek, dan ciri khusus barang',
                  ),
                ),
                const SizedBox(height: 8),
                _fieldLabel(
                  widget.isFound
                      ? 'Lokasi ditemukan'
                      : 'Perkiraan lokasi hilang',
                  required: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('report-location'),
                  controller: _locationController,
                  enabled: !_isSubmitting && !locked,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  validator: Validators.reportLocation,
                  decoration: _inputDecoration(
                    widget.isFound
                        ? 'Contoh: Kantin Universitas Andalas'
                        : 'Contoh: Perpustakaan Universitas Andalas',
                  ),
                ),
                const SizedBox(height: 8),
                // Sementara: GPS sederhana. Modul 2 akan menggantikannya dengan
                // LocationPicker (GPS + geser pin + pilih gedung, FR-L01).
                Row(
                  children: [
                    OutlinedButton.icon(
                      key: const Key('report-use-gps'),
                      onPressed: _isSubmitting || _isLocating || locked
                          ? null
                          : _useCurrentLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: const Text('Gunakan lokasi saya'),
                    ),
                    const SizedBox(width: 10),
                    if (_latitude != null && _longitude != null)
                      Expanded(
                        child: Text(
                          '${_latitude!.toStringAsFixed(5)}, '
                          '${_longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(color: _muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                if (!widget.isFound) ...[
                  const SizedBox(height: 12),
                  _buildMapPreview(),
                ],
                if (widget.isFound) ...[
                  const SizedBox(height: 16),
                  _fieldLabel('Keberadaan barang saat ini', required: true),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final keeping in ItemKeeping.values)
                        ChoiceChip(
                          key: Key('report-keeping-${keeping.name}'),
                          label: Text(keeping.label),
                          selected: _keeping == keeping,
                          showCheckmark: false,
                          onSelected: _isSubmitting
                              ? null
                              : (selected) => setState(
                                  () => _keeping = selected ? keeping : null,
                                ),
                          labelStyle: TextStyle(
                            color: _keeping == keeping ? Colors.white : _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: _green,
                          side: BorderSide(
                            color: _keeping == keeping ? _green : _outline,
                          ),
                          shape: const StadiumBorder(),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Warna (opsional)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('report-color'),
                            controller: _colorController,
                            enabled: !_isSubmitting,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _inputDecoration('mis. Hitam'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Merek (opsional)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('report-brand'),
                            controller: _brandController,
                            enabled: !_isSubmitting,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration('mis. Eiger'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _fieldLabel('Foto barang', required: widget.isFound),
                const SizedBox(height: 8),
                ReportPhotoSection(
                  photos: _photos,
                  isFound: widget.isFound,
                  isBusy: _isPickingPhoto || _isSubmitting,
                  onAdd: _addPhoto,
                  onRemove: _removePhoto,
                  onBlur: _blurPhoto,
                ),
                const SizedBox(height: 16),
                _fieldLabel('Detail pembeda rahasia'),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('report-secret-detail'),
                  controller: _secretDetailController,
                  enabled: !_isSubmitting && !locked,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    'mis. Isi dompet, stiker, atau goresan',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tidak ditampilkan ke publik. Hanya dipakai untuk '
                  'memverifikasi klaim barang.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E9E8))),
            ),
            child: SizedBox(
              height: 56,
              child: FilledButton(
                key: const Key('submit-report'),
                onPressed: _isSubmitting ? null : _submitReport,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
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
                    : Text(
                        _isEdit ? 'Simpan Perubahan' : 'Publikasikan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool locked) {
    return FormField<String>(
      key: const Key('report-category'),
      initialValue: _category,
      validator: Validators.reportCategory,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ReportCategories.all)
                ChoiceChip(
                  label: Text(category.name),
                  selected: field.value == category.name,
                  showCheckmark: false,
                  onSelected: _isSubmitting || locked
                      ? null
                      : (selected) {
                          final value = selected ? category.name : null;
                          field.didChange(value);
                          setState(() {
                            _category = value;
                            if (_category2 == value) _category2 = null;
                          });
                        },
                  labelStyle: TextStyle(
                    color: field.value == category.name ? Colors.white : _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: _green,
                  side: BorderSide(
                    color: field.value == category.name ? _green : _outline,
                  ),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
            ],
          ),
          if (field.hasError) ...[
            const SizedBox(height: 6),
            Text(
              field.errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF8A4B08)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF5C3A06)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    final selectedColor = widget.isFound ? _green : const Color(0xFFF8A10A);
    final selectedForeground = widget.isFound ? Colors.white : _ink;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEEF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _reportTypeSegment(
            label: 'Hilang',
            selected: !widget.isFound,
            selectedColor: selectedColor,
            selectedForeground: selectedForeground,
          ),
          _reportTypeSegment(
            label: 'Ditemukan',
            selected: widget.isFound,
            selectedColor: selectedColor,
            selectedForeground: selectedForeground,
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            key: const Key('report-map-preview'),
            height: 132,
            width: double.infinity,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _IllustratedMapPainter()),
                ),
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color: _green,
                    size: 38,
                    shadows: [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          _locationController.text.trim().isEmpty
                              ? 'Perkiraan lokasi di kampus'
                              : _locationController.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Peta ilustrasi. Isi nama gedung atau area pada kolom lokasi.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    );
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _reportTypeSegment({
    required String label,
    required bool selected,
    required Color selectedColor,
    required Color selectedForeground,
  }) {
    return Expanded(
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? selectedForeground : _muted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFB3261E)),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: _muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _green, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  ButtonStyle _pickerButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _ink,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      side: const BorderSide(color: _outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _IllustratedMapPainter extends CustomPainter {
  const _IllustratedMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 150);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 360, 150),
      Paint()..color = const Color(0xFFEEF3EE),
    );
    final parkPaint = Paint()..color = const Color(0xFFD8E9D7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 14, 88, 42),
        const Radius.circular(12),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(254, 18, 82, 48),
        const Radius.circular(12),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 98, 70, 38),
        const Radius.circular(12),
      ),
      parkPaint,
    );
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roads = [
      Path()
        ..moveTo(-10, 78)
        ..cubicTo(70, 56, 120, 88, 188, 64)
        ..cubicTo(250, 42, 290, 76, 370, 48),
      Path()
        ..moveTo(148, -10)
        ..cubicTo(132, 38, 180, 90, 158, 160),
      Path()
        ..moveTo(248, 160)
        ..cubicTo(230, 120, 260, 100, 242, 68)
        ..cubicTo(224, 36, 242, 18, 232, -10),
    ];
    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
    }
    final linePaint = Paint()
      ..color = const Color(0xFFDCE4DF)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final road in roads) {
      canvas.drawPath(road, linePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IllustratedMapPainter oldDelegate) => false;
}
