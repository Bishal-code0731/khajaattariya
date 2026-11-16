import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../payments/application/payment_provider.dart';
import '../../application/admin_actions.dart';
import '../../../../shared/widgets/busy_overlay.dart';

const _switchKeys = ['cash_enabled', 'khalti_enabled', 'esewa_enabled'];
const _textKeys = [
  'default_delivery_fee',
  'commission_percent',
  'rider_share_percent',
  'cod_cash_limit',
  'min_app_version',
  'latest_app_version',
  'terms_version',
];

final _semver = RegExp(r'^\d+\.\d+\.\d+$');

int _compareVersions(String a, String b) {
  final x = a.split('.').map(int.parse).toList();
  final y = b.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return 0;
}

/// Platform settings as a grouped form.
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformSettingsProvider);
    if (async.hasValue) {
      final data = async.value!;
      return _SettingsForm(
        key: ValueKey(
            Object.hashAll(data.entries.map((e) => '${e.key}=${e.value}'))),
        initial: data,
      );
    }
    if (async.hasError) {
      return AppErrorState(
          error: async.error,
          onRetry: () => ref.invalidate(platformSettingsProvider));
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppShimmer(
                height: 180,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          ),
      ],
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({super.key, required this.initial});
  final Map<String, String> initial;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, bool> _switches = {
    for (final k in _switchKeys)
      k: (widget.initial[k] ?? 'true').toLowerCase() == 'true',
  };
  late final Map<String, TextEditingController> _text = {
    for (final k in _textKeys)
      k: TextEditingController(text: widget.initial[k] ?? ''),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _changed {
    final out = <String, String>{};
    for (final k in _switchKeys) {
      final v = _switches[k]! ? 'true' : 'false';
      final before = (widget.initial[k] ?? 'true').toLowerCase();
      if (v != before) out[k] = v;
    }
    for (final k in _textKeys) {
      final v = _text[k]!.text.trim();
      if (v != (widget.initial[k] ?? '').trim()) out[k] = v;
    }
    return out;
  }

  FieldValidator _range(String field, double min, double max) => (v) {
        final c = context.s.common;
        final t = (v ?? '').trim();
        if (t.isEmpty) return c.required(field);
        final n = double.tryParse(t);
        if (n == null) return c.invalidNumber;
        if (n < min || n > max) {
          String f(double d) => d % 1 == 0 ? d.toStringAsFixed(0) : '$d';
          return context.s.admin.rangeError(f(min), f(max));
        }
        return null;
      };

  String? _version(String? v, String field) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return context.s.common.required(field);
    return _semver.hasMatch(t) ? null : context.s.admin.versionInvalid;
  }

  Future<void> _save() async {
    final s = context.s.admin;
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    if (!_switches.values.any((on) => on)) {
      AppSnackbar.warning(context, s.atLeastOnePayment);
      return;
    }
    final changed = _changed;
    if (changed.isEmpty) {
      AppSnackbar.info(context, s.noChanges);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(adminActionsProvider).saveSettings(changed);
      if (mounted) {
        AppSnackbar.success(context, s.settingsSaved(changed.length));
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _saving, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final s = context.s.admin;
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);
    final versionFormat = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
    ];

    Widget numberField(
            String key, String label, String helper, double min, double max) =>
        AppTextField(
          label: label,
          helper: helper,
          controller: _text[key],
          keyboardType: numberKeyboard,
          inputFormatters: decimal,
          validator: _range(label, min, max),
          onChanged: (_) => setState(() {}),
        );

    Widget switchTile(String key, String label, IconData icon) =>
        SwitchListTile(
          value: _switches[key]!,
          onChanged: _saving ? null : (v) => setState(() => _switches[key] = v),
          secondary: Icon(icon),
          title: Text(label),
          contentPadding: EdgeInsets.zero,
        );

    final dirty = _changed.isNotEmpty;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                  AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.xxl),
              children: [
                _Group(
                  title: s.groupPayments,
                  hint: s.groupPaymentsHint,
                  children: [
                    switchTile(
                        'cash_enabled', s.setCash, Icons.payments_outlined),
                    switchTile('khalti_enabled', s.setKhalti,
                        Icons.account_balance_wallet_outlined),
                    switchTile('esewa_enabled', s.setEsewa,
                        Icons.account_balance_wallet_outlined),
                  ],
                ),
                _Group(
                  title: s.groupMoney,
                  hint: s.groupMoneyHint,
                  children: [
                    _Pair(
                      numberField('default_delivery_fee', s.setDeliveryFee,
                          s.setDeliveryFeeHelper, 0, 500),
                      numberField('cod_cash_limit', s.setCodLimit,
                          s.setCodLimitHelper, 0, 1000000),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Pair(
                      numberField('commission_percent', s.setCommission,
                          s.percentHelper, 0, 100),
                      numberField('rider_share_percent', s.setRiderShare,
                          s.percentHelper, 0, 100),
                    ),
                  ],
                ),
                _Group(
                  title: s.groupApp,
                  hint: s.groupAppHint,
                  children: [
                    _Pair(
                      AppTextField(
                        label: s.setMinVersion,
                        helper: s.versionHelper,
                        controller: _text['min_app_version'],
                        keyboardType: numberKeyboard,
                        inputFormatters: versionFormat,
                        validator: (v) => _version(v, s.setMinVersion),
                        onChanged: (_) => setState(() {}),
                      ),
                      AppTextField(
                        label: s.setLatestVersion,
                        helper: s.versionHelper,
                        controller: _text['latest_app_version'],
                        keyboardType: numberKeyboard,
                        inputFormatters: versionFormat,
                        validator: (v) {
                          final err = _version(v, s.setLatestVersion);
                          if (err != null) return err;
                          final min = _text['min_app_version']!.text.trim();
                          if (_semver.hasMatch(min) &&
                              _compareVersions(v!.trim(), min) < 0) {
                            return s.latestBelowMin;
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: s.setTermsVersion,
                      helper: s.setTermsHelper,
                      controller: _text['terms_version'],
                      maxLength: 40,
                      validator:
                          context.validators.text(s.setTermsVersion, max: 40),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Sticky save bar.
          Container(
            decoration: BoxDecoration(
              color: context.palette.surface,
              border: Border(top: BorderSide(color: context.palette.border)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(dirty ? s.unsavedChanges : s.noChanges,
                      style: dirty ? context.text.label : context.text.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                if (dirty) ...[
                  AppButton(
                    label: s.discard,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.medium,
                    expand: false,
                    onPressed: _saving
                        ? null
                        : () => ref.invalidate(platformSettingsProvider),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                AppButton(
                  label: context.s.common.saveChanges,
                  leadingIcon: Icons.check_rounded,
                  size: AppButtonSize.medium,
                  expand: false,
                  isLoading: _saving,
                  onPressed: dirty ? _save : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(
      {required this.title, required this.hint, required this.children});
  final String title;
  final String hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: context.text.h3)),
            const SizedBox(height: 2),
            Text(hint, style: context.text.caption),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair(this.a, this.b);
  final Widget a;
  final Widget b;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 520) {
          return Column(
              children: [a, const SizedBox(height: AppSpacing.lg), b]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: a),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: b),
        ]);
      });
}
