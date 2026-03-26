# Monifly - Dê asas ao seu dinheiro 🦅

Monifly é um aplicativo completo de gestão financeira pessoal desenvolvido em Flutter, com foco em uma experiência de usuário premium, animações fluidas e integração com Supabase.

## 🚀 Funcionalidades

- **Dashboard Inteligente**: Resumo de saldo, receitas, despesas e investimentos.
- **Estratégia 20/10/60/10**: Calculadora integrada para a metodologia de poupança.
- **Gestão de Metas**: Crie e acompanhe o progresso de seus objetivos financeiros.
- **Controle de Transações**: Filtros, busca e categorização completa.
- **Relatórios**: Visualização clara de gastos por categoria e evolução mensal.
- **Orçamentos**: Defina limites por categoria e acompanhe em tempo real.
- **Contas e Vencimentos**: Lembretes de contas a pagar.
- **Fins Premium**: Modo escuro, biometria e animações Lottie.

## 🛠️ Tecnologias

- **Flutter**: UI e Lógica.
- **Riverpod**: Gerenciamento de estado (moderno e performático).
- **Supabase**: Backend (Auth, Database (PostgreSQL), Realtime).
- **Material Design 3**: UI moderna e adaptativa.
- **Shared Preferences**: Persistência local de configurações.

## 🏁 Como Iniciar

### 1. Requisitos
- Flutter SDK >= 3.2.0
- Conta no [Supabase](https://supabase.com)

### 2. Configuração do Supabase
1. Crie um novo projeto no Supabase.
2. Copie a **URL** e a **Anon Key** das configurações de API.
3. Cole as chaves no arquivo: `lib/data/datasources/remote/supabase_client.dart`.

### 3. Banco de Dados
Certifique-se de criar as seguintes tabelas no Supabase (ou use SQL similar):
- `profiles`: `id`, `email`, `name`, `created_at`, `updated_at`
- `transactions`: `id`, `user_id`, `description`, `amount`, `date`, `category`, `type`, `payment_status`, `is_recurring`, etc.
- `goals`: `id`, `user_id`, `name`, `target_amount`, `current_amount`, `target_date`, `category`, etc.
- `budgets`: `id`, `user_id`, `category`, `amount`, `month`

### 4. Assets
Adicione os arquivos de fontes e imagens nas pastas criadas em `assets/`. O arquivo `pubspec.yaml` já está configurado para:
- **Fontes**: Poppins e Inter.
- **Imagens**: Logo, ilustrações e onboarding.

### 5. Executar
```bash
flutter pub get
flutter run
```

---
Desenvolvido com ❤️ para ajudar na sua liberdade financeira.
`Monifly: Dê asas ao seu dinheiro.`
