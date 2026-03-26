import Stripe from 'npm:stripe@^14.18.0';
import { createClient } from 'npm:@supabase/supabase-js@^2.39.0';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const cryptoProvider = Stripe.createSubtleCryptoProvider();

Deno.serve(async (req: Request) => {
  const signature = req.headers.get('Stripe-Signature');

  if (!signature) {
    console.error('ERRO: Assinatura da Stripe ausente na requisição.');
    return new Response('Unauthorized', { status: 401 });
  }

  const endpointSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');
  if (!endpointSecret) {
    console.error('ERRO: STRIPE_WEBHOOK_SECRET não configurado.');
    return new Response('Server misconfigured', { status: 500 });
  }

  try {
    const body = await req.text();

    // ✅ VERIFICAÇÃO DE SEGURANÇA: Garante que o sinal veio da Stripe oficial
    const event = await stripe.webhooks.signature.verifyHeaderAsync(
      body,
      signature,
      endpointSecret,
      undefined,
      cryptoProvider
    );

    console.log(`✅ Evento autêntico recebido da Stripe: ${event.type}`);

    if (event.type === 'checkout.session.completed' || event.type === 'invoice.payment_succeeded') {
      const session = event.data.object as any;

      const clientReferenceId =
        session.client_reference_id ||
        session.metadata?.client_reference_id ||
        session.subscription_details?.metadata?.client_reference_id;

      const amountTotal = session.amount_total || session.amount_paid || 0;

      console.log(`ID do Usuário: ${clientReferenceId || 'Não enviado'}`);
      console.log(`Valor: ${amountTotal}`);

      if (!clientReferenceId) {
        console.error('ERRO: client_reference_id ausente. Nenhuma atualização feita.');
        return new Response('Missing client_reference_id', { status: 200 });
      }

      const supabaseUrl = Deno.env.get('SUPABASE_URL');
      const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
      const supabase = createClient(supabaseUrl!, supabaseAnonKey!);

      const daysToAdd = amountTotal > 5000 ? 365 : 30;
      const newPlanType = amountTotal > 5000 ? 'premium_annual' : 'premium_monthly';

      console.log(`🚀 Ativando ${newPlanType} para o usuário ${clientReferenceId}`);

      // Usa a Database Function com SECURITY DEFINER para contornar o RLS
      const { error } = await supabase.rpc('handle_stripe_success', {
        p_user_id: clientReferenceId,
        p_days: daysToAdd,
        p_plan_type: newPlanType,
      });

      if (error) {
        console.error('ERRO no RPC do Supabase:', error.message);
        throw error;
      }

      console.log('🏆 Plano ativado com sucesso via RPC!');
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    console.error('ERRO GERAL NO WEBHOOK:', msg);
    return new Response(`Webhook Error: ${msg}`, { status: 400 });
  }
});
