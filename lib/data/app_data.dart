import 'item_repository.dart';
import '../services/matching_service.dart';

class AppData {
  AppData._();

  static final ItemRepository repository = ItemRepository();
  static final MatchingService matchingService = MatchingService(
    items: repository.items,
  );
}
