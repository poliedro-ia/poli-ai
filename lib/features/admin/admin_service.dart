import 'package:cloud_functions/cloud_functions.dart';

class AdminService {
  final _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<Map<String, dynamic>> listUsers({
    String? pageToken,
    int pageSize = 20,
  }) async {
    final callable = _functions.httpsCallable('adminListUsers');
    final res = await callable.call({
      'pageToken': pageToken,
      'pageSize': pageSize,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> setDisabled({
    required String uid,
    required bool disabled,
  }) async {
    final callable = _functions.httpsCallable('adminSetDisabled');
    await callable.call({'uid': uid, 'disabled': disabled});
  }

  Future<void> setRole({required String uid, required bool admin}) async {
    final callable = _functions.httpsCallable('adminSetRole');
    await callable.call({'uid': uid, 'admin': admin});
  }

  Future<void> selfPromote() async {
    final callable = _functions.httpsCallable('adminSelfPromote');
    await callable.call({});
  }
}
