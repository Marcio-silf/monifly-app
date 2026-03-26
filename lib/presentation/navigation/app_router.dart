import 'package:flutter/material.dart';
import 'package:monifly/core/constants/app_constants.dart';
import 'package:monifly/presentation/screens/splash/splash_screen.dart';
import 'package:monifly/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:monifly/presentation/screens/auth/login_screen.dart';
import 'package:monifly/presentation/screens/auth/register_screen.dart';
import 'package:monifly/presentation/screens/auth/verify_email_screen.dart';
import 'package:monifly/presentation/screens/auth/forgot_password_screen.dart';
import 'package:monifly/presentation/screens/transactions/add_transaction_screen.dart';
import 'package:monifly/presentation/screens/transactions/transaction_detail_screen.dart';
import 'package:monifly/presentation/screens/goals/add_goal_screen.dart';
import 'package:monifly/presentation/screens/goals/goal_detail_screen.dart';
import 'package:monifly/presentation/screens/strategy/strategy_hub_screen.dart';
import 'package:monifly/presentation/screens/strategy/budget_503020_screen.dart';
import 'package:monifly/presentation/screens/strategy/budget_602010_screen.dart';
import 'package:monifly/presentation/screens/strategy/rule30days_screen.dart';
import 'package:monifly/presentation/screens/strategy/calculators/compound_interest_screen.dart';
import 'package:monifly/presentation/screens/strategy/calculators/cost_per_use_screen.dart';
import 'package:monifly/presentation/screens/strategy/calculators/hours_to_pay_screen.dart';
import 'package:monifly/presentation/screens/budget/budget_screen.dart';
import 'package:monifly/presentation/screens/reports/reports_screen.dart';
import 'package:monifly/presentation/screens/notifications/notifications_screen.dart';
import 'package:monifly/presentation/screens/bills/bills_screen.dart';
import 'package:monifly/presentation/screens/investments/investments_screen.dart';
import 'package:monifly/presentation/screens/profile/profile_screen.dart';
import 'package:monifly/presentation/screens/profile/edit_profile_screen.dart';
import 'package:monifly/presentation/screens/profile/change_password_screen.dart';
import 'package:monifly/presentation/screens/planning/spending_plan_screen.dart';
import 'package:monifly/presentation/screens/premium/paywall_screen.dart';
import 'main_shell.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routePaywall:
        return _slideRoute(const PaywallScreen(), settings);
      case AppConstants.routeSplash:
        return _fadeRoute(const SplashScreen(), settings);
      case AppConstants.routeOnboarding:
        return _slideRoute(const OnboardingScreen(), settings);
      case AppConstants.routeLogin:
        return _fadeRoute(const LoginScreen(), settings);
      case AppConstants.routeRegister:
        return _slideRoute(const RegisterScreen(), settings);
      case AppConstants.routeVerifyEmail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          VerifyEmailScreen(email: args?['email'] ?? ''),
          settings,
        );
      case AppConstants.routeForgotPassword:
        return _slideRoute(const ForgotPasswordScreen(), settings);
      case AppConstants.routeMain:
        return _fadeRoute(const MainShell(), settings);
      case AppConstants.routeAddTransaction:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          AddTransactionScreen(
            initialType: args?['type'],
            transactionId: args?['id'],
          ),
          settings,
        );
      case AppConstants.routeTransactionDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          TransactionDetailScreen(transactionId: args?['id'] ?? ''),
          settings,
        );
      case AppConstants.routeAddGoal:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(AddGoalScreen(goalId: args?['id']), settings);
      case AppConstants.routeGoalDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          GoalDetailScreen(goalId: args?['id'] ?? ''),
          settings,
        );
      case AppConstants.routeStrategy:
        return _slideRoute(const StrategyHubScreen(), settings);
      case AppConstants.routeStrategy503020:
        return _slideRoute(const Budget503020Screen(), settings);
      case AppConstants.routeStrategy602010:
        return _slideRoute(const Budget602010Screen(), settings);
      case AppConstants.routeStrategyRule30Days:
        return _slideRoute(const Rule30DaysScreen(), settings);
      case AppConstants.routeCalculatorCompound:
        return _slideRoute(const CompoundInterestScreen(), settings);
      case AppConstants.routeCalculatorCostPerUse:
        return _slideRoute(const CostPerUseScreen(), settings);
      case AppConstants.routeCalculatorHoursToPay:
        return _slideRoute(const HoursToPayScreen(), settings);
      case AppConstants.routeBudget:
        return _slideRoute(const BudgetScreen(), settings);
      case AppConstants.routeReports:
        return _slideRoute(const ReportsScreen(), settings);
      case '/spending-plan':
        return _slideRoute(const SpendingPlanScreen(), settings);
      case AppConstants.routeNotifications:
        return _slideRoute(const NotificationsScreen(), settings);
      case AppConstants.routeBills:
        return _slideRoute(const BillsScreen(), settings);
      case AppConstants.routeInvestments:
        return _slideRoute(const InvestmentsScreen(), settings);
      case AppConstants.routeProfile:
        return _slideRoute(const ProfileScreen(), settings);
      case AppConstants.routeEditProfile:
        return _slideRoute(const EditProfileScreen(), settings);
      case AppConstants.routeChangePassword:
        return _slideRoute(const ChangePasswordScreen(), settings);
      default:
        return _fadeRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

