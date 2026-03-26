import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers/auth_provider.dart';

class SubscriptionState {
  final bool isPremium;
  final String planType;
  final DateTime? premiumUntil;

  const SubscriptionState({
    this.isPremium = false,
    this.planType = 'free',
    this.premiumUntil,
  });

  factory SubscriptionState.fromProfile(UserProfile profile) {
    final now = DateTime.now();

    // ── Plano Vitalício: sem data de expiração, acesso permanente ──────────────
    if (profile.planType == 'lifetime') {
      return const SubscriptionState(
        isPremium: true,
        planType: 'lifetime',
        premiumUntil: null,
      );
    }

    // ── Plano com data de expiração definida no banco (premium ou trial) ───────
    if (profile.premiumUntil != null) {
      final isExpired = profile.premiumUntil!.isBefore(now);

      if (!isExpired) {
        // Determina o rótulo correto do plano
        final effectivePlan = (profile.planType == 'free' || profile.planType.isEmpty)
            ? 'trial'
            : profile.planType;
        return SubscriptionState(
          isPremium: true,
          planType: effectivePlan,
          premiumUntil: profile.premiumUntil,
        );
      }

      // Expirado
      return SubscriptionState(
        isPremium: false,
        planType: 'free',
        premiumUntil: profile.premiumUntil,
      );
    }

    // ── Lógica legada: trial automático de 7 dias pela data de criação ─────────
    final autoTrialLimit = profile.createdAt.add(const Duration(days: 7));
    if (now.isBefore(autoTrialLimit)) {
      return SubscriptionState(
        isPremium: true,
        planType: 'trial',
        premiumUntil: autoTrialLimit,
      );
    }

    return const SubscriptionState();
  }

}

final subscriptionProvider = Provider<SubscriptionState>((ref) {
  final profileAsyncValue = ref.watch(profileProvider);

  return profileAsyncValue.maybeWhen(
    data: (profile) {
      if (profile != null) {
        return SubscriptionState.fromProfile(profile);
      }
      return const SubscriptionState();
    },
    orElse: () => const SubscriptionState(),
  );
});
