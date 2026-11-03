# Remote Stage Timer

A stage timer you control from your phone. The stage laptop shows the timer fullscreen; whoever runs the show scans a QR code and controls it from their phone, from any network.

**Live:** https://rafatokairin.github.io/remote-stage-timer/ · English and Portuguese (switch with the EN/PT button)

- **Sessions:** each event gets a short code (e.g. `K7P2QX`) with its own rundown, messages, questions and time log.
- **Phone control by QR:** the control QR carries a secret key. With just the code, people can only view the agenda/stage and send questions.
- **Timers:** countdown, count up, time of day or countdown + time; yellow/red wrap-up colors; chimes; linked (auto-start when the previous ends) and scheduled starts; ±1 min on air.
- **Stage:** fullscreen display with up next, messages to the speaker (colors, flash) and blackout.
- **Time log:** planned vs actual time (pauses excluded), difference, start/end per segment; CSV export.
- **Audience questions:** sent from a QR and turned into stage messages with one tap.

## How it works

- Static site on GitHub Pages (`index.html` + `config.js`).
- Supabase stores the sessions (`supabase/schema.sql`) and pushes live updates (Realtime broadcast + presence).
- Tables are not exposed; everything goes through functions that check the control key (stored only as a SHA-256 hash).

## Setup

1. Create a Supabase project and run `supabase/schema.sql` in the SQL Editor.
2. Fill `config.js` with the Project URL and the `anon` key (Settings > API).
3. Enable GitHub Pages on `main`, root folder.

---

## Português

Timer de palco controlado pelo celular. O notebook do palco mostra o timer em tela cheia, e quem conduz escaneia um QR e controla pelo celular, em qualquer rede. Tem pauta, cores de aviso, som, timers encadeados e agendados, mensagens para quem fala, tela preta, perguntas da plateia e registro dos tempos reais com exportação em CSV. A interface tem português e inglês.
