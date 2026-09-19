import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'content_store.dart';

class CatalogEndpoint extends Endpoint {
  Future<List<TrainingCatalogEntry>> list(Session session) async =>
      ContentStore.catalog();
}
