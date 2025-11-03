import 'package:app/core/motion/motion.dart';
import 'package:app/core/motion/route.dart';
import 'package:flutter/material.dart';
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
        pageSize: 24,
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
      if (q.isNotEmpty && !(email.contains(q) || name.contains(q))) {
        return false;
      }
      if (_roleFilter == 'admin' && !admin) return false;
      if (_roleFilter == 'user' && admin) return false;
      if (_statusFilter == 'ativo' && disabled) return false;
      if (_statusFilter == 'bloqueado' && !disabled) return false;
      return true;
    }).toList();
  }

  int get _countAdmins =>
      _users.where((u) => (u['admin'] as bool? ?? false)).length;
  int get _countDisabled =>
      _users.where((u) => (u['disabled'] as bool? ?? false)).length;

  ThemeData _theme(BuildContext ctx) {
    final base = Theme.of(ctx);
    return base.copyWith(
      scaffoldBackgroundColor: _bg,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
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
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _cta, width: 1.6),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: Color(0xff2563EB),
        textColor: Colors.white,
      ),
      dataTableTheme: base.dataTableTheme.copyWith(
        dataTextStyle: TextStyle(color: _textMain),
        headingTextStyle: TextStyle(
          color: _textMain,
          fontWeight: FontWeight.w700,
        ),
        headingRowColor: WidgetStateProperty.resolveWith(
          (_) => _dark ? const Color(0x121E2233) : const Color(0x11E7EAF0),
        ),
        dividerThickness: 0.6,
        decoration: BoxDecoration(
          color: _layer,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: _bg,
      foregroundColor: _textMain,
      elevation: 0,
      toolbarHeight: 76,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, slideUpRoute(const HomePage()));
          },
          child: Entry(
            dy: -8,
            child: Image.asset(
              _dark ? Images.whiteLogo : Images.logo,
              height: 100,
              width: 100,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Entry(
            dy: -8,
            delay: const Duration(milliseconds: 120),
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.push(context, slideUpRoute(const HomePage())),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Voltar'),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _textSub.withOpacity(0.25)),
      ),
    );
  }

  Widget _quickStat({
    required IconData icon,
    required String label,
    required String value,
    List<Color>? gradient,
  }) {
    final g =
        gradient ??
        (_dark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFFEFF3FE), const Color(0xFFFFFFFF)]);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: g,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _cta.withOpacity(.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _cta),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _textSub),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: _textMain,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersBar() {
    return Container(
      decoration: BoxDecoration(
        color: _layer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (_, c) {
              final wrap = c.maxWidth < 680;
              final role = Row(
                children: [
                  Text('Papel', style: TextStyle(color: _textSub)),
                  const SizedBox(width: 10),
                  Wrap(
                    spacing: 8,
                    children: [
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
                ],
              );
              final status = Row(
                children: [
                  Text('Status', style: TextStyle(color: _textSub)),
                  const SizedBox(width: 10),
                  Wrap(
                    spacing: 8,
                    children: [
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
                ],
              );
              return wrap
                  ? Column(children: [role, const SizedBox(height: 8), status])
                  : Row(
                      children: [
                        Expanded(child: role),
                        Expanded(child: status),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _cta.withOpacity(.15),
      labelStyle: TextStyle(color: selected ? _textMain : _textSub),
      side: BorderSide(color: selected ? _cta : _border),
      backgroundColor: _dark
          ? const Color(0x141E2233)
          : const Color(0x14E7EAF0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _dark
                          ? [const Color(0xFF0B0E19), const Color(0xFF0E1325)]
                          : [const Color(0xFFF7F8FA), const Color(0xFFEFF3FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -90,
              right: -70,
              child: _halo(300, _cta.withOpacity(.12)),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _halo(260, const Color(0xFF22C55E).withOpacity(.10)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _quickStat(
                                  icon: Icons.groups_rounded,
                                  label: 'Total',
                                  value: _users.length.toString(),
                                  gradient: _dark
                                      ? [
                                          const Color(0xFF0F172A),
                                          const Color(0xFF111827),
                                        ]
                                      : [
                                          const Color(0xFFFFFFFF),
                                          const Color(0xFFF5F7FF),
                                        ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _quickStat(
                                  icon: Icons.shield_rounded,
                                  label: 'Admins',
                                  value: _countAdmins.toString(),
                                  gradient: [
                                    const Color(0xFF2563EB).withOpacity(.18),
                                    const Color(0xFF7C3AED).withOpacity(.18),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _quickStat(
                                  icon: Icons.lock_rounded,
                                  label: 'Bloqueados',
                                  value: _countDisabled.toString(),
                                  gradient: [
                                    const Color(0xFFEF4444).withOpacity(.18),
                                    const Color(0xFFF59E0B).withOpacity(.18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _filtersBar(),
                    const SizedBox(height: 14),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final wide = c.maxWidth >= 900;
                          if (_error.isNotEmpty) return _errorView();
                          if (!_initialLoaded && _loading) {
                            return _skeletonView();
                          }
                          if (filtered.isEmpty) return _emptyView();
                          return wide
                              ? _wideTable(filtered)
                              : _compactList(filtered);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: !_loading && _nextToken != null
            ? FloatingActionButton.extended(
                onPressed: () => _load(more: true),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Carregar mais'),
                backgroundColor: _cta,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _halo(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 60, spreadRadius: 10)],
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      controller: _scroll,
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 64, color: _textSub),
        const SizedBox(height: 8),
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
      itemCount: 8,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: _dark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
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
          constraints: const BoxConstraints(minWidth: 1000),
          child: DataTable(
            columnSpacing: 26,
            headingRowHeight: 46,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 56,
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
                      width: 240,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _cta.withOpacity(.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                ((name.isNotEmpty
                                        ? name[0]
                                        : (email.isNotEmpty ? email[0] : '?')))
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _textMain,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name.isNotEmpty ? name : '(Sem nome)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _textMain),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 280,
                      child: Text(
                        email.isNotEmpty ? email : uid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _textMain),
                      ),
                    ),
                  ),
                  DataCell(
                    _badge(
                      admin ? 'Admin' : 'Usuário',
                      admin ? _cta : (_dark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                  DataCell(
                    _badge(
                      disabled ? 'Bloqueado' : 'Ativo',
                      disabled
                          ? const Color(0x33EF4444)
                          : const Color(0x3322C55E),
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

  Widget _badge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _textMain,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: _cta.withOpacity(.18),
                child: Text(
                  ((name.isNotEmpty
                          ? name[0]
                          : (email.isNotEmpty ? email[0] : '?')))
                      .toUpperCase(),
                  style: TextStyle(
                    color: _textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                name.isNotEmpty ? name : '(Sem nome)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _textMain),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        email.isNotEmpty ? email : uid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
