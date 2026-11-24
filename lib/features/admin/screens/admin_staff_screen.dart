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
import '../../../core/locale/auth_l10n.dart';
import '../../../l10n/app_localizations.dart';

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
            AppLocalizations.of(context)!
                .adminPhoneDigits(AppConstants.localPhoneLength),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminRoleGranted),
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.adminRevoked(role, row.phone),
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).session;
    if (session == null || !session.isPlatformAdmin) {
      return Scaffold(
        body: FuturisticBackdrop(
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.adminPlatformOnly,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminTitle),
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
                              ? AppLocalizations.of(context)!
                                  .adminNoAdminPhones
                              : AppLocalizations.of(context)!
                                  .adminBootstrapPhones(
                                    _bootstrapPhones.join(', '),
                                  ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!
                            .adminGrantRole
                            .toUpperCase(),
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
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!
                                    .adminLocalPhone,
                                prefixText:
                                    '${AppLocalizations.of(context)!.phonePrefix} ',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              // ignore: deprecated_member_use
                              value: _role,
                              dropdownColor: MaekelColors.panel,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.adminRole,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'market_moderator',
                                  child: Text(AppLocalizations.of(context)!.adminMarketModerator),
                                ),
                                DropdownMenuItem(
                                  value: 'platform_admin',
                                  child: Text(AppLocalizations.of(context)!.adminPlatformAdmin),
                                ),
                                DropdownMenuItem(
                                  value: 'market_ops',
                                  child: Text(AppLocalizations.of(context)!.adminMarketOps),
                                ),
                                DropdownMenuItem(
                                  value: 'food_ops',
                                  child: Text(AppLocalizations.of(context)!.foodOps),
                                ),
                                DropdownMenuItem(
                                  value: 'food_merchant',
                                  child: Text(AppLocalizations.of(context)!.adminFoodMerchant),
                                ),
                                DropdownMenuItem(
                                  value: 'food_rider',
                                  child: Text(AppLocalizations.of(context)!.adminFoodRider),
                                ),
                                DropdownMenuItem(
                                  value: 'ride_ops',
                                  child: Text(AppLocalizations.of(context)!.adminRideOps),
                                ),
                                DropdownMenuItem(
                                  value: 'events_ops',
                                  child: Text(AppLocalizations.of(context)!.eventsOps),
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
                                  : Text(AppLocalizations.of(context)!.adminGrant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!
                            .adminStaff(_items.length)
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_items.isEmpty)
                        GlassPanel(
                          child: Text(AppLocalizations.of(context)!.adminNoStaff),
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
                                        label: Text(
                                          localizedAdminRole(
                                            AppLocalizations.of(context)!,
                                            role,
                                          ),
                                        ),
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
