import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok =
        await ref.read(authProvider.notifier).verifyOtp(_controller.text);
    if (ok && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final phone = auth.pendingPhoneE164 ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.auth),
        ),
      ),
      body: FuturisticBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/branding/maekel_skyline_logo_light.png',
                    height: 36,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VERIFY CHANNEL',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.otpTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.otpSubtitle),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: MaekelColors.signal,
                            letterSpacing: 1.1,
                          ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  GlassPanel(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            color: MaekelColors.ink,
                            letterSpacing: 8,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                              AppConstants.otpLength,
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.otpHint,
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            final digits =
                                (value ?? '').replaceAll(RegExp(r'\D'), '');
                            if (digits.length != AppConstants.otpLength) {
                              return 'Enter the ${AppConstants.otpLength}-digit code';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _verify(),
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.errorMessage!,
                            style:
                                const TextStyle(color: MaekelColors.danger),
                          ),
                        ],
                        const SizedBox(height: 20),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    MaekelColors.signal.withValues(alpha: 0.35),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: FilledButton(
                            onPressed: auth.isSubmitting ? null : _verify,
                            child: auth.isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : Text(l10n.verifyLabel.toUpperCase()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
