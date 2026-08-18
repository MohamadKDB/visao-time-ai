# Visão do Time — Farol de Backlog

Painel de acompanhamento de demandas com **D.O.R**, **Status**, **D.O.D**, farol de risco
calculado automaticamente e comentários para reportar ao gestor.

É um arquivo único (`index.html`), sem build, sem dependências, sem servidor.
Basta abrir no navegador.

## Como usar

1. Abra o `index.html` (duplo clique, ou pelo GitHub Pages — veja abaixo).
2. Clique em qualquer linha da tabela para abrir o painel da demanda:
   checklists de D.O.R e D.O.D, bloqueio com motivo, datas, esforço e comentários.
3. **Resumo no Teams** gera um texto pronto, agrupado por farol — veja
   [Envio para o Teams](#envio-para-o-teams).
4. Ao terminar de editar, clique em **Salvar (.json)** e guarde o arquivo.
   Na próxima vez, use **Carregar** para continuar de onde parou.

> ⚠️ A página **não salva sozinha**. O estado vive no arquivo `.json` que você
> baixa. Sugestão: manter o `backlog-AAAA-MM-DD.json` numa pasta compartilhada
> do time (ou versionado neste repo, em `dados/`).

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

> Os _Incoming Webhooks_ clássicos do Teams (Office 365 connectors) foram
> desativados pela Microsoft em maio de 2026. Fazer o envio pelo n8n contorna
> isso: o nó **Microsoft Teams** usa a API do Graph, não o connector antigo.

#### Montando o fluxo

1. Nó **Webhook** — método `POST`. Copie a **URL de produção**.
2. Em _Options_ do nó Webhook, preencha **Allowed Origins (CORS)** com a origem
   desta página (ex.: `https://mohamadkdb.github.io`, ou `*` para testar).
   Sem isso o navegador não lê a resposta e o painel não confirma a entrega.
3. Nó **Microsoft Teams** → _Send message_, mapeando o texto do passo anterior.
4. Ative o fluxo e cole a URL em _Configurar envio_ no painel.

#### O que o painel envia

```jsonc
{
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
