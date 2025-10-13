import 'package:flutter/material.dart';
import 'package:app/features/admin/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _svc = AdminService();
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();

  bool _loading = false;
  bool _initialLoaded = false;
  String? _nextToken;
  String _roleFilter = 'todos';
  String _statusFilter = 'todos';
  String _error = '';
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _nextToken == null) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _load(more: true);
    }
  }

  Future<void> _load({bool more = false, bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _error = '';
        _nextToken = null;
      }
    });
    try {
      final res = await _svc.listUsers(
        pageToken: more ? _nextToken : null,
        pageSize: 20,
      );
      final arr = (res['users'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        if (reset || !more) {
          _users = arr;
        } else {
          _users.addAll(arr);
        }
        _nextToken = res['nextPageToken'] as String?;
        _initialLoaded = true;
      });
    } catch (e) {
      setState(() => _error = '$e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadAll() async {
    await _load(reset: true);
  }

  Future<void> _toggleAdmin(String uid, bool value) async {
    await _svc.setRole(uid: uid, admin: value);
    await _reloadAll();
  }

  Future<void> _toggleDisabled(String uid, bool value) async {
    await _svc.setDisabled(uid: uid, disabled: value);
    await _reloadAll();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _users.where((u) {
      final email = (u['email'] as String? ?? '').toLowerCase();
      final name = (u['displayName'] as String? ?? '').toLowerCase();
      final admin = u['admin'] as bool? ?? false;
      final disabled = u['disabled'] as bool? ?? false;
      if (q.isNotEmpty && !(email.contains(q) || name.contains(q)))
        return false;
      if (_roleFilter == 'admin' && !admin) return false;
      if (_roleFilter == 'user' && admin) return false;
      if (_statusFilter == 'ativo' && disabled) return false;
      if (_statusFilter == 'bloqueado' && !disabled) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área Administrativa'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loading ? null : _reloadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome ou e-mail',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Filtrar'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    const Text('Papel'),
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _roleFilter == 'todos',
                      onSelected: (_) => setState(() => _roleFilter = 'todos'),
                    ),
                    ChoiceChip(
                      label: const Text('Usuários'),
                      selected: _roleFilter == 'user',
                      onSelected: (_) => setState(() => _roleFilter = 'user'),
                    ),
                    ChoiceChip(
                      label: const Text('Admins'),
                      selected: _roleFilter == 'admin',
                      onSelected: (_) => setState(() => _roleFilter = 'admin'),
                    ),
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    const Text('Status'),
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _statusFilter == 'todos',
                      onSelected: (_) =>
                          setState(() => _statusFilter = 'todos'),
                    ),
                    ChoiceChip(
                      label: const Text('Ativos'),
                      selected: _statusFilter == 'ativo',
                      onSelected: (_) =>
                          setState(() => _statusFilter = 'ativo'),
                    ),
                    ChoiceChip(
                      label: const Text('Bloqueados'),
                      selected: _statusFilter == 'bloqueado',
                      onSelected: (_) =>
                          setState(() => _statusFilter = 'bloqueado'),
                    ),
                  ],
                ),
                FilledButton.tonal(
                  onPressed: _loading || _nextToken == null
                      ? null
                      : () => _load(more: true),
                  child: const Text('Carregar mais'),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 820;
                if (_error.isNotEmpty) {
                  return _errorView();
                }
                if (!_initialLoaded && _loading) {
                  return _skeletonView();
                }
                if (_filtered.isEmpty) {
                  return _emptyView();
                }
                return wide ? _wideTable(filtered) : _compactList(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      controller: _scroll,
      children: [
        const SizedBox(height: 80),
        Center(child: Text('Erro: $_error')),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: _reloadAll,
            child: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }

  Widget _skeletonView() {
    return ListView.builder(
      controller: _scroll,
      itemCount: 6,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, __) => Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _emptyView() {
    return ListView(
      controller: _scroll,
      children: const [
        SizedBox(height: 80),
        Icon(Icons.group_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 8),
        Center(child: Text('Sem usuários encontrados')),
        SizedBox(height: 120),
      ],
    );
  }

  Widget _wideTable(List<Map<String, dynamic>> data) {
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 920),
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 44,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 52,
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('E-mail')),
              DataColumn(label: Text('Papel')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Verificado')),
              DataColumn(label: Text('Ações')),
            ],
            rows: data.map((u) {
              final uid = u['uid'] as String? ?? '';
              final email = u['email'] as String? ?? '';
              final name = u['displayName'] as String? ?? '';
              final disabled = u['disabled'] as bool? ?? false;
              final admin = u['admin'] as bool? ?? false;
              final verified = u['emailVerified'] as bool? ?? false;
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        name.isNotEmpty ? name : '(Sem nome)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Text(
                        email.isNotEmpty ? email : uid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: admin
                            ? Colors.blue.withOpacity(0.12)
                            : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(admin ? 'Admin' : 'Usuário'),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: disabled
                            ? Colors.red.withOpacity(0.12)
                            : Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(disabled ? 'Bloqueado' : 'Ativo'),
                    ),
                  ),
                  DataCell(
                    Icon(
                      verified ? Icons.verified : Icons.verified_outlined,
                      color: verified ? Colors.green : null,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: admin ? 'Remover admin' : 'Tornar admin',
                          onPressed: () => _toggleAdmin(uid, !admin),
                          icon: Icon(
                            admin ? Icons.shield_outlined : Icons.shield,
                            color: Colors.blue,
                          ),
                        ),
                        IconButton(
                          tooltip: disabled ? 'Desbloquear' : 'Bloquear',
                          onPressed: () => _toggleDisabled(uid, !disabled),
                          icon: Icon(
                            disabled ? Icons.lock_open : Icons.lock,
                            color: disabled ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _compactList(List<Map<String, dynamic>> data) {
    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: data.length + (_loading || _nextToken != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          if (index >= data.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FilledButton.tonal(
                        onPressed: _nextToken == null
                            ? null
                            : () => _load(more: true),
                        child: const Text('Carregar mais'),
                      ),
              ),
            );
          }
          final u = data[index];
          final uid = u['uid'] as String? ?? '';
          final email = u['email'] as String? ?? '';
          final name = u['displayName'] as String? ?? '';
          final disabled = u['disabled'] as bool? ?? false;
          final admin = u['admin'] as bool? ?? false;
          final verified = u['emailVerified'] as bool? ?? false;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: CircleAvatar(
                radius: 18,
                child: Text(
                  (name.isNotEmpty
                          ? name[0]
                          : (email.isNotEmpty ? email[0] : '?'))
                      .toUpperCase(),
                ),
              ),
              title: Text(
                name.isNotEmpty ? name : '(Sem nome)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      email.isNotEmpty ? email : uid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    verified ? Icons.verified : Icons.verified_outlined,
                    size: 16,
                    color: verified ? Colors.green : null,
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'toggle_admin') {
                    await _toggleAdmin(uid, !admin);
                  } else if (value == 'toggle_disabled') {
                    await _toggleDisabled(uid, !disabled);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_admin',
                    child: Row(
                      children: [
                        Icon(
                          admin ? Icons.shield_outlined : Icons.shield,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(admin ? 'Remover admin' : 'Tornar admin'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_disabled',
                    child: Row(
                      children: [
                        Icon(
                          disabled ? Icons.lock_open : Icons.lock,
                          size: 18,
                          color: disabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(disabled ? 'Desbloquear' : 'Bloquear'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
