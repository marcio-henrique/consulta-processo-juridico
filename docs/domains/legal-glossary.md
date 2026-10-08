# Domain: Legal glossary

> What the movement titles in the CSV mean in plain Portuguese, and how they are classified for the summary. Owner: Legal Expert agent. Based on the 183 distinct titles in the data (top titles listed here). **Review with a lawyer before relying on it for product copy.**

## 1. Context

The lawsuits are Brazilian civil cases at TJSP (state court), 1st instance, mostly small-value consumer claims (values between R$ 2.4k and R$ 40k). Many reach the appeals stage (Colégio Recursal / Tribunal de Justiça) and the enforcement phase.

Typical life of a case:

```
Filing and random assignment -> judge accepts the complaint -> defendant is summoned
-> defense -> plaintiff reply -> (hearing / evidence) -> ruling (sentença)
-> (appeal -> appeals-court judgment) -> final decision (trânsito em julgado)
-> (enforcement: collecting what was ordered) -> archived
```

## 2. Terms

| Term | Plain meaning |
|------|---------------|
| Autor / Requerente | Person who filed the lawsuit |
| Réu / Requerido | Person or company being sued |
| Petição inicial | The document that starts the lawsuit |
| Citação | Official notice to the defendant that they are being sued |
| Contestação | The defendant's written defense |
| Réplica | The plaintiff's answer to the defense |
| Despacho | Routine order from the judge; does not decide the dispute |
| Decisão | Judge's ruling on a specific point during the case |
| Sentença | Judge's final ruling in the first instance |
| Procedente / Improcedente | Claim accepted / rejected |
| Procedente em parte | Claim accepted only partly |
| Acordo / Transação | An agreement between the parties |
| Homologação | The judge officially approves something (e.g. an agreement) |
| Extinção do processo | The case ends |
| Apelação | An appeal against the first-instance ruling |
| Contrarrazões | The other side's reply to the appeal |
| Acórdão | Ruling issued by a panel of judges (appeals court) |
| Trânsito em julgado | The decision is final; no more appeals possible |
| Cumprimento de sentença / Execução | Phase to make the losing side do or pay what was ordered |
| Mandado de levantamento | Order to release money deposited in court to the person entitled |
| DJE | Official gazette where court acts are published |
| Intimação | Notice to a party or lawyer to do something or to know something |
| Conclusos | Case file sent to the judge for a decision |
| AR (aviso de recebimento) | Mail receipt proving a letter was delivered |
| Baixa | Case returns to the original court or is closed in the system |
| Arquivamento | Case is stored; no more activity expected |

## 3. Movement classification

`Movements::Classifier` matches the **title** (case-insensitive, accents folded) against these rules. First match wins. Counts are from the provided CSV.

### 3.1 Milestones (always in the summary)

| Title pattern (examples) | Count | Plain meaning |
|--------------------------|------:|---------------|
| `Distribuído Livremente`, `Distribuição por Sorteio` | 100 / 40 | Case filed and randomly assigned to a court (or, in appeals, to a judge) |
| `Recebida a Petição Inicial` | 43 | Judge accepted the complaint; defendant will be notified |
| `Contestação Juntada` | 93 | Defendant presented their defense |
| `Réplica Juntada` | 80 | Plaintiff answered the defense |
| `Designada Audiência de Conciliação`, `Audiência Realizada` (+ `Exitosa` / `Inexitosa`), `Audiência de Conciliação`, `Termo de Audiência` | 11 / 8 / 2 / 5 | A hearing was scheduled or took place. `Exitosa` = it ended in agreement; `Inexitosa` = no agreement was reached |
| `Pedido de Homologação de Acordo Juntado` | 10 | The parties asked the judge to approve an agreement |
| `Homologada a Transação de Acordo ExtraJudicial`, `Homologado o Acordo em Execução...` | 13 / 1 | Judge approved an agreement |
| `Julgada Procedente a Ação` | 35 | Judge decided in favor of the plaintiff |
| `Julgada Procedente em Parte` | 32 | Judge decided partly in favor of the plaintiff |
| `Julgada improcedente a ação` | 13 | Judge decided against the plaintiff |
| `Extinto o Processo sem Resolução do Mérito...` (desistência, ausência de condições/pressupostos) | 5 | Case ended without deciding who is right (e.g. plaintiff gave up, or a legal requirement was missing) |
| `Extinta a Execução/Cumprimento da Sentença pela Satisfação da Obrigação`, `Pedido de Extinção - Obrigação Satisfeita` | 29 / 8 | The enforcement phase ended because what was owed was paid |
| `Apelação/Razões Juntada` | 42 | An appeal was filed |
| `Contrarrazões Juntada` | 41 | Reply to the appeal was filed |
| `Acórdão registrado` | 41 | Appeals court issued its ruling |
| `Julgado virtualmente`, `Julgamento Virtual Iniciado` | 43 / 40 | Appeals judgment in a virtual session |
| `Trânsito em Julgado` (incl. `Certidão de Trânsito em Julgado com Baixa`) | 38 / 36 | Decision became final |
| `Execução/Cumprimento de Sentença Iniciada` | 37 | Phase to enforce the ruling started |
| `Pedido de Expedição de Mandado de Levantamento Juntado` | 43 | Request to release money deposited in court |
| `Arquivado Definitivamente`, `Baixa Definitiva` | 87 / 43 | Case archived / closed |
| `Proferidas Outras Decisões não Especificadas` | 131 | A decision was issued; the content has the text |
| `Termo de Audiência` (any) | - | A hearing took place |

### 3.2 Context (title + date, short content)

`Conclusos para Sentença` (85, case is about to be judged), `Conclusos para Decisão` (187), `Conclusos para Despacho` (360), `Petição Juntada` (289), `Juntada de petição`, `Documento Juntado`, `Carta Expedida` (86), `AR Positivo Juntado` (93, mail receipt), `Suspensão do Prazo` (61), `Prazo` (56), `Remetidos os Autos para o Tribunal de Justiça/Colégio Recursal` (41), `Recebidos os Autos do Tribunal de Justiça` (40), `Proferido Despacho de Mero Expediente` (101), and unknown titles.

### 3.3 Noise (collapsed into counts)

`Remetido ao DJE` (704), `Certidão de Publicação Expedida` (701), `Publicado em` (142), `Ato Ordinatório - Intimação - DJE` (147), `Certidão de Cartório Expedida` (239), `Expedido Certidão` (110), `Expedido Termo` (42), `Expedido Certidão de Baixa de Recurso` (40), `Processo Cadastrado` (41), `Processo encaminhado para a Distribuição de Recursos` (43), `Recebidos os Autos pela Entrada de Recursos` (41), `Conclusos para o Relator` (42), `Processo encaminhado para o Processamento de Grupos e Câmaras...` (39).

> Important exception: `Remetido ao DJE` is noise as an event, but in the provided data **all 704** `Teor do ato:` occurrences are under this title, and they carry the **text of the court's decision** (e.g. approval of an agreement, dismissal). When the content has a `Teor do ato`, the movement is promoted to `milestone` for its content. The cleaner extracts that text. Where the Teor text and a milestone movement describe the same decision (same date), the Teor text is the more informative source.

## 4. Plain-language writing guide for summaries

| Avoid | Prefer |
|-------|--------|
| "O feito foi julgado procedente" | "O juiz decidiu a favor de quem entrou com a ação" |
| "Homologou a transação" | "O juiz aprovou o acordo feito entre as partes" |
| "Trânsito em julgado" | "A decisão se tornou definitiva, sem possibilidade de recurso" |
| "Cumprimento de sentença" | "Fase em que se cobra o que a decisão determinou" |
| "Citação" | "Aviso oficial à parte processada" |
| "Conclusos para sentença" | "O processo foi enviado ao juiz para decisão final" |
| "Remetido ao DJE" | (omit; it is just a publication) |
| "Contestação" | "Defesa apresentada pela parte processada" |
| "Acórdão" | "Decisão de um grupo de juízes do tribunal" |
| "Apelação" | "Recurso para que o tribunal revise a decisão" |

## 5. Plain-language review checklist

Used by the Legal Expert and in [tune-llm-summary](../skills/tune-llm-summary.md).

- [ ] At most 3 paragraphs, no lists or headings.
- [ ] No Latin expressions or procedural jargon without explanation.
- [ ] Says who did what, in chronological order, in short sentences.
- [ ] States the current situation and the date of the latest movement.
- [ ] Does not say who "will win", what the user "should" do, or what happens next.
- [ ] Does not state facts absent from the data (reason for the lawsuit, amounts awarded, names not provided).
- [ ] Outcome words (procedente, improcedente, acordo) are translated correctly.
- [ ] No lawyer names or OAB numbers.
- [ ] Neutral tone; no emotion or blame.

## 6. Open questions for a lawyer

- Confirm the classification of `Proferidas Outras Decisões não Especificadas` (always a milestone?).
- Confirm that `Baixa Definitiva` in appeals means "case returned to the first instance" vs "closed".
- Confirm the plain wording for "Colégio Recursal" (suggestion: "turma de juízes que revisa decisões dos Juizados").
