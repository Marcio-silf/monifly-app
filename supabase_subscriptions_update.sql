-- ============================================================================
-- MONIFLY: Atualização de Schema para Sistema de Assinaturas (Freemium)
-- Execute este script no SQL Editor do seu projeto Supabase
-- ============================================================================

-- 1. Adicionar novas colunas na tabela de Profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS plan_type TEXT DEFAULT 'free', -- 'free', 'premium_monthly', 'premium_annual'
ADD COLUMN IF NOT EXISTS premium_until TIMESTAMPTZ;

-- 2. Atualizar todos os usuários existentes para 'free' por precaução (opcional, pois o DEFAULT já cobre os novos)
UPDATE public.profiles SET plan_type = 'free' WHERE plan_type IS NULL;

-- 3. (Opcional) Função para ajudar a consultar quantas transações o usuário fez no mês atual 
-- Isso otimiza consultas no app para verificar os limites do plano Free
CREATE OR REPLACE FUNCTION public.get_current_month_transactions_count(p_user_id UUID)
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::integer FROM public.transactions 
  WHERE user_id = p_user_id 
  AND date >= date_trunc('month', CURRENT_DATE)
  AND date < date_trunc('month', CURRENT_DATE) + interval '1 month';
$$;

-- Permissão para acessar a função de contagem
GRANT EXECUTE ON FUNCTION public.get_current_month_transactions_count(UUID) TO authenticated;
