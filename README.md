# Visão do Time — Farol de Backlog

Painel de acompanhamento de demandas com **D.O.R**, **Status**, **D.O.D**, farol de risco
calculado automaticamente e comentários para reportar ao gestor.

É um arquivo único (`index.html`), sem build, sem dependências, sem servidor.
Basta abrir no navegador.

## Como usar

1. Abra o `index.html` (duplo clique, ou pelo GitHub Pages — veja abaixo).
2. Clique em qualquer linha da tabela para abrir o painel da demanda:
   checklists de D.O.R e D.O.D, bloqueio com motivo, datas, esforço e comentários.
3. **Resumo p/ gestor** gera um texto pronto, agrupado por farol, para colar no
   e-mail, Teams ou 1:1.
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

## Exportações

- **Salvar (.json)** — estado completo, para recarregar depois
- **CSV** — abre no Excel/Sheets, com farol e motivos já resolvidos em colunas
- **Imprimir** — layout limpo para PDF (esconde filtros e botões)
