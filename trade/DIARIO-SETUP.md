# Diário dos Traders — implantação

A página \`/trade/diario.html\` já está integrada ao menu do gerenciamento 4x0. Para operar entre dispositivos **é obrigatório configurar um backend**. Sem isso a página informa **MODO DEMONSTRAÇÃO LOCAL**; prints ficam no navegador do usuário e não chegam ao administrador.

## Ativar o armazenamento privado

1. Crie um projeto Supabase sob sua conta e revise o plano, custos e exigências LGPD.
2. Execute \`supabase/diario.sql\` no SQL Editor do projeto, conferindo as políticas RLS e o bucket **privado** \`trade-evidence\`.
3. Em **Authentication > URL Configuration**, defina Site URL para \`https://gabriellemos1.com.br\` e inclua \`https://gabriellemos1.com.br/trade/diario.html\` nos redirects autorizados.
4. Crie os usuários autorizados em Authentication > Users. O aplicativo usa OTP com \`shouldCreateUser:false\`, então nenhum visitante pode se cadastrar livremente.
5. No SQL Editor, adicione os respectivos IDs à tabela \`trade_profiles\`, definindo somente um administrador confiável como \`admin\`. Faça o bootstrap do primeiro admin com SQL Editor usando credenciais de administrador do banco; usuários comuns não podem elevar seus papéis.
6. Edite \`trade/diario-config.js\` com **Project URL** e a **anon/publishable key** da Supabase. Essa chave pode ficar no frontend com RLS corretamente configurada. **Nunca** use \`service_role\` no site.
7. Faça login na página com o e-mail provisionado. O trader verá seus próprios relatórios; o administrador poderá ver todos e marcar como revisados.

## Testes antes de liberar

- Entrar com trader A e trader B: A não pode ver as imagens e relatórios de B.
- Entrar como admin e confirmar acesso aos relatórios de todos.
- Tentar upload de arquivo não permitido e acima de 5 MB; deve falhar.
- Testar autenticação em telefone e computador; testar desconexão e acesso sem login.
- Confirmar no Storage que o bucket continua privado e que URLs assinadas expiram.
- Não compartilhar prints com nome completo, número de conta, CPF, e-mail, QR codes ou outros dados confidenciais. As capturas são declarações enviadas pelo trader, não auditoria de corretora.

## Limitações

O registro do resultado é manual e não comprova a veracidade do print. A plataforma não extrai dados automaticamente da corretora, não calcula retorno auditado, não executa ordens e não autentica usuários enquanto Supabase não estiver configurado. No modo local o navegador pode rejeitar grandes imagens por falta de espaço.
