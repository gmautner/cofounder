# Cofounder

Um plugin para o [Claude Code](https://docs.anthropic.com/en/docs/claude-code) que atua como seu tech cofounder — te guiando da ideia ao app publicado na internet, mesmo que voce nunca tenha escrito uma linha de codigo.

[Click here for the English version](README.en.md)

## O que ele faz

Cofounder e um parceiro tecnico movido por IA que te ajuda a:

- **Descrever sua ideia** em linguagem simples e obter um documento estruturado de requisitos (PRD)
- **Construir um app web completo** (Go + React + PostgreSQL) com desenvolvimento guiado
- **Testar seu app** com testes automatizados de ponta a ponta via Playwright
- **Publicar na nuvem** na Locaweb Cloud com CI/CD via GitHub Actions

Ele cuida da configuracao do ambiente, gerenciamento de dependencias, fluxos do Git/GitHub, containers de banco de dados e deploy — explicando tudo em linguagem acessivel ao longo do caminho.

## Requisitos

- macOS ou Linux (WSL2 suportado no Windows)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) instalado e configurado

## Instalacao

Adicione o marketplace e instale o plugin:

```
/plugin marketplace add gmautner/cofounder
/plugin install cofounder
```

## Como usar

Apos a instalacao, crie um novo diretorio para o projeto e inicie o Claude Code:

```bash
mkdir meu-app && cd meu-app
claude
```

O agente cofounder e ativado automaticamente. Ele vai:

1. Configurar seu ambiente de desenvolvimento (devbox, podman, repositorio GitHub)
2. Perguntar o que voce quer construir
3. Criar um PRD, gerar tarefas e comecar a desenvolver
4. Te guiar nos testes e no deploy

Basta descrever o que voce quer com suas proprias palavras — nenhum conhecimento tecnico necessario.

## Skills incluidas

| Skill | Finalidade |
|-------|------------|
| `pre-flight-check` | Valida pre-requisitos do ambiente |
| `devbox-setup` | Ambiente de desenvolvimento isolado e reproduzivel via Nix |
| `podman-setup` | Runtime de containers para bancos de dados locais |
| `repo-setup` | Inicializacao do repositorio Git + GitHub |
| `github-account` | Orienta a criacao de conta no GitHub |
| `tech-stack` | Desenvolvimento full-stack (Go, React, PostgreSQL) |
| `frontend-design` | Orientacao de design UI/UX diferenciado |
| `webapp-testing` | Testes end-to-end com Playwright |
| `locaweb-cloud-deploy` | Deploy na infraestrutura da Locaweb Cloud |

## Stack tecnologica

Aplicacoes construidas com este plugin utilizam:

- **Backend:** Go stdlib (`net/http`), `pgx/v5`, `sqlc`
- **Frontend:** Vite + React + TypeScript, shadcn/ui, Tailwind CSS
- **Banco de dados:** PostgreSQL (via imagem Supabase Postgres com extensoes)
- **Deploy:** Container Docker unico, CI/CD com GitHub Actions

## Licenca

Apache 2.0 — veja [LICENSE](LICENSE).
