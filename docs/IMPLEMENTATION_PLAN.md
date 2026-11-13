# Plano de implementação funcional

## Fase 1 — Fundação
- [x] React + Vite + TypeScript
- [x] Supabase Auth
- [x] Perfis e rotas protegidas
- [x] Estrutura visual responsiva
- [x] Esquema inicial PostgreSQL e RLS

## Fase 2 — Recepção
- [ ] Busca por nome e nascimento
- [ ] Cadastro e alergias
- [ ] Abertura de atendimento via RPC
- [ ] Lista de atendimentos do dia

## Fase 3 — Enfermagem
- [ ] Formulário de sinais vitais
- [ ] Sugestão de risco e confirmação
- [ ] Justificativa obrigatória para alteração
- [ ] Reclassificação com histórico
- [ ] Fila priorizada e alertas de prazo

## Fase 4 — Médico
- [ ] RPC de chamada com consultório
- [ ] Histórico e evolução
- [ ] Prescrição com validação server-side de alergia e dose
- [ ] Destino e transições autorizadas

## Fase 5 — Leitos e painel
- [ ] Planta visual de alas
- [ ] Atribuição concorrente segura
- [ ] Limpeza e liberação
- [ ] Painel público sem nome do paciente

## Fase 6 — Gestão
- [ ] Indicadores SQL por período
- [ ] Distribuição por risco
- [ ] Espera média versus prazo
- [ ] Percentual fora do prazo
- [ ] Ocupação de leitos

## Observação técnica
A função `call_next_patient` deve ser revisada para que o desempate etário siga exatamente o requisito: idade como critério após a cor e o tempo de espera. Também deve ser criado um mecanismo para a chamada do painel sem expor dados clínicos. As políticas RLS deste esqueleto são uma base inicial e precisam de revisão de segurança antes do uso real.
