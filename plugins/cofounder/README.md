# Cofounder

Um plugin para o [Claude Code](https://docs.anthropic.com/en/docs/claude-code) que atua como seu cofundador — guiando da ideia ao app publicado na internet, mesmo que você nunca tenha escrito uma linha de código.

[Click here for the English version](README.en.md)

## Antes de começar

Verifique se seu computador atende aos [requisitos de instalação](../../README.md#requisitos) antes de prosseguir.

## O que ele faz

Cofounder é um cofundador movido por IA que ajuda você a:

- **Descrever sua ideia** em linguagem simples e obter um documento estruturado de requisitos (PRD)
- **Construir um app web completo** (Go + React + PostgreSQL) com desenvolvimento guiado
- **Testar seu app** com testes automatizados de ponta a ponta via Playwright
- **Publicar na nuvem** na Locaweb Cloud com CI/CD via GitHub Actions

Ele cuida da configuração do ambiente, gerenciamento de dependências, fluxos do Git/GitHub, containers de banco de dados e deploy — explicando tudo em linguagem acessível ao longo do caminho.

## Instalação

Adicione o marketplace e instale o plugin:

```
/plugin marketplace add gmautner/marketplace
/plugin install cofounder
```

## Como usar

Após a instalação, crie um novo diretório para o projeto e inicie o Claude Code:

```bash
mkdir meu-app && cd meu-app
claude
```

Ative o cofounder no projeto:

```
/cofounder:install
```

Isso configura o agente cofounder como thread principal do projeto. A partir daí, toda sessão do Claude Code nesse projeto inicia automaticamente com o cofounder gerenciando seu ambiente, requisitos e fluxo de desenvolvimento.

A configuração é salva em `.claude/settings.json`, que você pode comitar no git para que todos os colaboradores tenham a mesma experiência (eles precisam ter o plugin cofounder instalado também).

O agente vai:

1. Configurar seu ambiente de desenvolvimento (devbox, podman, repositório GitHub)
2. Perguntar o que você quer construir
3. Criar um PRD, gerar tarefas e começar a desenvolver
4. Guiar você nos testes e no deploy

Basta descrever o que você quer com suas próprias palavras — nenhum conhecimento técnico necessário.

## Comandos

| Comando | Descrição |
|---------|-----------|
| `/cofounder:install` | Instala o cofounder como thread principal do projeto (recomendado) |
| `/cofounder:run` | Executa o agente cofounder uma vez sem instalar (avançado) |

## Skills incluídas

| Skill | Finalidade |
|-------|------------|
| `computer-setup` | Instala pré-requisitos (Homebrew/Scoop, mise, podman, GH CLI) |
| `pre-flight-check` | Valida pré-requisitos do ambiente |
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

Apache 2.0 — veja [LICENSE](../../LICENSE).
