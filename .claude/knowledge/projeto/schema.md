# Schema do Banco — SGS (68 tabelas)

Schema completo em: `C:\Users\DELL\sgs\notes\notas\schema.sql`

## Hierarquia principal
```
empresas → unidades → setores → funcoes → funcionarios
                                    ↓
                            setor_riscos → funcao_riscos → funcionario_riscos
```

## Grupos de tabelas

### Cadastro Base
| Tabela | Campos principais |
|---|---|
| `empresas` | razao_social, cnpj_raiz, grau_risco, tipo_empresa, empresa_mae_id, owner_id |
| `unidades` | empresa_id, nome_unidade, cnpj_completo, tipo, grau_risco, sesmt_centralizado |
| `setores` | nome_setor, empresa_id, tem_agente_fisico/quimico/biologico/ergonomico/acidente/psicossocial |
| `funcoes` | nome_funcao, cbo, empresa_id, trabalho_altura/confinado/eletrico/insalubre/periculoso |
| `funcao_setores` | vínculo N:N funcao ↔ setor |
| `funcionarios` | nome_completo, cpf, empresa_id, setor_id, funcao_id, data_admissao, pis_pasep |
| `historico_contrato` | eventos admissão/transferência/demissão |
| `cbo` | tabela CBO completa |

### SaaS / Comercial
| Tabela | Campos principais |
|---|---|
| `planos` | limite_empresas, limite_funcionarios, numero_usuarios, tem_esocial, valor_mensal |
| `assinaturas` | user_id, plano_id, status (Free/Ativo/Suspenso/Cancelado/Trial/Enterprise) |
| `usuarios` | email, cliente_id, perfil, pode_gerar_documentos |
| `usuario_permissoes` | usuario_id, empresa_id, modulo, nivel_acesso |
| `log_acessos` | auditoria |

### Riscos (núcleo do PGR)
| Tabela | Campos principais |
|---|---|
| `categorias_risco` | Físico, Químico, Biológico, Ergonômico, Acidente, Psicossocial |
| `riscos` | nome_risco, categoria_risco_id, danos_saude, codigo_tabela24_esocial |
| `perigos` | nome, descricao, categoria_risco_id |
| `perigo_riscos` | vínculo N:N perigo ↔ risco |
| `setor_riscos` | setor_id, risco_id, perigo_id, probabilidade, severidade, nivel_risco, medida_elim/subs/eng/adm/epi + _desc + _responsavel + _prazo |
| `funcao_riscos` | funcao_id, risco_id, propagado_do_setor, origem_campanha_id |
| `setor_risco_medidas` | EPIs vinculados por setor_risco (nivel=EPI) |
| `funcao_risco_medidas` | EPIs vinculados por funcao_risco |
| `funcionario_riscos` | riscos individuais |

### EPIs
| Tabela | Campos principais |
|---|---|
| `catalogo_epis` | nome, categoria, CA, fabricante, validade_ca |
| `ca_epi` | ~96k registros MTE — numero_ca, nome_equipamento, situacao, data_validade |
| `epi_entregas` | funcionario_id, epi_id, data_entrega, devolvido |

### Psicossocial
| Tabela | Campos principais |
|---|---|
| `campanhas_psicossocial` | empresa_id, metodologia (COPSOQ-III / COPSOQ-III-Media / Checklist-NR01), status |
| `campanha_funcoes` | token de acesso por função, total_respondentes |
| `respostas_copsoq` | d01-d23 (curta) ou respostas_json JSONB q01-q76 (média), modo_entrada |
| `resultados_copsoq` | scores por dimensão, resultados_json |
| `checklist_nr01_respostas` | respostas JSONB B1F1..B8F3 |
| `checklist_nr01_resultados` | médias por fator, integrado_inventario |

### eSocial
| Tabela | Campos principais |
|---|---|
| `esocial_s2220` | ASO por funcionário — tipo_aso, data_aso, resultado |
| `esocial_s2220_exames` | exames dentro do ASO |
| `esocial_s2240` | exposição a agentes nocivos |
| `acidentes_trabalho` | CAT, afastamento, óbito, status_esocial |

### Outros módulos
| Tabela | Finalidade |
|---|---|
| `acoes` | plano de ação — titulo, prioridade, status, prazo, origem |
| `acoes_historico` | histórico de status e comentários |
| `catalogo_treinamentos` | nr_relacionada, carga_horaria |
| `funcionario_treinamentos` | realizações com vencimento |
| `catalogo_exames` | codigo_tabela27_esocial |
| `funcionario_documentos` | ASO, laudos, arquivo_url |
| `catalogo_checklists` + `inspecoes` | inspeções com % conformidade |
| `equipamentos_seg` | NR-12, proxima_inspecao |
| `permissoes_trabalho` | PT Abertas/Fechadas |
| `medicoes_ambientais` | valor_medido, gera_insalubridade |
| `ghe_nomes` | nomes customizados de GHE (pouco usado) |

## Triggers importantes
- `trg_novo_usuario`: `AFTER INSERT OR UPDATE ON auth.users` → cria plano Free
- `atualizar_total_respondentes_checklist`: SECURITY DEFINER (RLS bypass necessário)
