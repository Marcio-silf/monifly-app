import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../core/services/export_service.dart';

import '../../../data/providers/transaction_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/premium/upgrade_modal.dart';
import '../../../data/providers/spending_plan_provider.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/providers/goal_provider.dart';
import 'package:flutter/foundation.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);


    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: profileAsync.when(
                    data: (profile) => Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo/logo_monifly.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile?.name ?? 'Usuário',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          profile?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer(
                           builder: (context, ref, _) {
                            final subscription = ref.watch(subscriptionProvider);
                            if (subscription.isPremium) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.workspace_premium, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      subscription.planType == 'lifetime'
                                        ? 'Vitalicio'
                                        : (subscription.planType == 'trial' && subscription.premiumUntil != null)
                                          ? 'Teste: ${subscription.premiumUntil!.difference(DateTime.now()).inDays} d'
                                          : subscription.premiumUntil != null
                                            ? 'Premium: ${subscription.premiumUntil!.difference(DateTime.now()).inDays} d res.'
                                            : 'Premium',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Center(
                                child: InkWell(
                                  onTap: () => Navigator.pushNamed(context, AppConstants.routePaywall),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Seja Premium',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                           },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          // Settings list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // App preferences section
                _SectionHeader(title: 'Aparência'),
                // Theme toggle
                _SettingsTile(
                  icon: Icons.contrast_rounded,
                  title: 'Tema',
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Sistema'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Claro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Escuro'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeProvider.notifier).setTheme(mode);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),

                _SectionHeader(title: 'Segurança e Notificações'),
                _SettingsTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notificações',
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: (v) {
                      ref.read(notificationsEnabledProvider.notifier).state = v;
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),


                _SectionHeader(title: 'Dados'),
                _SettingsTile(
                  icon: Icons.ios_share_rounded,
                  title: 'Exportar Relatório Completo (Excel)',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    final subscription = ref.read(subscriptionProvider);
                    if (!subscription.isPremium) {
                      UpgradeModal.show(
                        context,
                        title: 'Exportação Premium',
                        message: 'A exportação completa em Excel com múltiplas abas é exclusiva para membros Premium. Assine agora para ter total controle dos seus dados!',
                      );
                      return;
                    }

                    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
                    final summary = ref.read(monthlySummaryProvider);
                    final expenseByCategory = ref.read(expenseByCategoryProvider);
                    final report = ref.read(monthlyReportProvider);

                    if (transactions.isNotEmpty) {
                      ExportService.exportFullReport(
                        summary: summary,
                        expenseByCategory: expenseByCategory,
                        report: report,
                        transactions: transactions,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nenhuma movimentação para exportar')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                _SectionHeader(title: 'Conta'),
                _SettingsTile(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Editar perfil',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(
                      context, AppConstants.routeEditProfile),
                ),
                _SettingsTile(
                  icon: Icons.key_rounded,
                  title: 'Alterar senha',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(
                      context, AppConstants.routeChangePassword),
                ),
                _SettingsTile(
                  icon: Icons.help_center_rounded,
                  title: 'Sobre o Monifly',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/logo/logo_official.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Sobre o Monifly'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Versão 1.0.0',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Dê asas ao seu dinheiro.'),
                          const SizedBox(height: 16),
                          const Text(
                            '© 2026 Monifly. Todos os direitos reservados.',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sair da conta?'),
                          content: const Text(
                            'Você precisará entrar novamente para acessar o app.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Sair'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        final repo = ref.read(authRepositoryProvider);
                        ref.invalidate(transactionsProvider);
                        ref.invalidate(goalsProvider);
                        ref.invalidate(budgetsProvider);
                        ref.invalidate(spendingPlanProvider);
                        await repo.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            AppConstants.routeLogin,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sair da conta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // App version
                Center(
                  child: Text(
                    'Monifly v1.0.0\nDê asas ao seu dinheiro',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
