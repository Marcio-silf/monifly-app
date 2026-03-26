import 'dart:math';

class CalculatorService {
  CalculatorService._();

  // ── Compound Interest ──────────────────────────────────────────────────────

  static Map<String, dynamic> calculateCompoundInterest({
    required double initialAmount,
    required double monthlyContribution,
    required double yearlyInterestRate,
    required int years,
  }) {
    if (years <= 0) return {};

    double monthlyRate = pow(1 + (yearlyInterestRate / 100), 1 / 12) - 1;
    int totalMonths = years * 12;
    
    double amount = initialAmount;
    double totalInvested = initialAmount;
    
    List<Map<String, dynamic>> history = [
      {'month': 0, 'amount': amount, 'invested': totalInvested}
    ];

    for (int month = 1; month <= totalMonths; month++) {
      amount = amount * (1 + monthlyRate);
      if (monthlyContribution > 0) {
        amount += monthlyContribution;
        totalInvested += monthlyContribution;
      }
      
      if (month % 6 == 0 || month == totalMonths) {
        history.add({
          'month': month,
          'amount': amount,
          'invested': totalInvested,
          'interest': amount - totalInvested,
        });
      }
    }

    double totalInterest = amount - totalInvested;

    return {
      'finalAmount': amount,
      'totalInvested': totalInvested,
      'totalInterest': totalInterest,
      'interestPercentage': totalInvested > 0 ? (totalInterest / totalInvested) * 100 : 0,
      'multiplier': totalInvested > 0 ? amount / totalInvested : 0,
      'history': history,
    };
  }

  // ── Cost Per Use ───────────────────────────────────────────────────────────

  static Map<String, dynamic> calculateCostPerUse({
    required double price,
    required int frequencyPerMonth,
    required int intendedMonths,
    double resaleValue = 0,
    double extraCosts = 0,
  }) {
    if (price <= 0 || frequencyPerMonth <= 0 || intendedMonths <= 0) return {};

    double totalCost = price + extraCosts - resaleValue;
    int totalUses = frequencyPerMonth * intendedMonths;
    double costPerUse = totalCost / totalUses;
    double costPerMonth = costPerUse * frequencyPerMonth;

    String rating = 'Muito Alto';
    if (costPerUse < 1) {
      rating = 'Excelente';
    } else if (costPerUse < 5) {
      rating = 'Moderado';
    } else if (costPerUse < 20) {
      rating = 'Elevado';
    }

    return {
      'totalCost': totalCost,
      'totalUses': totalUses,
      'costPerUse': costPerUse,
      'costPerMonth': costPerMonth,
      'rating': rating,
    };
  }

  // ── Hours to Pay ───────────────────────────────────────────────────────────

  static Map<String, dynamic> calculateHoursToPay({
    required double productPrice,
    required double monthlySalary,
    double hoursPerDay = 8,
    int daysPerWeek = 5,
    bool considerDiscounts = true,
  }) {
    if (productPrice <= 0 || monthlySalary <= 0) return {};

    double daysPerMonth = daysPerWeek * 4.33;
    double hoursPerMonth = daysPerMonth * hoursPerDay;
    if (hoursPerMonth == 0) hoursPerMonth = 160;

    double grossHourlyRate = monthlySalary / hoursPerMonth;
    double discountFactor = 1.0;

    if (considerDiscounts) {
      if (monthlySalary <= 1903.98) discountFactor = 0.92;
      else if (monthlySalary <= 2826.65) discountFactor = 0.86;
      else if (monthlySalary <= 3751.05) discountFactor = 0.78;
      else if (monthlySalary <= 4664.68) discountFactor = 0.73;
      else discountFactor = 0.70;
    }

    double netHourlyRate = grossHourlyRate * discountFactor;
    double hoursEquivalent = productPrice / netHourlyRate;
    double daysEquivalent = hoursEquivalent / hoursPerDay;

    String reflection = 'Mais de um mês de trabalho';
    if (hoursEquivalent < 1) reflection = 'Menos de 1 hora de trabalho';
    else if (hoursEquivalent < 4) reflection = 'Uma manhã de trabalho';
    else if (hoursEquivalent < 8) reflection = 'Um dia inteiro de trabalho';
    else if (hoursEquivalent < 40) reflection = 'Aproximadamente ${daysEquivalent.toStringAsFixed(1)} dias de trabalho';

    return {
      'hoursEquivalent': hoursEquivalent,
      'daysEquivalent': daysEquivalent,
      'netHourlyRate': netHourlyRate,
      'reflection': reflection,
      'coffees': (productPrice / 8).floor(),
      'lunches': (productPrice / 35).floor(),
      'gasLiters': (productPrice / 5.5).floor(),
    };
  }
}
