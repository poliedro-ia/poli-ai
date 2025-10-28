import 'package:cloud_functions/cloud_functions.dart';

class AdminService {
  final _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<Map<String, dynamic>> listUsers({
    String? pageToken,
    int pageSize = 20,
  }) async {
    final res = await _functions.httpsCallable('adminListUsers').call({
      'pageToken': pageToken,
      'pageSize': pageSize,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> setDisabled({
    required String uid,
    required bool disabled,
  }) async {
    await _functions.httpsCallable('adminSetDisabled').call({
      'uid': uid,
      'disabled': disabled,
    });
  }

  Future<void> setRole({required String uid, required bool admin}) async {
    await _functions.httpsCallable('adminSetRole').call({
      'uid': uid,
      'admin': admin,
    });
  }

  Future<void> selfPromote() async {
    await _functions.httpsCallable('adminSelfPromote').call({});
  }
}
