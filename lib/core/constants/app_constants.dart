class AppConstants {
  AppConstants._();

  static const String appName = 'Monifly';
  static const String tagline = 'Dê asas ao seu dinheiro';
  static const String supabaseUrl = 'https://yjerwnusthcguvukwawb.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqZXJ3bnVzdGhjZ3V2dWt3YXdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0NDAyMDUsImV4cCI6MjA4OTAxNjIwNX0.PuK7j989IfgGZIbHyryq318X2Ct_u6FOYbJ-fK-ttBA';

  // Routes
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeVerifyEmail = '/verify-email';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeMain = '/main';
  static const String routeHome = '/home';
  static const String routeTransactions = '/transactions';
  static const String routeAddTransaction = '/add-transaction';
  static const String routeTransactionDetail = '/transaction-detail';
  static const String routeGoals = '/goals';
  static const String routeAddGoal = '/add-goal';
  static const String routeGoalDetail = '/goal-detail';
  static const String routeBills = '/bills';
  static const String routeInvestments = '/investments';
  static const String routeStrategy = '/strategy';
  static const String routeStrategy503020 = '/strategy/503020';
  static const String routeStrategy602010 = '/strategy/602010';
  static const String routeStrategyRule30Days = '/strategy/rule-30-days';
  static const String routeCalculatorCompound = '/calculator/compound';
  static const String routeCalculatorCostPerUse = '/calculator/cost-per-use';
  static const String routeCalculatorHoursToPay = '/calculator/hours-to-pay';
  static const String routeBudget = '/budget';
  static const String routeReports = '/reports';
  static const String routeNotifications = '/notifications';
  static const String routeProfile = '/profile';
  static const String routeEditProfile = '/edit-profile';
  static const String routeChangePassword = '/change-password';
  static const String routePaywall = '/paywall';

  // SharedPrefs keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyThemeMode = 'theme_mode';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyReminderTime = 'reminder_time';
  static const String keyBalanceVisible = 'balance_visible';
  static const String keyUserName = 'user_name';

  // Transaction types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';
  static const String typeInvestmentIn = 'investment_in';
  static const String typeInvestmentOut = 'investment_out';

  // Payment statuses
  static const String statusPaid = 'paid';
  static const String statusPending = 'pending';
  static const String statusScheduled = 'scheduled';

  // Payment methods
  static const List<String> paymentMethods = [
    'Dinheiro',
    'Débito',
    'Crédito',
    'PIX',
    'Boleto',
    'Transferência',
    'Outro',
  ];

  // Recurring frequencies
  static const String freqMonthly = 'monthly';
  static const String freqYearly = 'yearly';
  static const String freqWeekly = 'weekly';

  // Goal statuses
  static const String goalActive = 'active';
  static const String goalCompleted = 'completed';
  static const String goalCancelled = 'cancelled';

  // Goal categories
  static const List<Map<String, dynamic>> goalCategories = [
    {'key': 'viagem', 'label': 'Viagem', 'icon': '✈️'},
    {'key': 'carro', 'label': 'Carro', 'icon': '🚗'},
    {'key': 'casa', 'label': 'Casa', 'icon': '🏠'},
    {'key': 'estudos', 'label': 'Estudos', 'icon': '📚'},
    {'key': 'aposentadoria', 'label': 'Aposentadoria', 'icon': '🏖️'},
    {'key': 'outros', 'label': 'Outros', 'icon': '🎯'},
  ];

  // Expense categories
  static const List<Map<String, dynamic>> expenseCategories = [
    {'key': 'alimentacao', 'label': 'Alimentação', 'icon': '🍔'},
    {'key': 'transporte', 'label': 'Transporte', 'icon': '🚗'},
    {'key': 'moradia', 'label': 'Moradia', 'icon': '🏠'},
    {'key': 'contas', 'label': 'Contas', 'icon': '⚡'},
    {'key': 'fatura_cartao', 'label': 'Fatura Cartão', 'icon': '💳'},
    {'key': 'boletos', 'label': 'Boletos', 'icon': '📄'},
    {'key': 'saude', 'label': 'Saúde', 'icon': '🏥'},
    {'key': 'educacao', 'label': 'Educação', 'icon': '📚'},
    {'key': 'lazer', 'label': 'Lazer', 'icon': '🎮'},
    {'key': 'compras', 'label': 'Compras', 'icon': '🛍️'},
    {'key': 'pets', 'label': 'Pets', 'icon': '🐾'},
    {'key': 'viagem', 'label': 'Viagem', 'icon': '✈️'},
    {'key': 'trabalho', 'label': 'Trabalho', 'icon': '💼'},
    {'key': 'assinaturas', 'label': 'Assinaturas', 'icon': '📦'},
    {'key': 'manutencao', 'label': 'Manutenção', 'icon': '🔧'},
    {'key': 'filhos', 'label': 'Crianças/Filhos', 'icon': '👶'},
    {'key': 'beleza', 'label': 'Beleza', 'icon': '💇'},
    {'key': 'doacoes', 'label': 'Doações', 'icon': '❤️'},
    {'key': 'celular', 'label': 'Celular', 'icon': '📱'},
    {'key': 'emergencia', 'label': 'Emergência', 'icon': '🚑'},
    {'key': 'outros', 'label': 'Outros', 'icon': '❓'},
  ];

  // Income categories
  static const List<Map<String, dynamic>> incomeCategories = [
    {'key': 'salario', 'label': 'Salário', 'icon': '💼'},
    {'key': 'freelance', 'label': 'Freelance / Autônomo', 'icon': '💻'},
    {'key': 'presente', 'label': 'Presente', 'icon': '🎁'},
    {'key': 'rendimento', 'label': 'Rendimento Investimento', 'icon': '📈'},
    {'key': 'bonus', 'label': 'Bônus / 13º', 'icon': '💰'},
    {'key': 'emprestimo', 'label': 'Empréstimo', 'icon': '🏦'},
    {'key': 'reembolso', 'label': 'Reembolso', 'icon': '🔄'},
    {'key': 'venda', 'label': 'Venda', 'icon': '💵'},
    {'key': 'aluguel', 'label': 'Aluguel recebido', 'icon': '🏠'},
    {'key': 'outros', 'label': 'Outros', 'icon': '❓'},
  ];

  // Investment categories
  static const List<Map<String, dynamic>> investmentCategories = [
    {'key': 'acoes', 'label': 'Ações', 'icon': '📊'},
    {'key': 'tesouro', 'label': 'Tesouro Direto', 'icon': '💹'},
    {'key': 'cripto', 'label': 'Criptomoeda', 'icon': '₿'},
    {'key': 'poupanca', 'label': 'Poupança', 'icon': '🏦'},
    {'key': 'fii', 'label': 'Fundo Imobiliário (FII)', 'icon': '📈'},
    {'key': 'previdencia', 'label': 'Previdência Privada', 'icon': '💼'},
    {'key': 'cdb', 'label': 'CDB / RDB', 'icon': '💵'},
    {'key': 'fundo', 'label': 'Fundo de Investimento', 'icon': '📉'},
    {'key': 'lca', 'label': 'LC/LCA', 'icon': '💰'},
    {'key': 'outros', 'label': 'Outros', 'icon': '❓'},
  ];

  // Health score thresholds
  static const double healthScoreExcellent = 80.0;
  static const double healthScoreGood = 60.0;
  static const double healthScoreFair = 40.0;

  // Default percentage for strategy 20/10/60/10
  static const double strategyReserve = 0.20;
  static const double strategyStudies = 0.10;
  static const double strategyExpenses = 0.60;
  static const double strategyLeisure = 0.10;

  // Alert thresholds
  static const double categoryAlertThreshold = 0.30; // 30% of income
  static const double budgetWarningThreshold = 0.80; // 80% of budget
}
