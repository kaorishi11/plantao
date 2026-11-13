# PlantãoPS

Sistema web de organização do fluxo de pronto-socorro, desenvolvido com React, Vite, TypeScript e Supabase.

## Requisitos

- Node.js 20.19+ ou 22.12+
- npm
- Projeto no Supabase

## 1. Instalar dependências

```bash
npm install
```

## 2. Configurar o Supabase

1. Crie um projeto em https://supabase.com.
2. Abra **Project Settings > API**.
3. Copie a Project URL e a chave pública `anon`/publishable.
4. Duplique `.env.example` como `.env`.
5. Preencha `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`.

Nunca coloque `service_role` no frontend. A chave pública é protegida pelas políticas RLS.

## 3. Criar banco de dados

No painel Supabase, abra **SQL Editor** e execute o conteúdo de:

`supabase/migrations/001_initial_schema.sql`

Depois, opcionalmente, execute `supabase/seed.sql` para inserir leitos e medicamentos de demonstração.

## 4. Criar primeiro usuário

1. No Supabase, abra **Authentication > Users**.
2. Crie um usuário com e-mail e senha.
3. O trigger cria um perfil inicial como `recepcao`.
4. Para trocar o perfil inicial, execute no SQL Editor, substituindo o e-mail:

```sql
update public.profiles p
set role = 'gestao'
from auth.users u
where p.id = u.id
  and u.email = 'admin@hospital.com';
```

Perfis possíveis: `recepcao`, `enfermagem`, `medico`, `gestao`, `painel`.

Em produção, a criação e alteração de perfis deve ser restrita a administradores autorizados.

## 5. Executar

```bash
npm run dev
```

Abra o endereço informado pelo Vite, normalmente `http://localhost:5173`.

## 6. Gerar versão de produção

```bash
npm run build
npm run preview
```

Os arquivos finais ficam em `dist/`.

## Estado desta entrega

Esta primeira base inclui:

- Estrutura React + Vite + TypeScript.
- Login com Supabase Auth.
- Contexto de sessão e carregamento do perfil.
- Navegação e proteção de rotas por perfil.
- Identidade visual azul responsiva.
- Esquema SQL inicial para os módulos.
- RLS inicial.
- Regras SQL para transições de atendimento.
- RPC para senha diária, chamada concorrente de pacientes e ocupação atômica de leitos.
- Função didática de classificação de risco em TypeScript.

Os módulos operacionais ainda precisam ser implementados e testados por etapa. Não use dados reais de pacientes nesta versão inicial.

## Segurança e validação

- Não exponha a chave `service_role` no navegador.
- Revise as políticas RLS com testes para cada perfil antes de produção.
- Aplique autenticação forte, auditoria, backups e monitoramento.
- A classificação de risco apresentada é didática e não substitui protocolo oficial.
- Prescrição e dose máxima exigem catálogo farmacológico validado e validação no servidor.
- O sistema não é um dispositivo médico nem deve orientar decisões clínicas sem validação institucional.
