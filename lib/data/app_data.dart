import 'package:find_it/data/item_repository.dart';
import 'package:find_it/data/report_draft_store.dart';
import 'package:find_it/services/matching_service.dart';
import 'package:find_it/services/report_notification_service.dart';

class AppData {
  AppData._();

  static final ItemRepository repository = ItemRepository();
  static final MatchingService matchingService = MatchingService(
    items: repository.items,
  );

  // Modul 1
  static final ReportNotificationService reportNotifications =
      ReportNotificationService();
  static final ReportDraftStore reportDrafts = ReportDraftStore();
}
