import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/gradients.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../data/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;

  Future<void> _simulatedPurchase(String planType) async {
    setState(() => _isLoading = true);
    
    try {
      // Pega o ID do usuário para associar o pagamento à conta dele
      final currentUser = ref.read(currentUserProvider);
      final userId = currentUser?.id ?? '';

      // Links fornecidos (Pode ajustar caso tenha invertido Mensal e Anual)
      final String stripeLinkMensal = 'https://buy.stripe.com/28E9AM0s0eM03Wl8Lu2B200?client_reference_id=$userId';
      final String stripeLinkAnual = 'https://buy.stripe.com/14AdR22A8avK64taTC2B202?client_reference_id=$userId';

      final urlString = planType.contains('annual') ? stripeLinkAnual : stripeLinkMensal;
      final Uri url = Uri.parse(urlString);

      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aguardando seus links reais de pagamento para abrir.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao redirecionar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.monifly,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
                          const SizedBox(height: 16),
                          const Text(
                            'Monifly Premium',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Alcance sua liberdade financeira sem limites.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Benefícios
                          _buildBenefitItem(Icons.all_inclusive, 'Transações e Metas Ilimitadas'),
                          _buildBenefitItem(Icons.pie_chart, 'Relatórios Avançados e Exportação em CSV'),
                          _buildBenefitItem(Icons.auto_awesome, 'Estratégias Interativas (Planejamento)'),
                          _buildBenefitItem(Icons.category, 'Categorias Personalizadas'),
                        ],
                      ),
                    ),
                  ),
                  
                  // Cards de Preço
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        _buildPlanCard(
                          context,
                          title: 'Plano Mensal',
                          price: 'R\$ 9,90',
                          period: '/mês',
                          onTap: () => _simulatedPurchase('premium_monthly'),
                        ),
                        const SizedBox(height: 16),
                        _buildPlanCard(
                          context,
                          title: 'Plano Anual (Recomendado)',
                          price: 'R\$ 89,90',
                          period: '/ano',
                          isFeatured: true,
                          onTap: () => _simulatedPurchase('premium_annual'),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cancele a qualquer momento.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Processando seu pedido...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    bool isFeatured = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isFeatured ? AppGradients.monifly : null,
          color: isFeatured ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isFeatured ? null : Border.all(color: AppColors.borderLight),
          boxShadow: isFeatured
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isFeatured ? Colors.white : null,
                  ),
                ),
                if (isFeatured)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Economize 24%',
                      style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isFeatured ? Colors.white : AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: TextStyle(
                      fontSize: 14,
                      color: isFeatured ? Colors.white70 : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
