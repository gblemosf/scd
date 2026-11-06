# NEXUS CAPITAL GROUP - Gerenciamento simples e dashboard

## Arquitetura

- GitHub Pages: apenas frontend e código publicado em /trade/dashboard.html
- Supabase: autenticação e armazenamento PRIVADO de operações
- Excel: planilha para input do trader; exportação manual para CSV UTF-8
- Dashboard: leitura autenticada de dados e agregação por trader/dia

## Ativação

1. No projeto Supabase "trade", execute o arquivo supabase/trade-operations.sql.
2. Garanta que o script antigo supabase/diario.sql já foi executado e que existem os perfis em public.trade_profiles, com a função public.trade_is_admin().
3. Confira trade/diario-config.js (a URL pública e a publishable key do Supabase).
4. Supabase Authentication > URL Configuration:
   Site URL = https://gabriellemos1.com.br
   Redirect URLs inclui https://gabriellemos1.com.br/trade/dashboard.html
5. Em Authentication > Users, provisione cada trader e associe o UUID ao perfil public.trade_profiles (role trader). Admin deve ter role admin.
6. No Excel use a aba Operacoes: preencha A:J; a aba Resumo calcula resultado localmente.
7. No Excel salve SOMENTE a aba Operacoes como CSV UTF-8. Se disponível, escolher separador ponto e vírgula (padrão regional).
8. O trader abre /trade/dashboard.html, autentica por e-mail e importa o CSV. O sistema ignora o nome de trader digitado no CSV e associa dados ao usuário autenticado.
9. O dashboard exibe resultados agregados e sinalização ilustrativa de violações das regras 4x0. Não envia ordens e não se conecta a corretoras.

## Testes de permissão obrigatórios

- Trader A faz login, importa CSV e vê apenas os próprios registros.
- Trader B faz login e não vê os dados de A.
- Administrador vê A+B e as métricas consolidadas.
- Arquivos malformados são recusados; importações repetidas não duplicam dados.
- Logout e URLs magic-link devem retornar ao dashboard correto.

## Limitações

- Não há sincronização automática Excel/Supabase: importação CSV manual.
- Dados de performance são autodeclarados; não equivalem a extrato certificado.
- Para retorno auditável, integração com API autorizada da corretora seria necessária.
- O "stop na primeira derrota" e demais limites são regras internas; o painel sinaliza possíveis violações, não bloqueia operações realizadas fora do sistema.
- A planilha é compatível com Excel e outros editores. Se exported as XLSX, primeiro converta para CSV UTF-8.
