import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/locale/auth_l10n.dart';
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
                    AppLocalizations.of(context)!.authVerifyChannel.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.otpTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.otpSubtitle),
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
                          style: MaekelFonts.latinUi(
                            color: MaekelColors.ink,
                            letterSpacing: 8,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          strutStyle: const StrutStyle(
                            fontSize: 22,
                            height: 1.2,
                            forceStrutHeight: true,
                          ),
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                              AppConstants.otpLength,
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.otpHint,
                            alignLabelWithHint: true,
                            labelStyle: MaekelFonts.latinUi(
                              fontSize: 14,
                              color: MaekelColors.muted,
                            ),
                          ),
                          validator: (value) {
                            final digits =
                                (value ?? '').replaceAll(RegExp(r'\D'), '');
                            if (digits.length != AppConstants.otpLength) {
                              return AppLocalizations.of(context)!.authOtpInvalid;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _verify(),
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            resolveAuthErrorMessage(
                              AppLocalizations.of(context)!,
                              auth.errorMessage,
                            ),
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
                          child: SizedBox(
                            height: 54,
                            width: double.infinity,
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
                                  : Text(
                                      AppLocalizations.of(context)!.verifyLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      strutStyle: const StrutStyle(
                                        fontSize: 16,
                                        height: 1.2,
                                        forceStrutHeight: true,
                                      ),
                                    ),
                            ),
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
