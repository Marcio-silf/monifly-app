import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/premium/upgrade_modal.dart';

class StrategyHubScreen extends ConsumerWidget {
  const StrategyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = ref.watch(subscriptionProvider).isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estratégias e Calculadoras', style: TextStyle(fontSize: 18)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    'Ferramentas Financeiras',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore estratégias comprovadas e calculadoras para tomar melhores decisões.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
          
          _buildSectionHeader(context, 'Estratégias de Orçamento', Icons.account_balance_wallet_rounded),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ActionCard(
                  title: 'A Regra 50-30-20',
                  description: 'A estratégia mais famosa para organizar suas finanças mantendo equilíbrio.',
                  icon: Icons.pie_chart_rounded,
                  color: AppColors.primary,
                  isPremiumOnly: false,
                  hasAccess: true,
                  onTap: () => Navigator.pushNamed(context, AppConstants.routeStrategy503020),
                ),
                _ActionCard(
                  title: 'O Método 60-20-10-10',
                  description: 'Variação para quem quer acelerar reserva de emergência e investimentos.',
                  icon: Icons.track_changes_rounded,
                  color: AppColors.secondary,
                  isPremiumOnly: true,
                  hasAccess: isPremium,
                  onTap: () => _handleTap(context, isPremium, AppConstants.routeStrategy602010),
                ),
                _ActionCard(
                  title: 'Regra dos 30 Dias',
                  description: 'Controle impulsos de compra com um período de reflexão e economize.',
                  icon: Icons.hourglass_bottom_rounded,
                  color: AppColors.accent,
                  isPremiumOnly: true,
                  hasAccess: isPremium,
                  onTap: () => _handleTap(context, isPremium, AppConstants.routeStrategyRule30Days),
                ),
              ]),
            ),
          ),

          _buildSectionHeader(context, 'Calculadoras Inteligentes', Icons.calculate_rounded),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ActionCard(
                  title: 'Juros Compostos',
                  description: 'Simule o crescimento do seu dinheiro ao longo do tempo.',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.income,
                  isPremiumOnly: false,
                  hasAccess: true,
                  onTap: () => Navigator.pushNamed(context, AppConstants.routeCalculatorCompound),
                ),
                _ActionCard(
                  title: 'Custo por Uso',
                  description: 'Descubra se aquela compra cara realmente vale a pena vs alugar.',
                  icon: Icons.sync_alt_rounded,
                  color: AppColors.pending,
                  isPremiumOnly: true,
                  hasAccess: isPremium,
                  onTap: () => _handleTap(context, isPremium, AppConstants.routeCalculatorCostPerUse),
                ),
                _ActionCard(
                  title: 'Horas Trabalhadas',
                  description: 'Converta preços em horas da sua vida e reflita sobre o custo real.',
                  icon: Icons.schedule_rounded,
                  color: AppColors.expense,
                  isPremiumOnly: true,
                  hasAccess: isPremium,
                  onTap: () => _handleTap(context, isPremium, AppConstants.routeCalculatorHoursToPay),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, bool hasAccess, String route) {
    if (hasAccess) {
      Navigator.pushNamed(context, route);
    } else {
      UpgradeModal.show(
        context,
        title: 'Ferramenta Premium',
        message: 'Esta ferramenta avançada é exclusiva para assinantes Monifly Premium. Assine para desbloquear todo o poder do aplicativo!',
      );
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isPremiumOnly;
  final bool hasAccess;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isPremiumOnly,
    required this.hasAccess,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                          if (isPremiumOnly)
                            Icon(
                              hasAccess ? Icons.check_circle_rounded : Icons.lock_rounded,
                              size: 16,
                              color: hasAccess ? AppColors.income : Colors.amber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
