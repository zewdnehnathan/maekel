import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';

class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  final _phone = TextEditingController();
  String _role = 'market_moderator';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<_StaffRow> _items = const [];
  List<String> _bootstrapPhones = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw =
          await _api.get('/v1/admin/staff', auth: true) as Map<String, dynamic>;
      final items = ((raw['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (j) => _StaffRow(
              userId: j['userId'] as String,
              phone: j['phone'] as String,
              roles: ((j['roles'] as List?) ?? const [])
                  .map((e) => '$e')
                  .toList(),
            ),
          )
          .toList();
      final boots = ((raw['bootstrapPhones'] as List?) ?? const [])
          .map((e) => '$e')
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _bootstrapPhones = boots;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _grant() async {
    final local = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (local.length != AppConstants.localPhoneLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter a ${AppConstants.localPhoneLength}-digit local number.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post(
        '/v1/admin/roles/grant',
        auth: true,
        body: {
          'phone': '${AppConstants.phoneCountryCode}$local',
          'role': _role,
        },
      );
      _phone.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Role granted. They must sign out and OTP again to refresh the JWT.',
          ),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revoke(_StaffRow row, String role) async {
    setState(() => _saving = true);
    try {
      await _api.post(
        '/v1/admin/roles/revoke',
        auth: true,
        body: {'userId': row.userId, 'role': role},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Revoked $role from ${row.phone}')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).session;
    if (session == null || !session.isPlatformAdmin) {
      return Scaffold(
        body: FuturisticBackdrop(
          child: Center(
            child: Text(
              'Platform admin only',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & admins'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FuturisticBackdrop(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: MaekelColors.danger),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      GlassPanel(
                        accent: MaekelColors.amber,
                        child: Text(
                          _bootstrapPhones.isEmpty
                              ? 'No ADMIN_PHONES configured on the API. Set that env var to bootstrap the first platform admin.'
                              : 'Bootstrap phones (env): ${_bootstrapPhones.join(', ')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'GRANT ROLE',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      GlassPanel(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: MaekelColors.ink),
                              decoration: const InputDecoration(
                                labelText: 'Local phone (9 digits)',
                                prefixText: '+251 ',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              // ignore: deprecated_member_use
                              value: _role,
                              dropdownColor: MaekelColors.panel,
                              decoration:
                                  const InputDecoration(labelText: 'Role'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'market_moderator',
                                  child: Text('Market moderator'),
                                ),
                                DropdownMenuItem(
                                  value: 'platform_admin',
                                  child: Text('Platform admin'),
                                ),
                                DropdownMenuItem(
                                  value: 'market_ops',
                                  child: Text('Market ops'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _role = v);
                              },
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: _saving ? null : _grant,
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : const Text('GRANT'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'STAFF (${_items.length})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_items.isEmpty)
                        const GlassPanel(
                          child: Text('No staff roles assigned yet.'),
                        )
                      else
                        for (final row in _items) ...[
                          GlassPanel(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.phone,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final role in row.roles)
                                      Chip(
                                        label: Text(role),
                                        backgroundColor: MaekelColors.panelLift,
                                        side: const BorderSide(
                                          color: MaekelColors.glassBorder,
                                        ),
                                        onDeleted: _saving ||
                                                (role == 'platform_admin' &&
                                                    row.userId ==
                                                        session.userId)
                                            ? null
                                            : () => _revoke(row, role),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
      ),
    );
  }
}

class _StaffRow {
  const _StaffRow({
    required this.userId,
    required this.phone,
    required this.roles,
  });

  final String userId;
  final String phone;
  final List<String> roles;
}
