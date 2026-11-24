import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/locale/language_picker.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/locale/auth_l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok =
        await ref.read(authProvider.notifier).submitPhone(_controller.text);
    if (ok && mounted) {
      context.go(AppRoutes.otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(fade);

    return Scaffold(
      body: FuturisticBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.authSignalEthiopia.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: AppLocalizations.of(context)!.languageTitle,
                          onPressed: () => showLanguagePicker(context, ref),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                MaekelColors.panel.withValues(alpha: 0.7),
                            side: const BorderSide(
                              color: MaekelColors.glassBorder,
                            ),
                          ),
                          icon: const Icon(Icons.translate_rounded),
                          color: MaekelColors.signal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Image.asset(
                      'assets/branding/maekel_skyline_logo_light.png',
                      height: 48,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.appName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: MaekelColors.signal,
                            height: 1.2,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.tagline,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: MaekelColors.muted,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 24),
                    GlassPanel(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.phoneTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(height: 1.25),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.phoneSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.35),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _controller,
                              keyboardType: TextInputType.phone,
                              style: MaekelFonts.latinUi(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              strutStyle: MaekelFonts.latinStrut,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  AppConstants.localPhoneLength,
                                ),
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: AppLocalizations.of(context)!.phoneHint,
                                hintText: AppLocalizations.of(context)!.phoneHint,
                                prefixText: '${AppLocalizations.of(context)!.phonePrefix} ',
                                prefixStyle: MaekelFonts.latinUi(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: MaekelColors.signal,
                                ),
                                labelStyle: MaekelFonts.latinUi(
                                  fontSize: 14,
                                  color: MaekelColors.muted,
                                ),
                                hintStyle: MaekelFonts.latinUi(
                                  fontSize: 14,
                                  color: MaekelColors.muted,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              validator: (value) {
                                final digits =
                                    (value ?? '').replaceAll(RegExp(r'\D'), '');
                                if (digits.length !=
                                    AppConstants.localPhoneLength) {
                                  return AppLocalizations.of(context)!
                                      .adminPhoneDigits(
                                    AppConstants.localPhoneLength,
                                  );
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _continue(),
                            ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                resolveAuthErrorMessage(
                                  AppLocalizations.of(context)!,
                                  auth.errorMessage,
                                ),
                                style: MaekelFonts.latinUi(
                                  color: MaekelColors.danger,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed:
                                    auth.isSubmitting ? null : _continue,
                                child: auth.isSubmitting
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!.continueLabel,
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
