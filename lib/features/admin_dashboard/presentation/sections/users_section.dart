import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/l10n/strings/admin_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../application/admin_actions.dart';
import '../../application/admin_queries.dart';
import '../../domain/admin_models.dart';
import '../widgets/admin_busy.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_list.dart';
import '../widgets/admin_tag.dart';

String roleLabel(AdminStrings s, String role) => switch (role) {
      'restaurant' => s.roleRestaurant,
      'rider' => s.roleRider,
      'admin' => s.roleAdmin,
      _ => s.roleCustomer,
    };

/// Every account: search, filter by role, ban / unban.
class UsersSection extends ConsumerStatefulWidget {
  const UsersSection({super.key});

  @override
  ConsumerState<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends ConsumerState<UsersSection> {
  final _search = TextEditingController();
  String _query = '';
  String? _role; // null = all

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AdminUser u) {
    if (_role != null && u.role != _role) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return u.fullName.toLowerCase().contains(q) ||
        (digits.isNotEmpty &&
            (u.phone ?? '').replaceAll(RegExp(r'\D'), '').contains(digits));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final users = ref.watch(adminUsersProvider);
    final all = users.valueOrNull ?? const <AdminUser>[];
    int count(String role) => all.where((u) => u.role == role).length;

    return AdminAsyncList<AdminUser>(
      value: users.whenData((list) => list.where(_matches).toList()),
      onRefresh: () => ref.refresh(adminUsersProvider.future),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.xs),
            child: AppSearchField(
              hint: s.searchUsers,
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              onClear: _query.isEmpty
                  ? null
                  : () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
            ),
          ),
          AdminFilterBar<String?>(
            selected: _role,
            onSelected: (v) => setState(() => _role = v),
            options: [
              AdminFilterOption(null, s.all, count: all.length),
              AdminFilterOption(UserRole.customer.name, s.rolesCustomers,
                  count: count(UserRole.customer.name)),
              AdminFilterOption(UserRole.restaurant.name, s.rolesRestaurants,
                  count: count(UserRole.restaurant.name)),
              AdminFilterOption(UserRole.rider.name, s.rolesRiders,
                  count: count(UserRole.rider.name)),
              AdminFilterOption(UserRole.admin.name, s.rolesAdmins,
                  count: count(UserRole.admin.name)),
            ],
          ),
        ],
      ),
      empty: AppEmptyState(
        icon: Icons.person_search_rounded,
        title: all.isEmpty ? s.usersEmpty : s.noResults,
        subtitle: all.isEmpty ? null : s.noResultsHint,
        compact: true,
      ),
      itemBuilder: (context, u) => _UserRow(key: ValueKey(u.id), user: u),
    );
  }
}

class _UserRow extends ConsumerStatefulWidget {
  const _UserRow({super.key, required this.user});
  final AdminUser user;

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> with AdminBusy {
  Future<void> _toggle() async {
    final s = context.s.admin;
    final u = widget.user;
    final name = u.fullName.isEmpty ? s.unknown : u.fullName;
    final banning = u.isActive;
    final ok = await AppDialog.confirm(
      context,
      title: banning ? s.banTitle(name) : s.unbanTitle(name),
      message: banning ? s.banMessage : s.unbanMessage,
      confirmLabel: banning ? s.ban : s.unban,
      destructive: banning,
      icon: banning ? Icons.block_rounded : Icons.lock_open_rounded,
    );
    if (!ok || !mounted) return;
    await runAction('toggle',
        () => ref.read(adminActionsProvider).setUserActive(u.id, !banning),
        success: banning ? s.userBanned : s.userUnbanned);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final u = widget.user;
    final role = UserRole.fromString(u.role);
    final isSelf = u.id == supabase.auth.currentUser?.id;
    final name = u.fullName.isEmpty ? s.unknown : u.fullName;
    return AdminRow(
      leading: AdminAvatar(name: name, color: role.color),
      title: name,
      lines: [
        '${u.phone == null || u.phone!.isEmpty ? s.noPhone : AppFormat.phone(u.phone!)} · '
            '${s.joined(AppFormat.date(context, u.createdAt))}',
      ],
      tags: [
        AdminTag(label: roleLabel(s, u.role), tone: AdminTone.brand),
        if (!u.isActive)
          AdminTag(
              label: s.banned,
              icon: Icons.block_rounded,
              tone: AdminTone.error),
        if (isSelf) AdminTag(label: s.you, icon: Icons.person_rounded),
      ],
      actions: isSelf
          ? const []
          : [
              AppButton(
                label: u.isActive ? s.ban : s.unban,
                leadingIcon:
                    u.isActive ? Icons.block_rounded : Icons.lock_open_rounded,
                variant: u.isActive
                    ? AppButtonVariant.outline
                    : AppButtonVariant.tonal,
                textColor: u.isActive ? context.palette.error : null,
                size: AppButtonSize.small,
                expand: false,
                isLoading: busy == 'toggle',
                onPressed: _toggle,
              ),
            ],
    );
  }
}
