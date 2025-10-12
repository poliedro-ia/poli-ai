import 'package:app/features/admin/admin_service.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _svc = AdminService();
  bool _loading = true;
  String? _nextToken;
  List<Map<String, dynamic>> _users = [];

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    final res = await _svc.listUsers(
      pageToken: more ? _nextToken : null,
      pageSize: 20,
    );
    final List<dynamic> arr = res['users'] as List<dynamic>;
    final list = arr.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    setState(() {
      if (more) {
        _users.addAll(list);
      } else {
        _users = list;
      }
      _nextToken = res['nextPageToken'] as String?;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loading = false;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Área Administrativa')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                FilledButton(
                  onPressed: _loading ? null : () => _load(),
                  child: const Text('Recarregar'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _loading || _nextToken == null
                      ? null
                      : () => _load(more: true),
                  child: const Text('Carregar mais'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _users.isEmpty
                  ? const Center(child: Text('Sem usuários listados.'))
                  : ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = _users[index];
                        final uid = u['uid'] as String? ?? '';
                        final email = u['email'] as String? ?? '';
                        final name = u['displayName'] as String? ?? '';
                        final disabled = u['disabled'] as bool? ?? false;
                        final admin = u['admin'] as bool? ?? false;
                        final verified = u['emailVerified'] as bool? ?? false;
                        return ListTile(
                          title: Text(name.isNotEmpty ? name : '(Sem nome)'),
                          subtitle: Text(email.isNotEmpty ? email : uid),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              Tooltip(
                                message: verified
                                    ? 'E-mail verificado'
                                    : 'E-mail não verificado',
                                child: Icon(
                                  verified
                                      ? Icons.verified
                                      : Icons.verified_outlined,
                                  color: verified ? Colors.green : null,
                                ),
                              ),
                              FilterChip(
                                selected: admin,
                                label: const Text('Admin'),
                                onSelected: (sel) async {
                                  await _svc.setRole(uid: uid, admin: sel);
                                  await _load();
                                },
                              ),
                              FilterChip(
                                selected: disabled,
                                label: const Text('Bloqueado'),
                                onSelected: (sel) async {
                                  await _svc.setDisabled(
                                    uid: uid,
                                    disabled: sel,
                                  );
                                  await _load();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
