import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app/core/configs/assets/images.dart';
import 'package:app/features/admin/admin_service.dart';
import 'package:app/features/home/home_page.dart';

class AdminPage extends StatefulWidget {
  final bool darkInitial;
  const AdminPage({super.key, this.darkInitial = true});
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
  late bool _dark;

  Color get _bg => _dark ? const Color(0xff0B0E19) : const Color(0xffF7F8FA);
  Color get _layer => _dark ? const Color(0xff121528) : Colors.white;
  Color get _border =>
      _dark ? const Color(0xff1E2233) : const Color(0xffE7EAF0);
  Color get _textMain => _dark ? Colors.white : const Color(0xff0B1220);
  Color get _textSub =>
      _dark ? const Color(0xff97A0B5) : const Color(0xff5A6477);
  Color get _cta => const Color(0xff2563EB);
  Color get _barBg => _dark ? const Color(0xff101425) : Colors.white;

  @override
  void initState() {
    super.initState();
    _dark = widget.darkInitial;
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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200)
      _load(more: true);
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
      final arr = (res['users'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _users = (reset || !more) ? arr : [..._users, ...arr];
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

  Future<void> _reloadAll() async => _load(reset: true);
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

  ThemeData _theme(BuildContext ctx) {
    final base = Theme.of(ctx);
    return base.copyWith(
      scaffoldBackgroundColor: _bg,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: _barBg,
        foregroundColor: _textMain,
        elevation: 0,
        toolbarHeight: 76,
      ),
      iconTheme: base.iconTheme.copyWith(color: _textMain),
      textTheme: base.textTheme.apply(
        bodyColor: _textMain,
        displayColor: _textMain,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: _dark ? const Color(0xff0F1220) : Colors.white,
        labelStyle: TextStyle(color: _textSub),
        hintStyle: TextStyle(color: _textSub),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: _dark ? const Color(0xff23263A) : const Color(0xffD8DEE9),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _cta, width: 1.4),
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      dataTableTheme: base.dataTableTheme.copyWith(
        dataTextStyle: TextStyle(color: _textMain),
        headingTextStyle: TextStyle(
          color: _textMain,
          fontWeight: FontWeight.w600,
        ),
        headingRowColor: WidgetStateProperty.resolveWith(
          (_) => _dark ? const Color(0x121E2233) : const Color(0x11E7EAF0),
        ),
        dividerThickness: 0.6,
        decoration: BoxDecoration(
          color: _layer,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      backgroundColor: _barBg,
      foregroundColor: _textMain,
      elevation: 0,
      toolbarHeight: 76,
      title: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
          child: Image.asset(
            _dark ? Images.whiteLogo : Images.logo,
            height: 100,
            width: 100,
          ),
        ),
      ),
      actions: [
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _cta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Voltar'),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border.withOpacity(0.7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themed = _theme(context);
    final filtered = _filtered;
    return Theme(
      data: themed,
      child: Scaffold(
        appBar: _appBar(),
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
                      style: TextStyle(color: _textMain),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome ou e-mail',
                        prefixIcon: Icon(Icons.search, color: _textSub),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => setState(() {}),
                    style: FilledButton.styleFrom(
                      backgroundColor: _cta,
                      foregroundColor: Colors.white,
                    ),
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Papel', style: TextStyle(color: _textSub)),
                      _chip(
                        'Todos',
                        _roleFilter == 'todos',
                        () => setState(() => _roleFilter = 'todos'),
                      ),
                      _chip(
                        'Usuários',
                        _roleFilter == 'user',
                        () => setState(() => _roleFilter = 'user'),
                      ),
                      _chip(
                        'Admins',
                        _roleFilter == 'admin',
                        () => setState(() => _roleFilter = 'admin'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Status', style: TextStyle(color: _textSub)),
                      _chip(
                        'Todos',
                        _statusFilter == 'todos',
                        () => setState(() => _statusFilter = 'todos'),
                      ),
                      _chip(
                        'Ativos',
                        _statusFilter == 'ativo',
                        () => setState(() => _statusFilter = 'ativo'),
                      ),
                      _chip(
                        'Bloqueados',
                        _statusFilter == 'bloqueado',
                        () => setState(() => _statusFilter = 'bloqueado'),
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
                builder: (context, c) {
                  final wide = c.maxWidth >= 820;
                  if (_error.isNotEmpty) return _errorView();
                  if (!_initialLoaded && _loading) return _skeletonView();
                  if (_filtered.isEmpty) return _emptyView();
                  return wide ? _wideTable(filtered) : _compactList(filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      controller: _scroll,
      children: [
        const SizedBox(height: 80),
        Center(
          child: Text('Erro: $_error', style: TextStyle(color: _textMain)),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: _reloadAll,
            style: FilledButton.styleFrom(
              backgroundColor: _cta,
              foregroundColor: Colors.white,
            ),
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
          color: _dark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _emptyView() {
    return ListView(
      controller: _scroll,
      children: [
        const SizedBox(height: 80),
        Icon(Icons.group_outlined, size: 64, color: _textSub),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Sem usuários encontrados',
            style: TextStyle(color: _textMain),
          ),
        ),
        const SizedBox(height: 120),
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
                        style: TextStyle(color: _textMain),
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
                        style: TextStyle(color: _textMain),
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
                            ? const Color(0x1A2563EB)
                            : (_dark ? Colors.white12 : Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        admin ? 'Admin' : 'Usuário',
                        style: TextStyle(color: _textMain),
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
                        color: disabled
                            ? const Color(0x1AFF5252)
                            : const Color(0x1A22C55E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        disabled ? 'Bloqueado' : 'Ativo',
                        style: TextStyle(color: _textMain),
                      ),
                    ),
                  ),
                  DataCell(
                    Icon(
                      verified ? Icons.verified : Icons.verified_outlined,
                      color: verified ? Colors.green : _textSub,
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
                            color: _cta,
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
            color: _layer,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: _border),
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
                backgroundColor: _cta.withOpacity(0.18),
                child: Text(
                  ((name.isNotEmpty
                          ? name[0]
                          : (email.isNotEmpty ? email[0] : '?')))
                      .toUpperCase(),
                  style: TextStyle(color: _textMain),
                ),
              ),
              title: Text(
                name.isNotEmpty ? name : '(Sem nome)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(color: _textMain),
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      email.isNotEmpty ? email : uid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 12, color: _textSub),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    verified ? Icons.verified : Icons.verified_outlined,
                    size: 16,
                    color: verified ? Colors.green : _textSub,
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'toggle_admin') {
                    await _toggleAdmin(uid, !admin);
                  } else if (v == 'toggle_disabled') {
                    await _toggleDisabled(uid, !disabled);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle_admin',
                    child: Row(
                      children: [
                        Icon(
                          admin ? Icons.shield_outlined : Icons.shield,
                          size: 18,
                          color: _cta,
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
