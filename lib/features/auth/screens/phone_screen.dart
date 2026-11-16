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
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(fade);

    return Scaffold(
      body: FuturisticBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
                  child: FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'SIGNAL · ETHIOPIA',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 14),
                          Image.asset(
                            'assets/branding/maekel_skyline_logo_light.png',
                            height: 48,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(height: 12),
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [
                                  MaekelColors.ink,
                                  MaekelColors.signal,
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              l10n.appName,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(color: Colors.white, height: 1.05),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.tagline,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: MaekelColors.muted),
                          ),
                          const SizedBox(height: 28),
                          GlassPanel(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.phoneTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(l10n.phoneSubtitle),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _controller,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(
                                      color: MaekelColors.ink,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(
                                        AppConstants.localPhoneLength,
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: l10n.phoneHint,
                                      prefixText: '${l10n.phonePrefix} ',
                                      prefixStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: MaekelColors.signal,
                                      ),
                                    ),
                                    validator: (value) {
                                      final digits = (value ?? '')
                                          .replaceAll(RegExp(r'\D'), '');
                                      if (digits.length !=
                                          AppConstants.localPhoneLength) {
                                        return 'Use ${AppConstants.localPhoneLength} digits after +251';
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _continue(),
                                  ),
                                  if (auth.errorMessage != null) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      auth.errorMessage!,
                                      style: const TextStyle(
                                        color: MaekelColors.danger,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: MaekelColors.signal
                                              .withValues(alpha: 0.35),
                                          blurRadius: 22,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: FilledButton(
                                      onPressed: auth.isSubmitting
                                          ? null
                                          : _continue,
                                      child: auth.isSubmitting
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                              ),
                                            )
                                          : Text(
                                              l10n.continueLabel.toUpperCase(),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
