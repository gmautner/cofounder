# Cofounder

Um plugin para o [Claude Code](https://docs.anthropic.com/en/docs/claude-code) que atua como seu cofundador — guiando da ideia ao app publicado na internet, mesmo que você nunca tenha escrito uma linha de código.

[Click here for the English version](README.en.md)

## Antes de começar

### macOS

1. Abra o Terminal e execute:

   ```
   xcode-select --install
   ```

   Isso instala o Git e outras ferramentas de linha de comando necessárias.

2. Instale o Claude:
   - [Claude Desktop](https://claude.com/download) (recomendado) — ou
   - [Claude Code](https://code.claude.com/docs/pt/overview) (linha de comando)

### Windows

1. Instale o [Claude Desktop](https://claude.com/download) (recomendado) ou o [Claude Code](https://code.claude.com/docs/pt/overview) (linha de comando).

2. Instale o Git: o Claude Code Desktop exibirá uma mensagem com um link para instalação do Git para Windows. Siga o link e aceite todas as opções padrão (o famoso Next/Next/.../Finish).

3. Habilite o WSL2 (Windows Subsystem for Linux):
   1. Abra o **PowerShell como Administrador**
   2. Execute `wsl --install`
   3. Reinicie o computador

   Após reiniciar, execute `wsl --status` e verifique se aparece "Default Version: 2". Em alguns casos pode ser necessário repetir o comando `wsl --install` e reiniciar o computador mais de uma vez.

## O que ele faz

Cofounder é um cofundador movido por IA que ajuda você a:

- **Descrever sua ideia** em linguagem simples e obter um documento estruturado de requisitos (PRD)
- **Construir um app web completo** (Go + React + PostgreSQL) com desenvolvimento guiado
- **Testar seu app** com testes automatizados de ponta a ponta via Playwright
- **Publicar na nuvem** na Locaweb Cloud com CI/CD via GitHub Actions

Ele cuida da configuração do ambiente, gerenciamento de dependências, fluxos do Git/GitHub, containers de banco de dados e deploy — explicando tudo em linguagem acessível ao longo do caminho.

## Instalação

### 🧑‍💻 Claude Desktop

1. Escolha o seletor Code (Command+3)
2. Abra a barra lateral
3. Clique em **Customize**
4. Clique em **Browse plugins**
5. Vá até a aba **Personal**
6. Clique em **+**
7. Selecione **Add marketplace from GitHub**
8. Cole a URL: `gmautner/marketplace`
9. Clique em **Sync**
10. Clique em **Cofounder**
11. Clique em **Install**

### ⌨️ Claude Code

Adicione o marketplace e instale o plugin:

```
/plugin marketplace add gmautner/marketplace
/plugin install cofounder
```

## Como usar

### 🧑‍💻 Claude Desktop

1. Escolha o seletor Code (Command+3)
2. Abra a barra lateral
3. Clique em **(+) New Session**
4. Clique na pasta abaixo da caixa de chat
5. Selecione **Choose a different folder**
6. Clique em **New Folder**
7. Escolha um nome para o projeto
8. Clique em **Open**
9. Na caixa de chat, digite `/cofounder:install`

### ⌨️ Claude Code

Crie um novo diretório para o projeto e inicie o Claude Code:

```bash
mkdir meu-app && cd meu-app
claude
```

Ative o cofounder no projeto:

```
/cofounder:install
```

## Demo

![Instalação e uso do Cofounder no Claude Desktop](demo.webp)

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
