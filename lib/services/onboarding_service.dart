/// Menyimpan apakah pengguna sudah melihat onboarding.
///
/// Saat ini di memori (reset saat aplikasi ditutup). Agar tersimpan
/// permanen, ganti isi kedua method dengan `shared_preferences`:
///   final prefs = await SharedPreferences.getInstance();
///   prefs.getBool('onboarding_done') / prefs.setBool('onboarding_done', true)
/// Pemanggil tidak perlu diubah karena API-nya sudah async.
class OnboardingService {
  OnboardingService._();

  static bool _done = false;

  static Future<bool> isCompleted() async => _done;

  static Future<void> markCompleted() async => _done = true;
}
