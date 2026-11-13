import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'package:find_it/data/app_data.dart';
import 'package:find_it/data/item_repository.dart';
import 'package:find_it/data/report_draft_store.dart';
import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/models/report_category.dart';
import 'package:find_it/models/report_photo_entry.dart';
import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/screens/blur_editor_screen.dart';
import 'package:find_it/screens/campus_location_picker_screen.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/services/device_image_picker.dart';
import 'package:find_it/services/location_service.dart';
import 'package:find_it/utils/campus_locations.dart';
import 'package:find_it/utils/validators.dart';
import 'package:find_it/widgets/report_photo_section.dart';

/// Form buat/ubah laporan (FR-R01, FR-R02, FR-R04).
///
/// Form menyimpan sendiri ke repository lalu `pop` dengan `Item` yang
/// tersimpan; pemanggil cukup memuat ulang daftar dan menampilkan snackbar.
/// Jika [editItem] diisi, layar berjalan dalam mode edit.
class AddReportScreen extends StatefulWidget {
  final bool isFound;
  final Item? editItem;
  final ItemRepository? repository;

  const AddReportScreen({
    super.key,
    required this.isFound,
    this.editItem,
    this.repository,
  });

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
  final _whatsappController = TextEditingController();
  final _keepingNoteController = TextEditingController();
  final _imagePicker = const DeviceImagePicker();
  final _locationService = const LocationService();

  late final ItemRepository _repository;
  final List<ReportPhotoEntry> _photos = [];

  String? _category;
  String? _category2;
  ItemKeeping? _keeping;
  double? _latitude;
  double? _longitude;
  bool _isLocationApproximate = false;
  bool _useTimeRange = false;
  bool _cameraUnavailable = false;
  bool _hasAttemptedSubmit = false;
  bool _isSubmitting = false;
  bool _isPickingPhoto = false;
  bool _isLocating = false;
  bool _isDirty = false;
  bool _allowPop = false;
  bool _canRetry = false;
  String? _errorMessage;
  ReportDraft? _pendingDraft;
  DateTime _eventStart = _trimSeconds(DateTime.now());
  DateTime _eventEnd = _trimSeconds(DateTime.now());

  bool get _isEdit => widget.editItem != null;

  /// FR-R09: field inti dikunci saat ada klaim yang sedang diverifikasi.
  bool get _coreLocked =>
      _isEdit && !ReportRules.canEditCoreFields(widget.editItem!);

  bool get _isSensitiveCategory => ReportCategories.isSensitiveName(_category);

  bool get _allowGalleryFallback =>
      widget.isFound &&
      (_cameraUnavailable || _keeping == ItemKeeping.atSecurityPost);

  static DateTime _trimSeconds(DateTime value) =>
      DateTime(value.year, value.month, value.day, value.hour, value.minute);

  // ------------------------------------------------------------ Lifecycle

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppData.repository;
    final item = widget.editItem;
    if (item != null) {
      _fillFromItem(item);
    } else {
      _pendingDraft = AppData.reportDrafts.read(isFound: widget.isFound);
      _useTimeRange = !widget.isFound;
      if (_useTimeRange) {
        _eventStart = _eventEnd.subtract(const Duration(hours: 2));
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
  }

  List<TextEditingController> get _controllers => [
    _nameController,
    _descriptionController,
    _colorController,
    _brandController,
    _secretDetailController,
    _locationController,
    _whatsappController,
    _keepingNoteController,
  ];

  void _markDirty() => _isDirty = true;

  void _fillFromItem(Item item) {
    _nameController.text = item.nameItem;
    _descriptionController.text = item.description;
    _colorController.text = item.color ?? '';
    _brandController.text = item.brand ?? '';
    _secretDetailController.text = item.secretDetail ?? '';
    _locationController.text = item.location;
    _whatsappController.text = item.whatsapp ?? '';
    _keepingNoteController.text = item.keepingNote ?? '';
    _category = ReportCategories.byName(item.category) != null
        ? item.category
        : ReportCategories.fromLegacy(item.category);
    _category2 = item.category2;
    _keeping = item.keeping;
    _latitude = item.latitude;
    _longitude = item.longitude;
    _isLocationApproximate = item.isLocationApproximate;
    final start = item.eventDate;
    if (start != null) _eventStart = _trimSeconds(start);
    final end = item.eventEndDate;
    _useTimeRange = end != null;
    _eventEnd = end != null ? _trimSeconds(end) : _eventStart;
    for (final bytes in item.photos) {
      // Foto lama sudah lolos validasi saat diterbitkan; tidak dicek ulang.
      _photos.add(ReportPhotoEntry(bytes, blurred: true, isExisting: true));
    }
  }

  void _applyDraft(ReportDraft draft) {
    setState(() {
      _nameController.text = draft.name;
      _descriptionController.text = draft.description;
      _locationController.text = draft.location;
      _colorController.text = draft.color;
      _brandController.text = draft.brand;
      _secretDetailController.text = draft.secretDetail;
      _whatsappController.text = draft.whatsapp;
      _keepingNoteController.text = draft.keepingNote;
      _category = draft.category;
      _category2 = draft.category2;
      _keeping = draft.keeping;
      _latitude = draft.latitude;
      _longitude = draft.longitude;
      _isLocationApproximate = draft.isLocationApproximate;
      _eventStart = draft.eventStart;
      _useTimeRange = draft.eventEnd != null;
      _eventEnd = draft.eventEnd ?? draft.eventStart;
      _photos
        ..clear()
        ..addAll(
          draft.galleryPhotos.map(
            (bytes) => ReportPhotoEntry(
              bytes,
              blurred: true,
              isUnverified: widget.isFound,
            ),
          ),
        );
      _pendingDraft = null;
    });
    if (widget.isFound) {
      _showSnack(
        'Draf dipulihkan. Ambil ulang foto kamera karena foto Found harus '
        'diambil maksimal 30 menit sebelum dikirim.',
      );
    }
  }

  void _discardDraft() {
    AppData.reportDrafts.clear(isFound: widget.isFound);
    setState(() => _pendingDraft = null);
  }

  ReportDraft _currentDraft() => ReportDraft(
    isFound: widget.isFound,
    name: _nameController.text,
    description: _descriptionController.text,
    location: _locationController.text,
    category: _category,
    category2: _category2,
    color: _colorController.text,
    brand: _brandController.text,
    secretDetail: _secretDetailController.text,
    whatsapp: _whatsappController.text,
    keepingNote: _keepingNoteController.text,
    keeping: _keeping,
    latitude: _latitude,
    longitude: _longitude,
    isLocationApproximate: _isLocationApproximate,
    eventStart: _eventStart,
    eventEnd: _useTimeRange ? _eventEnd : null,
    galleryPhotos: [
      for (final photo in _photos)
        if (!photo.isFromCamera) photo.bytes,
    ],
    savedAt: DateTime.now(),
  );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // --------------------------------------------------------- Keluar form

  Future<void> _handlePop() async {
    if (_isSubmitting) return;
    if (!_isDirty) {
      _leave();
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isEdit ? 'Buang perubahan?' : 'Simpan sebagai draf?'),
        content: Text(
          _isEdit
              ? 'Perubahan yang belum disimpan akan hilang.'
              : 'Isian laporan belum dikirim. Simpan sebagai draf agar bisa '
                    'dilanjutkan nanti?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: Text(_isEdit ? 'Buang' : 'Buang isian'),
          ),
          if (!_isEdit)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'draft'),
              child: const Text('Simpan draf'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'stay'),
            child: const Text('Lanjut mengisi'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'discard':
        if (!_isEdit) AppData.reportDrafts.clear(isFound: widget.isFound);
        _leave();
      case 'draft':
        AppData.reportDrafts.save(_currentDraft());
        _leave();
      default:
        break;
    }
  }

  void _leave([Item? result]) {
    setState(() => _allowPop = true);
    Navigator.pop<Item>(context, result);
  }

  // ------------------------------------------------------------- Waktu

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final now = DateTime.now();
    final safeInitial = initial.isAfter(now) ? now : initial;
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final date = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      // Jangan sampai firstDate > initialDate (laporan lama saat diedit).
      firstDate: safeInitial.isBefore(oneYearAgo) ? safeInitial : oneYearAgo,
      lastDate: now,
    );
    if (!mounted || date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _selectStart() async {
    final picked = await _pickDateTime(_eventStart);
    if (picked == null) return;
    setState(() {
      _eventStart = picked;
      if (_useTimeRange && _eventEnd.isBefore(picked)) _eventEnd = picked;
      _isDirty = true;
    });
  }

  Future<void> _selectEnd() async {
    final picked = await _pickDateTime(_eventEnd);
    if (picked == null) return;
    setState(() {
      _eventEnd = picked;
      _isDirty = true;
    });
  }

  // ---------------------------------------------------------- Kategori

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
    setState(() {
      _category2 = choice.isEmpty ? null : choice;
      _isDirty = true;
    });
  }

  // ------------------------------------------------------------ Lokasi

  Future<void> _useCurrentLocation() async {
    if (_isLocating || _isSubmitting) return;
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });
    final result = await _locationService.determinePosition();
    if (!mounted) return;
    setState(() => _isLocating = false);
    final position = result.position;
    if (!result.isSuccess || position == null) {
      // NFR-03/NFR-06: izin ditolak / GPS mati tidak menghalangi isian manual.
      _showSnack('${result.message} Isi nama gedung/area secara manual.');
      return;
    }
    final landmark = CampusLocations.getNearestLandmark(position);
    setState(() {
      _locationController.text = landmark;
      _latitude = position.latitude;
      _longitude = position.longitude;
      _isLocationApproximate = false;
      _isDirty = true;
    });
    _showSnack('Lokasi terdeteksi: $landmark');
  }

  Future<void> _openLocationPicker() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    final result = await Navigator.pushNamed<CampusLocationResult>(
      context,
      AppRoutes.locationPicker,
      arguments: <String, dynamic>{
        'initialLocationName': _locationController.text.trim(),
        'initialCenter': _latitude != null && _longitude != null
            ? LatLng(_latitude!, _longitude!)
            : null,
      },
    );
    if (!mounted || result == null) return;
    setState(() {
      _locationController.text = result.locationName;
      _latitude = result.latitude;
      _longitude = result.longitude;
      _isDirty = true;
    });
  }

  void _selectLandmark(String landmark) {
    final coords = CampusLocations.landmarks[landmark];
    setState(() {
      _locationController.text = landmark;
      if (coords != null) {
        _latitude = coords.latitude;
        _longitude = coords.longitude;
      }
      _isDirty = true;
    });
  }

  void _clearPin() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _isDirty = true;
    });
  }

  // -------------------------------------------------------------- Foto

  Future<void> _addPhoto({bool fromGallery = false}) async {
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
      if (widget.isFound && !fromGallery) {
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
        if (bytes != null) {
          added = ReportPhotoEntry(bytes, isUnverified: widget.isFound);
        }
      }
      if (!mounted) return;
      if (added != null) {
        setState(() {
          _photos.add(added!);
          _isDirty = true;
        });
      }
    } on PhotoAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        if (error.cameraUnavailable) _cameraUnavailable = true;
      });
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
          'Kategori ini sering memuat nama, NIM, nomor kartu, atau foto '
          'wajah. Samarkan bagian tersebut sebelum laporan dipublikasikan.',
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
      _isDirty = true;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _isDirty = true;
    });
  }

  // ------------------------------------------------------------ Submit

  /// Mengembalikan pesan error validasi di luar `Form`, atau null.
  String? _validateExtra(DateTime now) {
    final timeError = ReportRules.validateEventTime(
      _eventStart,
      now,
      end: _useTimeRange ? _eventEnd : null,
    );
    if (timeError != null) return timeError;
    if (widget.isFound) {
      if (_keeping == null) return 'Pilih keberadaan barang saat ini.';
      if (_keeping == ItemKeeping.atSecurityPost &&
          _keepingNoteController.text.trim().isEmpty) {
        return 'Sebutkan tempat penitipan barang (mis. Pos satpam Gedung F).';
      }
      if (_photos.isEmpty) {
        return 'Laporan barang ditemukan wajib menyertakan minimal 1 foto.';
      }
    }
    return null;
  }

  /// FR-R11: validasi foto kamera baru. Foto yang gagal dikeluarkan.
  bool _validateCameraPhotos(DateTime now) {
    if (!widget.isFound) return true;
    final reportLat = _latitude;
    final reportLng = _longitude;
    final rejected = <ReportPhotoEntry>[];
    String? firstError;
    for (final photo in _photos) {
      if (photo.isExisting || !photo.isFromCamera) continue;
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
    if (rejected.isEmpty) return true;
    setState(() {
      _photos.removeWhere(rejected.contains);
      _errorMessage = firstError;
    });
    return false;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Periksa lagi',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _hasAttemptedSubmit = true;
      _errorMessage = null;
      _canRetry = false;
    });
    final formValid = _formKey.currentState?.validate() ?? false;
    final now = DateTime.now();
    final extraError = _validateExtra(now);
    if (!formValid || extraError != null) {
      setState(
        () => _errorMessage =
            extraError ?? 'Periksa kembali isian yang ditandai merah.',
      );
      return;
    }
    if (!_validateCameraPhotos(now)) return;

    // FR-R07: konfirmasi bila kategori sensitif tetapi foto belum diblur.
    if (_isSensitiveCategory && _photos.any((p) => !p.blurred)) {
      final proceed = await _confirm(
        title: 'Foto belum disamarkan',
        message:
            'Ada foto yang belum diblur pada kategori yang rawan data '
            'pribadi. Tetap publikasikan?',
        confirmLabel: 'Tetap publikasikan',
      );
      if (!mounted || !proceed) return;
    }

    final userId = AppSession.userId ?? 'user:local';
    if (!_isEdit) {
      final limitError = ReportRules.checkRateLimit(
        _repository.items,
        userId,
        now,
      );
      if (limitError != null) {
        setState(() => _errorMessage = limitError);
        return;
      }
      final duplicate = ReportRules.findPossibleDuplicate(
        _repository.items,
        userId: userId,
        isFound: widget.isFound,
        category: _category!,
        name: _nameController.text,
        now: now,
      );
      if (duplicate != null) {
        final proceed = await _confirm(
          title: 'Mungkin laporan ganda',
          message:
              'Anda sudah melaporkan "${duplicate.nameItem}" pada kategori '
              'yang sama dalam 24 jam terakhir. Lebih baik perbarui laporan '
              'tersebut. Tetap buat laporan baru?',
          confirmLabel: 'Tetap buat baru',
          cancelLabel: 'Batal',
        );
        if (!mounted || !proceed) return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final draft = _buildItem(userId);
      final Item stored = _isEdit
          ? await _repository.saveEdit(draft)
          : await _repository.submit(draft);
      // Modul 3: laporan baru/berubah langsung ikut dicocokkan ulang.
      AppData.matchingService.refreshMatches();
      if (!_isEdit) AppData.reportDrafts.clear(isFound: widget.isFound);
      if (!mounted) return;
      _leave(stored);
    } on ReportSubmitException catch (error) {
      // NFR-06: isian tidak hilang; disimpan sebagai draf + bisa coba lagi.
      if (!_isEdit) {
        AppData.reportDrafts.save(_currentDraft());
        AppData.reportNotifications.notifySubmitFailed(
          _nameController.text.trim(),
        );
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _canRetry = true;
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Laporan gagal dikirim: $error';
        _canRetry = true;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Item _buildItem(String userId) {
    final name = _capitalize(_nameController.text);
    final location = _capitalize(_locationController.text);
    final description = _capitalize(_descriptionController.text);
    final subtitle =
        '${widget.isFound ? 'Ditemukan' : 'Hilang'} di sekitar $location';

    // Metadata foto kamera pertama (untuk validasi ulang di server).
    ReportPhotoEntry? camera;
    for (final photo in _photos) {
      if (photo.isFromCamera) {
        camera = photo;
        break;
      }
    }

    // Prioritas titik: pin pilihan > posisi foto kamera > titik landmark
    // (perkiraan, agar tetap tampil di peta Modul 2).
    var latitude = _latitude ?? camera?.latitude;
    var longitude = _longitude ?? camera?.longitude;
    var approximate = _isLocationApproximate;
    final existingItem = widget.editItem;
    if (_coreLocked && existingItem != null) {
      // Lokasi dikunci selama verifikasi klaim: pakai nilai tersimpan.
      latitude = existingItem.latitude;
      longitude = existingItem.longitude;
      approximate = existingItem.isLocationApproximate;
    } else if (latitude == null || longitude == null) {
      final fallback = CampusLocations.getCoordinates(location);
      latitude = fallback.latitude;
      longitude = fallback.longitude;
      approximate = true;
    }
    final photos = _photos.map((p) => p.bytes).toList();
    final secret = _optionalValue(_secretDetailController.text);
    final verificationDetails = secret == null ? <String>[] : [secret];
    final hasUnverifiedPhoto =
        widget.isFound && _photos.any((p) => p.isUnverified);
    final keepingNote = _keeping == ItemKeeping.atSecurityPost
        ? _optionalValue(_keepingNoteController.text)
        : null;

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
        eventDate: _eventStart,
        eventEndDate: _useTimeRange ? _eventEnd : null,
        clearEventEndDate: !_useTimeRange,
        photos: photos,
        color: _optionalValue(_colorController.text),
        clearColor: _optionalValue(_colorController.text) == null,
        brand: _optionalValue(_brandController.text),
        clearBrand: _optionalValue(_brandController.text) == null,
        verificationDetails: verificationDetails,
        whatsapp: _optionalValue(_whatsappController.text),
        clearWhatsapp: _optionalValue(_whatsappController.text) == null,
        keeping: _keeping,
        keepingNote: keepingNote,
        clearKeepingNote: keepingNote == null,
        latitude: latitude,
        longitude: longitude,
        isLocationApproximate: approximate,
        photoTakenAt: camera?.takenAt,
        photoLat: camera?.latitude,
        photoLng: camera?.longitude,
        hasUnverifiedPhoto: hasUnverifiedPhoto,
      );
    }

    return Item(
      id: 'rpt-${DateTime.now().microsecondsSinceEpoch}',
      nameItem: name,
      subtitle: subtitle,
      description: description,
      location: location,
      isFound: widget.isFound,
      category: _category!,
      category2: _category2,
      eventDate: _eventStart,
      eventEndDate: _useTimeRange ? _eventEnd : null,
      photos: photos,
      color: _optionalValue(_colorController.text),
      brand: _optionalValue(_brandController.text),
      reporter: AppSession.emailVerified
          ? 'Sivitas Unand (email terverifikasi)'
          : 'Pengguna Find!t',
      ownerId: userId,
      isOwner: true,
      verificationDetails: verificationDetails,
      whatsapp: _optionalValue(_whatsappController.text),
      latitude: latitude,
      longitude: longitude,
      isLocationApproximate: approximate,
      keeping: widget.isFound ? _keeping : null,
      keepingNote: keepingNote,
      photoTakenAt: camera?.takenAt,
      photoLat: camera?.latitude,
      photoLng: camera?.longitude,
      hasUnverifiedPhoto: hasUnverifiedPhoto,
    );
  }

  String _capitalize(String value) {
    final text = value.trim();
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // ------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final locked = _coreLocked;
    return PopScope<Item>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handlePop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          foregroundColor: _ink,
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _isSubmitting ? null : _handlePop,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            _isEdit
                ? 'Ubah Laporan'
                : widget.isFound
                ? 'Lapor Barang Ditemukan'
                : 'Lapor Barang Hilang',
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
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
                if (_pendingDraft case final draft?) ...[
                  const SizedBox(height: 12),
                  _buildDraftBanner(draft),
                ],
                if (locked) ...[
                  const SizedBox(height: 12),
                  _infoBanner(
                    'Laporan ini sedang diverifikasi. Kategori, lokasi, dan '
                    'detail pembeda dikunci sampai klaim selesai.',
                  ),
                ],
                const SizedBox(height: 18),
                ..._buildIdentitySection(locked),
                const SizedBox(height: 16),
                ..._buildTimeSection(),
                const SizedBox(height: 16),
                ..._buildLocationSection(locked),
                if (widget.isFound) ...[
                  const SizedBox(height: 16),
                  ..._buildKeepingSection(),
                ],
                const SizedBox(height: 16),
                ..._buildAttributeSection(),
                const SizedBox(height: 16),
                _fieldLabel('Foto barang', required: widget.isFound),
                const SizedBox(height: 8),
                ReportPhotoSection(
                  photos: _photos,
                  isFound: widget.isFound,
                  isBusy: _isPickingPhoto || _isSubmitting,
                  onAdd: _addPhoto,
                  onAddFromGallery: _allowGalleryFallback
                      ? () => _addPhoto(fromGallery: true)
                      : null,
                  onRemove: _removePhoto,
                  onBlur: _blurPhoto,
                ),
                const SizedBox(height: 16),
                ..._buildPrivateSection(locked),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorBox(),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildSubmitBar(),
      ),
    );
  }

  List<Widget> _buildIdentitySection(bool locked) {
    return [
      _fieldLabel('Nama barang', required: true),
      const SizedBox(height: 8),
      TextFormField(
        key: const Key('report-name'),
        controller: _nameController,
        enabled: !_isSubmitting,
        maxLength: ReportRules.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        validator: (value) =>
            Validators.reportName(value) ??
            ReportRules.validateSensitiveTitle(_category, value!),
        decoration: _inputDecoration(
          widget.isFound ? 'mis. Dompet kulit coklat' : 'mis. Tumbler hijau',
        ),
      ),
      const SizedBox(height: 8),
      _fieldLabel('Kategori utama', required: true),
      const SizedBox(height: 8),
      _buildCategoryChips(locked),
      if (_isSensitiveCategory) ...[
        const SizedBox(height: 8),
        _infoBanner(
          'Kategori ini rawan data pribadi. Jangan tulis nama atau nomor '
          'kartu pada judul, dan samarkan pada foto.',
        ),
      ],
      const SizedBox(height: 16),
      _fieldLabel('Kategori kedua (opsional)'),
      const SizedBox(height: 8),
      OutlinedButton(
        key: const Key('report-category2'),
        onPressed: _isSubmitting || locked ? null : _pickSecondCategory,
        style: _pickerButtonStyle(),
        child: Row(
          children: [
            Expanded(child: Text(_category2 ?? 'Tidak ada')),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _fieldLabel('Deskripsi / ciri-ciri', required: true),
      const SizedBox(height: 8),
      TextFormField(
        key: const Key('report-description'),
        controller: _descriptionController,
        enabled: !_isSubmitting,
        minLines: 3,
        maxLines: 5,
        maxLength: ReportRules.maxDescriptionLength,
        textCapitalization: TextCapitalization.sentences,
        validator: Validators.reportDescription,
        decoration: _inputDecoration(
          'Ciri umum yang boleh dilihat publik. Simpan ciri khusus di '
          '"Detail pembeda rahasia".',
        ),
      ),
    ];
  }

  List<Widget> _buildTimeSection() {
    return [
      _fieldLabel(
        widget.isFound
            ? 'Waktu ditemukan'
            : _useTimeRange
            ? 'Perkiraan waktu hilang (dari)'
            : 'Waktu hilang',
        required: true,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('report-time-start'),
        onPressed: _isSubmitting ? null : _selectStart,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(Item.formatDateTime(_eventStart)),
        style: _pickerButtonStyle(),
      ),
      if (!widget.isFound) ...[
        SwitchListTile(
          key: const Key('report-time-range'),
          contentPadding: EdgeInsets.zero,
          value: _useTimeRange,
          onChanged: _isSubmitting
              ? null
              : (value) => setState(() {
                  _useTimeRange = value;
                  if (value && _eventEnd.isBefore(_eventStart)) {
                    _eventEnd = _eventStart;
                  }
                  _isDirty = true;
                }),
          title: const Text(
            'Saya tidak tahu waktu pastinya',
            style: TextStyle(fontSize: 13),
          ),
          subtitle: const Text(
            'Isi rentang waktu, mis. 10.00–13.00',
            style: TextStyle(fontSize: 11),
          ),
        ),
        if (_useTimeRange) ...[
          _fieldLabel('Sampai'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('report-time-end'),
            onPressed: _isSubmitting ? null : _selectEnd,
            icon: const Icon(Icons.schedule),
            label: Text(Item.formatDateTime(_eventEnd)),
            style: _pickerButtonStyle(),
          ),
        ],
      ],
    ];
  }

  List<Widget> _buildLocationSection(bool locked) {
    final hasPin = _latitude != null && _longitude != null;
    return [
      _fieldLabel(
        widget.isFound ? 'Lokasi ditemukan' : 'Perkiraan lokasi hilang',
        required: true,
      ),
      if (!widget.isFound) ...[
        const SizedBox(height: 4),
        const Text(
          'Pilih tempat barang kemungkinan hilang, bukan lokasi Anda saat ini.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
      const SizedBox(height: 8),
      TextFormField(
        key: const Key('report-location'),
        controller: _locationController,
        enabled: !_isSubmitting && !locked,
        textCapitalization: TextCapitalization.sentences,
        validator: Validators.reportLocation,
        decoration: _inputDecoration('Nama gedung / area kampus').copyWith(
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('report-use-gps'),
                tooltip: 'Gunakan lokasi saya (GPS)',
                onPressed: _isSubmitting || _isLocating || locked
                    ? null
                    : _useCurrentLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, color: _green),
              ),
              IconButton(
                key: const Key('report-pick-map'),
                tooltip: 'Pilih di peta kampus',
                onPressed: _isSubmitting || locked ? null : _openLocationPicker,
                icon: const Icon(Icons.map_outlined, color: _green),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final landmark in CampusLocations.landmarkNames.take(8))
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(landmark, style: const TextStyle(fontSize: 11)),
                  onPressed: _isSubmitting || locked
                      ? null
                      : () => _selectLandmark(landmark),
                ),
              ),
          ],
        ),
      ),
      if (hasPin) ...[
        const SizedBox(height: 6),
        Container(
          key: const Key('report-pin-info'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: _green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Titik di peta: ${_latitude!.toStringAsFixed(5)}, '
                  '${_longitude!.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11, color: _green),
                ),
              ),
              if (!locked)
                InkWell(
                  onTap: _isSubmitting ? null : _clearPin,
                  child: const Text(
                    'Hapus titik',
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
      if (!widget.isFound)
        CheckboxListTile(
          key: const Key('report-location-approx'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _isLocationApproximate,
          onChanged: _isSubmitting || locked
              ? null
              : (value) => setState(() {
                  _isLocationApproximate = value ?? false;
                  _isDirty = true;
                }),
          title: const Text(
            'Saya tidak yakin lokasi pastinya',
            style: TextStyle(fontSize: 13),
          ),
          subtitle: const Text(
            'Laporan akan ditandai "lokasi perkiraan" agar penemu tidak '
            'terpaku pada satu titik.',
            style: TextStyle(fontSize: 11),
          ),
        ),
    ];
  }

  List<Widget> _buildKeepingSection() {
    return [
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
                  : (selected) => setState(() {
                      _keeping = selected ? keeping : null;
                      _isDirty = true;
                    }),
              labelStyle: TextStyle(
                color: _keeping == keeping ? Colors.white : _ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              selectedColor: _green,
              side: BorderSide(color: _keeping == keeping ? _green : _outline),
              shape: const StadiumBorder(),
            ),
        ],
      ),
      if (_keeping == ItemKeeping.atSecurityPost) ...[
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('report-keeping-note'),
          controller: _keepingNoteController,
          enabled: !_isSubmitting,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            'Tempat penitipan, mis. Pos satpam Gedung F',
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildAttributeSection() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    ];
  }

  List<Widget> _buildPrivateSection(bool locked) {
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E9E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: _green),
                SizedBox(width: 6),
                Text(
                  'Data privat',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tidak tampil di laporan publik.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Detail pembeda rahasia'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('report-secret-detail'),
              controller: _secretDetailController,
              enabled: !_isSubmitting && !locked,
              minLines: 2,
              maxLines: 3,
              maxLength: ReportRules.maxSecretDetailLength,
              validator: Validators.reportSecretDetail,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                widget.isFound
                    ? 'Ciri yang hanya diketahui pemilik asli, mis. isi '
                          'dompet, wallpaper HP'
                    : 'Ciri yang bisa Anda sebutkan saat klaim, mis. stiker '
                          'di bagian bawah',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hanya ditampilkan ke pemilik laporan saat memverifikasi klaim.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Nomor WhatsApp (opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('report-whatsapp'),
              controller: _whatsappController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.phone,
              validator: Validators.reportWhatsapp,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
              ],
              decoration: _inputDecoration('mis. 081234567890'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hanya dibagikan setelah klaim disetujui dan kedua pihak setuju '
              'bertukar kontak.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildDraftBanner(ReportDraft draft) {
    return Container(
      key: const Key('report-draft-banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ada draf tersimpan (${Item.formatDateTime(draft.savedAt)}).',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              FilledButton(
                key: const Key('report-draft-use'),
                onPressed: () => _applyDraft(draft),
                child: const Text('Lanjutkan draf'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _discardDraft,
                child: const Text('Buang'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      key: const Key('report-error'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_errorMessage!, style: TextStyle(color: color)),
          if (_canRetry) ...[
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: const Key('report-retry'),
              onPressed: _isSubmitting ? null : _submitReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba kirim lagi'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E9E8))),
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            key: const Key('submit-report'),
            onPressed: _isSubmitting ? null : _submitReport,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _photos.isEmpty
                            ? 'Mengirim laporan...'
                            : 'Mengunggah ${_photos.length} foto...',
                      ),
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
    );
  }

  Widget _buildCategoryChips(bool locked) {
    return FormField<String>(
      key: const Key('report-category'),
      initialValue: _category,
      validator: (_) => Validators.reportCategory(_category),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ReportCategories.all)
                Tooltip(
                  message: category.examples,
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: _category == category.name,
                    showCheckmark: false,
                    onSelected: _isSubmitting || locked
                        ? null
                        : (selected) {
                            final value = selected ? category.name : null;
                            field.didChange(value);
                            setState(() {
                              _category = value;
                              if (_category2 == value) _category2 = null;
                              _isDirty = true;
                            });
                          },
                    labelStyle: TextStyle(
                      color: _category == category.name ? Colors.white : _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: _green,
                    side: BorderSide(
                      color: _category == category.name ? _green : _outline,
                    ),
                    shape: const StadiumBorder(),
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

  /// Penanda jenis laporan (tidak dapat diubah setelah dipilih, termasuk
  /// saat edit, agar laporan Lost tidak berubah menjadi Found).
  Widget _buildReportTypeSelector() {
    final color = widget.isFound ? _green : const Color(0xFFC20E18);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            widget.isFound ? Icons.check_circle_outline : Icons.search,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isFound
                  ? 'Laporan BARANG DITEMUKAN — foto wajib dari kamera.'
                  : 'Laporan BARANG HILANG — foto opsional dari galeri.',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
      hintMaxLines: 2,
      hintStyle: const TextStyle(fontSize: 13, color: _muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _green, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  ButtonStyle _pickerButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _ink,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      side: const BorderSide(color: _outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
