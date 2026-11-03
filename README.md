# Cronômetro All Hands

Cronômetro de palco para o All Hands. O notebook mostra o timer em tela cheia, e o celular controla depois de escanear um QR.

- **Sessões:** cada evento tem um código (ex.: `K7P2QX`) com pauta, mensagens, perguntas e registro de tempos próprios.
- **Controle pelo celular:** o QR de controle leva uma chave secreta. Quem tem só o código vê a agenda, vê o palco e manda perguntas.
- **Registro de tempos:** guarda o tempo previsto, o real (sem pausas), a diferença, o início e o fim de cada apresentação, com exportação em CSV.
- **Por apresentação:** timer regressivo, progressivo ou hora do dia, cores de aviso (amarelo e vermelho), som, início encadeado ou agendado, mensagens com flash e tela preta.

## Como funciona

- Site estático no GitHub Pages (`index.html` + `config.js`).
- Supabase guarda as sessões (`supabase/schema.sql`) e avisa os aparelhos em tempo real (Realtime broadcast + presence).
- As tabelas não ficam acessíveis direto. Tudo passa por funções que conferem a chave de controle.

## Configurar

1. Crie um projeto no Supabase e rode `supabase/schema.sql` no SQL Editor.
2. Preencha `config.js` com a Project URL e a chave `anon` (Settings > API).
3. Ative o GitHub Pages na branch `main`, pasta raiz.
