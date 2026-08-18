# Visão do Time — Farol de Backlog

Painel de acompanhamento de demandas com **D.O.R**, **Status**, **D.O.D**, farol de risco
calculado automaticamente e comentários para reportar ao gestor.

O painel é um arquivo único (`index.html`), sem build e sem dependências —
basta abrir no navegador. Ele salva sozinho no navegador; para compartilhar o
backlog com o time, aponte-o para um fluxo do n8n
([`n8n/visao-time.json`](n8n/visao-time.json), pronto para importar).

## Como usar

1. Abra o `index.html` (duplo clique, ou pelo GitHub Pages — veja abaixo).
2. Clique em qualquer linha da tabela para abrir o painel da demanda:
   checklists de D.O.R e D.O.D, bloqueio com motivo, datas, esforço e comentários.
3. **Resumo no Teams** gera um texto pronto, agrupado por farol — veja
   [Envio para o Teams](#envio-para-o-teams).
4. Não há botão de salvar no fluxo normal — **cada edição é gravada sozinha**.
   Veja [Onde os dados ficam](#onde-os-dados-ficam).

## Onde os dados ficam

Toda alteração é persistida na hora, em duas camadas:

| Camada | Quando | Escopo |
|---|---|---|
| `localStorage` | imediato, a cada edição | só este navegador; funciona offline |
| n8n → Postgres | ~1,5 s depois (agrupado) | compartilhado com o time |

A linha embaixo do título mostra o estado real: `salvando…`,
`sincronizado 14:32`, ou o motivo exato da falha. Se o n8n estiver fora, você
continua trabalhando — o local não depende dele.

Sem o webhook configurado, o painel funciona só com `localStorage`: cada pessoa
tem sua cópia e não há backlog compartilhado.

**Ao abrir a página, o servidor sobrescreve a cópia local.** Duas exceções que
evitam perda de dados:

- banco vazio e há dados locais → o painel **sobe** o local em vez de apagá-lo;
- n8n inalcançável → segue com o local e avisa no indicador.

> ⚠️ Não há trava de concorrência: **duas pessoas editando ao mesmo tempo se
> sobrescrevem**, e a última gravação vence. Para um time pequeno revisando o
> backlog em reunião isso costuma bastar; se virar problema, o caminho é mover
> a escrita para o nível da demanda em vez do backlog inteiro.

**Salvar (.json)** e **Carregar** continuam disponíveis, agora como backup e
importação — não são mais parte da rotina.

## Regras do farol

| Farol | Quando |
|---|---|
| 🔴 Crítico | bloqueada, prazo previsto já vencido, ou entrou em desenvolvimento com D.O.R incompleto |
| 🟡 Atenção | prazo em até 3 dias, D.O.R incompleto já em "Pronto para Dev", concluída sem D.O.D 100%, ou sem data prevista |
| 🟢 No prazo | sem bloqueio, dentro do prazo, checklist coerente com o estágio |
| 🔵 Entregue | status Concluído com D.O.D 100% |

O painel de cada demanda mostra o bloco **"Por que está assim"** com os motivos
exatos do farol — é o que evita a pergunta "por que isso está vermelho?".

O cálculo pode ser sobrescrito manualmente no campo **Farol** da demanda, quando
o automático não refletir a realidade.

## Personalizando para o time

Tudo que é específico do processo está no topo do `<script>`, em `index.html`:

```js
const STATUSES   = [...]   // etapas do fluxo
const PRIORIDADES = [...]
const DOR_ITENS  = [...]   // checklist de Definition of Ready
const DOD_ITENS  = [...]   // checklist de Definition of Done
let   DADOS      = []      // demandas (começa vazio)
```

Editar essas listas é suficiente para adequar ao processo — o resto do painel se
ajusta sozinho (gráficos, filtros, percentuais e farol).

## Publicando para o time (GitHub Pages)

Settings → Pages → Source: `Deploy from a branch` → branch `main`, pasta `/ (root)`.
Em ~1 minuto o painel fica disponível em:

```
https://mohamadkdb.github.io/visao-time-ai/
```

## Envio para o Teams

O botão **Resumo no Teams** tem dois modos. Ambos são configurados em
_Configurar envio_, dentro do próprio painel do resumo — os valores ficam no
`localStorage` do navegador e **não** são versionados.

### 1. Deep link (padrão, sem configuração)

Abre o Teams com uma versão enxuta do resumo (só 🔴 e 🟡) já na caixa de
mensagem. **Você ainda precisa apertar Enter** — o Teams não permite que uma
página web envie mensagem sozinha, e isso é proposital.

Preenchendo o e-mail do gestor, o link já abre o chat correto. O texto vai na
URL, por isso o resumo é encurtado: relatório longo corre risco de ser truncado.

### 2. Webhook do n8n (envio real)

Faz `POST` no seu fluxo do n8n, que decide o que fazer — postar num canal,
mandar no chat do gestor, gravar histórico, escalar o que está vermelho.

O mesmo webhook também guarda o backlog. Um fluxo pronto está em
[`n8n/visao-time.json`](n8n/visao-time.json) — importe no n8n e ajuste as
credenciais. Ele atende três ações, distinguidas pelo campo `acao` do corpo:

| `acao` | o que faz |
|---|---|
| `carregar` | devolve `{demandas, atualizadoEm}` |
| `salvar` | grava o backlog inteiro |
| `resumo` | posta o texto no canal do Teams |

> Os _Incoming Webhooks_ clássicos do Teams (Office 365 connectors) foram
> desativados pela Microsoft em maio de 2026. Fazer o envio pelo n8n contorna
> isso: o nó **Microsoft Teams** usa a API do Graph, não o connector antigo.

#### Montando o fluxo

1. Importe [`n8n/visao-time.json`](n8n/visao-time.json). O nó _Leia primeiro_
   traz estas instruções e o SQL da tabela.
2. Crie a tabela no seu Postgres. O nó Postgres serve tanto um banco próprio
   quanto o **Supabase** — basta usar a connection string do projeto.

   ```sql
   create table if not exists visao_time_backlog (
     id             text primary key default 'atual',
     demandas       jsonb not null default '[]'::jsonb,
     atualizado_em  timestamptz not null default now(),
     atualizado_por text
   );
   ```

   É uma linha só (`id = 'atual'`) com o backlog inteiro em `jsonb`. Simples de
   propósito: o painel manda o estado completo, não diffs.
3. No nó **Webhook** → _Options_ → **Allowed Origins (CORS)**, troque `*` pela
   origem do painel (ex.: `https://mohamadkdb.github.io`). Sem isso o navegador
   não lê a resposta e o `carregar` não funciona.
4. No nó **Microsoft Teams**, preencha Team e Channel (estão como `SUBSTITUA`).
5. Ative o fluxo, copie a **URL de produção** e cole em _Configurar envio e
   sincronização_ no painel.

Dois detalhes que quebram o fluxo silenciosamente se passarem batido:

- O nó Postgres de leitura precisa de **Always Output Data** ligado (já vem
  assim no arquivo). Sem isso, banco vazio devolve zero itens, o branch morre e
  o webhook estoura por timeout em vez de responder lista vazia.
- A gravação usa query **parametrizada**. Título de demanda com apóstrofo
  quebraria SQL montado por concatenação.

#### O que o painel envia

Em `acao: "salvar"` vai só `{acao, demandas}` — o backlog cru, do jeito que o
painel guarda. Em `acao: "resumo"` vai o pacote completo:

```jsonc
{
  "acao": "resumo",
  "geradoEm": "2026-08-18",
  "texto":      "…relatório completo, agrupado por farol…",
  "textoCurto": "…só 🔴 e 🟡, para mensagem curta…",
  "contagem": { "vermelho": 1, "amarelo": 1, "verde": 1, "entregue": 0,
                "ativas": 3, "total": 3, "pontosAbertos": 24 },
  "demandas": [ { "id": "KRD-101", "titulo": "…", "status": "…",
                  "farol": "vermelho", "motivosFarol": ["…"],
                  "dorPct": 100, "dodPct": 0, "bloqueado": true,
                  "motivoBloqueio": "…", "ultimoComentario": { } } ]
}
```

O caminho mais curto é mandar `{{ $json.body.texto }}` direto ao nó do Teams.
`demandas` está aí para quem quiser montar Adaptive Card, filtrar por farol ou
abrir um item por demanda crítica.

#### Duas ressalvas

- **A URL do webhook é uma credencial.** Quem a tiver consegue disparar seu
  fluxo. Ela fica só no seu navegador; nunca a coloque no `index.html` — este
  repo é público. Para endurecer, ative _Header Auth_ no nó Webhook e preencha
  o campo **Token** no painel (vai como `Authorization: Bearer`).
- Se o CORS não estiver liberado, a página tenta um envio sem leitura de
  resposta e avisa _"entrega não confirmada"_: a requisição saiu, mas o
  resultado é ilegível. **Com Token preenchido esse fallback não existe** —
  cabeçalho customizado exige preflight — e o erro é explícito, pedindo o CORS.
- A **URL de teste** do n8n só responde enquanto o editor está escutando um
  evento. Em uso normal, use sempre a de produção com o fluxo ativo.

## Exportações

- **Salvar (.json)** — estado completo, para recarregar depois
- **CSV** — abre no Excel/Sheets, com farol e motivos já resolvidos em colunas
- **Imprimir** — layout limpo para PDF (esconde filtros e botões)
