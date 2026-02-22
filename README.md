# Cofounder

Um plugin para o [Claude Code](https://docs.anthropic.com/en/docs/claude-code) que atua como seu tech cofounder — guiando da ideia ao app publicado na internet, mesmo que você nunca tenha escrito uma linha de código.

[Click here for the English version](README.en.md)

## O que ele faz

Cofounder é um parceiro técnico movido por IA que ajuda você a:

- **Descrever sua ideia** em linguagem simples e obter um documento estruturado de requisitos (PRD)
- **Construir um app web completo** (Go + React + PostgreSQL) com desenvolvimento guiado
- **Testar seu app** com testes automatizados de ponta a ponta via Playwright
- **Publicar na nuvem** na Locaweb Cloud com CI/CD via GitHub Actions

Ele cuida da configuração do ambiente, gerenciamento de dependências, fluxos do Git/GitHub, containers de banco de dados e deploy — explicando tudo em linguagem acessível ao longo do caminho.

## Requisitos

- macOS ou Linux (WSL2 suportado no Windows)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) instalado e configurado

## Instalação

Adicione o marketplace e instale o plugin:

```
/plugin marketplace add gmautner/marketplace
/plugin install cofounder
```

## Como usar

Apos a instalacao, crie um novo diretorio para o projeto e inicie o Claude Code:

```bash
mkdir meu-app && cd meu-app
claude
```

O agente cofounder é ativado automaticamente. Ele vai:

1. Configurar seu ambiente de desenvolvimento (devbox, podman, repositorio GitHub)
2. Perguntar o que você quer construir
3. Criar um PRD, gerar tarefas e comecar a desenvolver
4. Guiar você nos testes e no deploy

Basta descrever o que você quer com suas proprias palavras — nenhum conhecimento técnico necessário.

## Skills incluídas

| Skill | Finalidade |
|-------|------------|
| `pre-flight-check` | Valida pre-requisitos do ambiente |
| `devbox-setup` | Ambiente de desenvolvimento isolado e reproduzivel via Nix |
| `podman-setup` | Runtime de containers para bancos de dados locais |
| `repo-setup` | Inicialização do repositório Git + GitHub |
| `github-account` | Orienta a criação de conta no GitHub |
| `tech-stack` | Desenvolvimento full-stack (Go, React, PostgreSQL) |
| `frontend-design` | Orientação de design UI/UX diferenciado |
| `webapp-testing` | Testes end-to-end com Playwright |
| `locaweb-cloud-deploy` | Deploy na infraestrutura da Locaweb Cloud |

## Stack

Aplicativos construídos com este plugin utilizam:

- **Backend:** Go stdlib (`net/http`), `pgx/v5`, `sqlc`
- **Frontend:** Vite + React + TypeScript, shadcn/ui, Tailwind CSS
- **Banco de dados:** PostgreSQL (via imagem Supabase Postgres com extensões)
- **Deploy:** Container Docker único, CI/CD com GitHub Actions

## Licença

Apache 2.0 — veja [LICENSE](LICENSE).
