# Planos e Negócio — SGS

## Modelo de negócio
Freemium SaaS para técnicos e consultores de SST. Nenhum concorrente tem plano gratuito permanente — esse é o principal diferencial.

## Tabela de planos (vigente desde 2026-05-09)
| Plano | Preço | Empresas | Funcionários | Usuários | eSocial |
|---|---|---|---|---|---|
| Free | R$0 | 2 | 25 | 1 | Não |
| Starter | R$79/mês | 8 | 120 | 2 | Sim |
| Pro | R$279/mês | 15 | 300 | 3 | Sim |
| Business | R$549/mês | 60 | 1.500 | ilimitado | Sim |
| Enterprise | R$949/mês | ilimitado | ilimitado | ilimitado | Sim |

## Racional de preços
- **Free:** pequeno demais para operar consultoria real, suficiente para testar
- **Starter R$79:** captura técnicos solo que faturam R$300-600/mês por cliente
- **Pro R$279:** R$20 abaixo do Bevart (R$299)
- **Business R$549:** abaixo do Bevart Ilimitado (R$799)
- **Enterprise R$949:** abaixo do mercado "sob consulta" (~R$1.200-2.000)

## Concorrentes
| Concorrente | Plano | Preço | Limite |
|---|---|---|---|
| Indexmed | Premium | R$199/mês | 500 funcionários |
| Indexmed | Pro | R$409/mês | 1.000 funcionários |
| Bevart | Plano 400 | R$299/mês | 400 funcionários |
| Bevart | Ilimitado | R$799/mês | ilimitado |
| Sistema Metra | — | sob consulta | ilimitado |
| Sistema ESO | — | sob consulta | — |

## Implementação técnica
- `planos` tem: limite_empresas, limite_funcionarios, numero_usuarios, tem_esocial, valor_mensal
- `assinaturas` status: Free, Ativo, Suspenso, Cancelado, Trial (legado), Enterprise
- Trigger `trg_novo_usuario`: AFTER INSERT OR UPDATE ON auth.users → cria plano Free
- SUPERADMIN: sgs.gestaosst@gmail.com — bypassa TUDO
- Verificação de limites: SEMPRE via `plano_utils.js` — nunca hardcodar
