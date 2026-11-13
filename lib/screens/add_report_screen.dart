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
import 'package:find_it/widgets/report/report_components.dart';
import 'package:find_it/widgets/report/report_theme.dart';
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
        icon: const Icon(
          Icons.privacy_tip_outlined,
          color: ReportColors.green,
          size: 36,
        ),
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

  // =============================================================== Build
  //
  // Susunan mengikuti kanvas desain:
  //  - Hilang   : 1 Barang · 2 Kapan & di mana · 3 Foto · Data privat
  //  - Ditemukan: Foto (kartu gelap) · Detail barang · Keberadaan barang ·
  //               Pertanyaan untuk pemilik

  @override
  Widget build(BuildContext context) {
    final locked = _coreLocked;
    final sections = widget.isFound
        ? <Widget>[
            _buildPhotoCard(),
            _buildFoundDetailsCard(locked),
            _buildKeepingCard(),
            _buildPrivateCard(locked),
          ]
        : <Widget>[
            _buildItemCard(locked),
            _buildWhenWhereCard(locked),
            _buildPhotoCard(),
            _buildPrivateCard(locked),
          ];

    return PopScope<Item>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handlePop();
      },
      child: Scaffold(
        backgroundColor: ReportColors.background,
        body: Column(
          children: [
            ReportHeader(
              title: _isEdit
                  ? 'Ubah laporan'
                  : widget.isFound
                  ? 'Lapor barang ditemukan'
                  : 'Lapor barang hilang',
              subtitle: _isEdit
                  ? 'Perubahan tercatat di riwayat laporan'
                  : 'Isian disimpan sebagai draf bila Anda keluar',
              onBack: _isSubmitting ? null : _handlePop,
              trailing: ReportTag(
                widget.isFound ? 'TEMUAN' : 'HILANG',
                foreground: widget.isFound ? Colors.white : ReportColors.lost,
                background: widget.isFound
                    ? ReportColors.green
                    : ReportColors.lostTint,
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: _hasAttemptedSubmit
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (_pendingDraft case final draft?) ...[
                      _buildDraftBanner(draft),
                      const SizedBox(height: 14),
                    ],
                    if (locked) ...[
                      const ReportBanner(
                        icon: Icons.lock_outline,
                        text:
                            'Laporan ini sedang diverifikasi. Kategori, '
                            'lokasi, dan detail pembeda dikunci sampai klaim '
                            'selesai.',
                      ),
                      const SizedBox(height: 14),
                    ],
                    for (final section in sections) ...[
                      section,
                      const SizedBox(height: 14),
                    ],
                    if (_errorMessage != null) _buildErrorBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: ReportBottomBar(
          buttonKey: const Key('submit-report'),
          label: _isEdit
              ? 'Simpan perubahan'
              : widget.isFound
              ? 'Publikasikan temuan'
              : 'Publikasikan laporan',
          busy: _isSubmitting,
          busyLabel: _photos.isEmpty
              ? 'Mengirim laporan...'
              : 'Mengunggah ${_photos.length} foto...',
          onPressed: _submitReport,
        ),
      ),
    );
  }

  // ------------------------------------------------------- Kartu: Hilang

  Widget _buildItemCard(bool locked) {
    return ReportSectionCard(
      step: 1,
      title: 'Barang apa yang hilang?',
      children: [
        _nameField(),
        _categoryField(locked),
        _descriptionField(),
        _colorBrandRow(),
      ],
    );
  }

  Widget _buildWhenWhereCard(bool locked) {
    return ReportSectionCard(
      step: 2,
      title: 'Kapan & di mana?',
      children: [
        _timeRangeSwitch(),
        _timeTiles(),
        _locationField(locked),
        _approximateCheckbox(locked),
      ],
    );
  }

  // ---------------------------------------------------- Kartu: Ditemukan

  Widget _buildFoundDetailsCard(bool locked) {
    return ReportSectionCard(
      title: 'Detail barang',
      children: [
        _nameField(),
        _categoryField(locked),
        _descriptionField(),
        _colorBrandRow(),
        _timeTiles(),
        _locationField(locked),
      ],
    );
  }

  Widget _buildKeepingCard() {
    return ReportSectionCard(
      title: 'Barang sekarang di mana? *',
      children: [
        Row(
          children: [
            Expanded(
              child: ReportOptionCard(
                key: const Key('report-keeping-withFinder'),
                icon: Icons.shopping_bag_outlined,
                label: 'Saya bawa',
                selected: _keeping == ItemKeeping.withFinder,
                onTap: _isSubmitting
                    ? null
                    : () => _setKeeping(ItemKeeping.withFinder),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ReportOptionCard(
                key: const Key('report-keeping-atSecurityPost'),
                icon: Icons.home_work_outlined,
                label: 'Dititipkan ke pos',
                selected: _keeping == ItemKeeping.atSecurityPost,
                onTap: _isSubmitting
                    ? null
                    : () => _setKeeping(ItemKeeping.atSecurityPost),
              ),
            ),
          ],
        ),
        if (_keeping == ItemKeeping.atSecurityPost)
          TextFormField(
            key: const Key('report-keeping-note'),
            controller: _keepingNoteController,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            decoration: reportInputDecoration(
              hint: 'Tempat penitipan, mis. Pos satpam Gedung F',
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
          ),
      ],
    );
  }

  void _setKeeping(ItemKeeping value) {
    setState(() {
      _keeping = _keeping == value ? null : value;
      _isDirty = true;
    });
  }

  // ------------------------------------------------------- Kartu: umum

  Widget _buildPhotoCard() {
    return ReportSectionCard(
      step: widget.isFound ? null : 3,
      dark: widget.isFound,
      title: widget.isFound ? 'Foto barang *' : 'Foto (opsional)',
      trailing: Text(
        '${_photos.length} / ${ReportRules.maxPhotos}',
        style: TextStyle(
          fontSize: 12,
          color: widget.isFound ? ReportColors.onDeepMuted : ReportColors.muted,
        ),
      ),
      children: [
        ReportPhotoSection(
          photos: _photos,
          isFound: widget.isFound,
          isBusy: _isPickingPhoto || _isSubmitting,
          dark: widget.isFound,
          statusText: _cameraPhotoStatus(),
          onAdd: _addPhoto,
          onAddFromGallery: _allowGalleryFallback
              ? () => _addPhoto(fromGallery: true)
              : null,
          onRemove: _removePhoto,
          onBlur: _blurPhoto,
        ),
      ],
    );
  }

  /// Ringkasan validasi foto kamera terbaru (FR-R11) untuk ditampilkan.
  String? _cameraPhotoStatus() {
    if (!widget.isFound) return null;
    ReportPhotoEntry? latest;
    for (final photo in _photos) {
      if (photo.isExisting || !photo.isFromCamera) continue;
      if (latest == null || photo.takenAt!.isAfter(latest.takenAt!)) {
        latest = photo;
      }
    }
    if (latest == null) return null;
    final minutes = DateTime.now().difference(latest.takenAt!).inMinutes;
    final age = minutes < 1
        ? 'Baru saja diambil'
        : 'Diambil $minutes menit lalu';
    final lat = _latitude;
    final lng = _longitude;
    final photoLat = latest.latitude;
    final photoLng = latest.longitude;
    if (lat == null || lng == null || photoLat == null || photoLng == null) {
      return age;
    }
    final distance = ReportRules.haversineMeters(photoLat, photoLng, lat, lng);
    return '$age · ${distance.round()} m dari titik laporan';
  }

  Widget _buildPrivateCard(bool locked) {
    return ReportSectionCard(
      dark: true,
      icon: Icons.lock_outline,
      title: widget.isFound ? 'Pertanyaan untuk pemilik' : 'Data privat',
      subtitle: widget.isFound
          ? 'Ciri yang hanya diketahui pemilik asli. Tidak tampil publik; '
                'dipakai untuk menguji klaim.'
          : 'Tidak tampil di laporan publik.',
      children: [
        ReportField(
          dark: true,
          label: 'Detail pembeda rahasia',
          helper: 'Hanya Anda yang melihatnya saat memverifikasi klaim.',
          child: TextFormField(
            key: const Key('report-secret-detail'),
            controller: _secretDetailController,
            enabled: !_isSubmitting && !locked,
            minLines: 2,
            maxLines: 3,
            maxLength: ReportRules.maxSecretDetailLength,
            validator: Validators.reportSecretDetail,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: reportInputDecoration(
              dark: true,
              hint: widget.isFound
                  ? 'mis. isi dompet, wallpaper HP'
                  : 'mis. ada stiker kucing di bagian bawah',
            ),
          ),
        ),
        ReportField(
          dark: true,
          label: 'Nomor WhatsApp (opsional)',
          helper:
              'Dibagikan hanya setelah klaim disetujui dan kedua pihak '
              'setuju bertukar kontak.',
          child: TextFormField(
            key: const Key('report-whatsapp'),
            controller: _whatsappController,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.phone,
            validator: Validators.reportWhatsapp,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
            ],
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: reportInputDecoration(dark: true, hint: '081234567890'),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- Field

  Widget _nameField() {
    return ReportField(
      label: 'Nama barang',
      required: true,
      child: TextFormField(
        key: const Key('report-name'),
        controller: _nameController,
        enabled: !_isSubmitting,
        maxLength: ReportRules.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        validator: (value) =>
            Validators.reportName(value) ??
            ReportRules.validateSensitiveTitle(_category, value!),
        decoration: reportInputDecoration(
          hint: widget.isFound
              ? 'mis. Dompet kulit coklat'
              : 'mis. Tumbler hijau',
        ),
      ),
    );
  }

  Widget _categoryField(bool locked) {
    return FormField<String>(
      key: const Key('report-category'),
      initialValue: _category,
      validator: (_) => Validators.reportCategory(_category),
      builder: (field) => ReportField(
        label: 'Kategori',
        required: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                key: const Key('report-category-list'),
                scrollDirection: Axis.horizontal,
                itemCount: ReportCategories.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = ReportCategories.all[index];
                  return Center(
                    child: ReportChoicePill(
                      label: category.name,
                      tooltip: category.examples,
                      selected: _category == category.name,
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
                    ),
                  );
                },
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: const TextStyle(color: ReportColors.lost, fontSize: 12),
              ),
            ],
            if (_isSensitiveCategory) ...[
              const SizedBox(height: 10),
              const ReportBanner(
                icon: Icons.shield_outlined,
                text:
                    'Kategori ini rawan data pribadi. Jangan tulis nama atau '
                    'nomor kartu, dan samarkan KTM/ATM di foto.',
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('report-category2'),
                onPressed: _isSubmitting || locked ? null : _pickSecondCategory,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(
                  _category2 == null
                      ? 'Tambah kategori kedua (opsional)'
                      : 'Kategori kedua: $_category2',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ReportColors.green,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _descriptionField() {
    return ReportField(
      label: 'Deskripsi umum',
      required: true,
      helper: 'Ciri khusus simpan di bagian rahasia agar tidak ditiru.',
      child: TextFormField(
        key: const Key('report-description'),
        controller: _descriptionController,
        enabled: !_isSubmitting,
        minLines: 2,
        maxLines: 4,
        maxLength: ReportRules.maxDescriptionLength,
        textCapitalization: TextCapitalization.sentences,
        validator: Validators.reportDescription,
        decoration: reportInputDecoration(
          hint: 'Warna, ukuran, kondisi yang boleh dilihat publik',
        ),
      ),
    );
  }

  Widget _colorBrandRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ReportField(
            label: 'Warna',
            child: TextFormField(
              key: const Key('report-color'),
              controller: _colorController,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.sentences,
              decoration: reportInputDecoration(hint: 'mis. Hitam'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ReportField(
            label: 'Merek',
            child: TextFormField(
              key: const Key('report-brand'),
              controller: _brandController,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              decoration: reportInputDecoration(hint: 'mis. Eiger'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeRangeSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: ReportColors.background,
        borderRadius: BorderRadius.circular(ReportRadius.field),
      ),
      child: SwitchListTile(
        key: const Key('report-time-range'),
        value: _useTimeRange,
        activeThumbColor: Colors.white,
        activeTrackColor: ReportColors.green,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReportRadius.field),
        ),
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
          'Tidak tahu waktu pastinya',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Isi rentang waktu, mis. 10.00–13.00',
          style: TextStyle(fontSize: 12, color: ReportColors.muted),
        ),
      ),
    );
  }

  Widget _timeTiles() {
    final range = !widget.isFound && _useTimeRange;
    return ReportField(
      label: widget.isFound ? 'Waktu ditemukan' : 'Waktu hilang',
      required: true,
      child: Row(
        children: [
          Expanded(
            child: ReportDateTimeTile(
              key: const Key('report-time-start'),
              caption: range ? 'Dari' : 'Tanggal & jam',
              value: Item.formatDateTime(_eventStart),
              onTap: _isSubmitting ? null : _selectStart,
            ),
          ),
          if (range) ...[
            const SizedBox(width: 10),
            Expanded(
              child: ReportDateTimeTile(
                key: const Key('report-time-end'),
                caption: 'Sampai',
                value: Item.formatDateTime(_eventEnd),
                onTap: _isSubmitting ? null : _selectEnd,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationField(bool locked) {
    final hasPin = _latitude != null && _longitude != null;
    return ReportField(
      label: widget.isFound ? 'Lokasi ditemukan' : 'Perkiraan lokasi hilang',
      required: true,
      helper: widget.isFound
          ? null
          : 'Pilih tempat barang kemungkinan hilang, bukan lokasi Anda '
                'sekarang.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('report-location'),
            controller: _locationController,
            enabled: !_isSubmitting && !locked,
            textCapitalization: TextCapitalization.sentences,
            validator: Validators.reportLocation,
            decoration: reportInputDecoration(
              hint: 'Nama gedung / area kampus',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: ReportColors.typeColor(widget.isFound),
              ),
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
                        : const Icon(
                            Icons.my_location,
                            color: ReportColors.green,
                          ),
                  ),
                  IconButton(
                    key: const Key('report-pick-map'),
                    tooltip: 'Pilih di peta kampus',
                    onPressed: _isSubmitting || locked
                        ? null
                        : _openLocationPicker,
                    icon: const Icon(
                      Icons.map_outlined,
                      color: ReportColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final landmark in CampusLocations.landmarkNames.take(8))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(landmark),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        color: ReportColors.ink,
                      ),
                      backgroundColor: ReportColors.surface,
                      side: const BorderSide(color: Color(0xFFD3E0DA)),
                      shape: const StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                      onPressed: _isSubmitting || locked
                          ? null
                          : () => _selectLandmark(landmark),
                    ),
                  ),
              ],
            ),
          ),
          if (hasPin) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('report-pin-info'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ReportColors.mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: ReportColors.green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Titik di peta: ${_latitude!.toStringAsFixed(5)}, '
                      '${_longitude!.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: ReportColors.green,
                      ),
                    ),
                  ),
                  if (!locked)
                    TextButton(
                      onPressed: _isSubmitting ? null : _clearPin,
                      style: TextButton.styleFrom(
                        foregroundColor: ReportColors.green,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Hapus titik'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _approximateCheckbox(bool locked) {
    return CheckboxListTile(
      key: const Key('report-location-approx'),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: ReportColors.green,
      value: _isLocationApproximate,
      onChanged: _isSubmitting || locked
          ? null
          : (value) => setState(() {
              _isLocationApproximate = value ?? false;
              _isDirty = true;
            }),
      title: const Text(
        'Saya tidak yakin lokasi pastinya',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: const Text(
        'Laporan ditandai "lokasi perkiraan".',
        style: TextStyle(fontSize: 12, color: ReportColors.muted),
      ),
    );
  }

  // ------------------------------------------------------ Banner & error

  Widget _buildDraftBanner(ReportDraft draft) {
    return ReportBanner(
      key: const Key('report-draft-banner'),
      tone: ReportBannerTone.success,
      icon: Icons.description_outlined,
      text: 'Ada draf tersimpan (${Item.formatDateTime(draft.savedAt)}).',
      action: Wrap(
        spacing: 8,
        children: [
          FilledButton(
            key: const Key('report-draft-use'),
            onPressed: () => _applyDraft(draft),
            style: FilledButton.styleFrom(
              backgroundColor: ReportColors.green,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Lanjutkan draf'),
          ),
          TextButton(
            onPressed: _discardDraft,
            style: TextButton.styleFrom(
              foregroundColor: ReportColors.greenDeep,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
    return ReportBanner(
      key: const Key('report-error'),
      tone: ReportBannerTone.danger,
      icon: Icons.error_outline,
      text: _errorMessage!,
      action: _canRetry
          ? OutlinedButton.icon(
              key: const Key('report-retry'),
              onPressed: _isSubmitting ? null : _submitReport,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba kirim lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ReportColors.lost,
                side: const BorderSide(color: ReportColors.lost),
                visualDensity: VisualDensity.compact,
              ),
            )
          : null,
    );
  }
}
