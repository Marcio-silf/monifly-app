import '../../data/models/transaction.dart';

class StrategyService {
  StrategyService._();

  // ── 50-30-20 Strategy ────────────────────────────────────────────────────────

  static Map<String, double> calculate503020(double income) {
    if (income <= 0) return {'needs': 0, 'wants': 0, 'savings': 0};
    return {
      'needs': income * 0.50,
      'wants': income * 0.30,
      'savings': income * 0.20,
    };
  }

  static Map<String, dynamic> analyze503020(double income, List<Transaction> transactions) {
    final targets = calculate503020(income);
    
    double needsSpent = 0;
    double wantsSpent = 0;
    double savingsSpent = 0;
    double unmapped = 0;

    final needsKeys = ['moradia', 'contas', 'boletos', 'saude', 'educacao', 'alimentacao', 'transporte', 'manutencao', 'fatura_cartao', 'trabalho', 'filhos', 'emergencia'];
    final wantsKeys = ['lazer', 'compras', 'pets', 'viagem', 'beleza', 'assinaturas', 'celular', 'doacoes', 'outros'];
    // Savings is tracked by investment in (Aplicar Investimento)
    
    for (var t in transactions) {
      if (t.isExpense) {
        if (needsKeys.contains(t.category)) {
          needsSpent += t.amount;
        } else if (wantsKeys.contains(t.category)) {
          wantsSpent += t.amount;
        } else {
          unmapped += t.amount;
        }
      } else if (t.isInvestmentIn) {
        savingsSpent += t.amount;
      }
    }

    List<String> recommendations = [];
    
    if (targets['needs']! > 0) {
      if (needsSpent > targets['needs']! * 1.1) {
        recommendations.add('Suas necessidades estão ${(needsSpent - targets['needs']!).toStringAsFixed(2)} acima da meta (50%). Tente reduzir gastos fixos.');
      }
    }
    
    if (targets['wants']! > 0) {
      if (wantsSpent > targets['wants']! * 1.1) {
        recommendations.add('Gastos com desejos/lazer estão altos. Você ultrapassou os 30% ideais.');
      }
    }

    if (targets['savings']! > 0) {
      if (savingsSpent < targets['savings']! * 0.7) {
        recommendations.add('Você está poupando/investindo menos que 20% da sua renda. Tente aumentar seus aportes.');
      }
    }

    return {
      'targets': targets,
      'spent': {
        'needs': needsSpent,
        'wants': wantsSpent,
        'savings': savingsSpent,
        'unmapped': unmapped,
      },
      'recommendations': recommendations,
    };
  }

  // ── 60-20-10-10 Strategy ───────────────────────────────────────────────────

  static Map<String, double> calculate602010(double income) {
    if (income <= 0) return {'essentials': 0, 'reserve': 0, 'investments': 0, 'leisure': 0};
    return {
      'essentials': income * 0.60,
      'reserve': income * 0.20,
      'investments': income * 0.10,
      'leisure': income * 0.10,
    };
  }

  static Map<String, dynamic> analyze602010(double income, List<Transaction> transactions) {
    final targets = calculate602010(income);
    
    double essentialsSpent = 0;
    double reserveSpent = 0;
    double investmentsSpent = 0;
    double leisureSpent = 0;

    final essentialKeys = ['moradia', 'contas', 'boletos', 'saude', 'educacao', 'alimentacao', 'transporte', 'manutencao', 'fatura_cartao', 'trabalho', 'filhos', 'emergencia'];
    final leisureKeys = ['lazer', 'compras', 'pets', 'viagem', 'beleza', 'assinaturas', 'celular', 'doacoes', 'outros'];
    
    for (var t in transactions) {
      if (t.isExpense) {
        if (essentialKeys.contains(t.category)) {
          essentialsSpent += t.amount;
        } else if (leisureKeys.contains(t.category)) {
          leisureSpent += t.amount;
        }
      } else if (t.isInvestmentIn) {
        // Simple heuristic: consider poupanca/cdb as reserve, others as investments
        if (t.category == 'poupanca' || t.category == 'cdb') {
          reserveSpent += t.amount;
        } else {
          investmentsSpent += t.amount;
        }
      }
    }

    List<String> recommendations = [];
    
    if (targets['essentials']! > 0) {
      if (essentialsSpent > targets['essentials']! * 1.05) {
        recommendations.add('Despesas essenciais estão acima dos 60%. Reveja contas fixas e mercado.');
      } else if (essentialsSpent < targets['essentials']! * 0.8) {
        recommendations.add('Ótimo trabalho mantendo as essenciais baixas! Considere investir a sobra.');
      }
    }

    if (targets['reserve']! > 0) {
      if (reserveSpent < targets['reserve']! * 0.5) {
        recommendations.add('Sua reserva está abaixo da meta (20%). Priorize aportes nela antes de investir em risco.');
      }
    }

    if (targets['investments']! > 0) {
      if (investmentsSpent < targets['investments']! * 0.5) {
        recommendations.add('Tente investir os 10% adicionais para crescimento, se sua reserva já está completa.');
      }
    }

    if (targets['leisure']! > 0) {
      if (leisureSpent > targets['leisure']! * 1.2) {
        recommendations.add('Gastos com lazer estão acima de 10%. Equilíbrio é a chave.');
      } else if (leisureSpent < targets['leisure']! * 0.5) {
        recommendations.add('Você está sendo muito restrito com lazer. Permita-se para manter a motivação!');
      }
    }

    return {
      'targets': targets,
      'spent': {
        'essentials': essentialsSpent,
        'reserve': reserveSpent,
        'investments': investmentsSpent,
        'leisure': leisureSpent,
      },
      'recommendations': recommendations,
    };
  }
}
