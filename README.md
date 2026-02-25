# Marketplace

Um marketplace de plugins para o [Claude Code](https://code.claude.com/docs/pt/overview).

[Click here for the English version](README.en.md)

## Requisitos

### macOS

1. Abra o Terminal e execute:

   ```
   xcode-select --install
   ```

   Isso instala o Git e outras ferramentas de linha de comando necessárias.

2. Instale o Claude:
   - [Claude Code Desktop](https://code.claude.com/docs/en/desktop-quickstart) (recomendado) — ou
   - [Claude Code](https://code.claude.com/docs/pt/overview) (linha de comando)

### Windows

1. Instale o [Claude Code Desktop](https://code.claude.com/docs/en/desktop-quickstart) (recomendado) ou o [Claude Code](https://code.claude.com/docs/pt/overview) (linha de comando).

2. Instale o Git: o Claude Code Desktop exibirá uma mensagem com um link para instalação do Git para Windows. Siga o link e aceite todas as opções padrão (o famoso Next/Next/.../Finish).

3. Habilite o WSL2 (Windows Subsystem for Linux):
   1. Abra o **PowerShell como Administrador**
   2. Execute `wsl --install`
   3. Reinicie o computador

   Após reiniciar, execute `wsl --status` e verifique se aparece "Default Version: 2". Em alguns casos pode ser necessário executar `wsl --install` e reiniciar o computador uma segunda vez.

## Instalação

<!-- [TODO] Adicionar instruções de instalação via Claude Code Desktop -->

```
/plugin marketplace add gmautner/marketplace
```

## Plugins disponíveis

| Plugin | Descrição |
|--------|-----------|
| [cofounder](plugins/cofounder/) | Um cofundador movido por IA que guia você da ideia ao app publicado na internet. Veja a [documentação do plugin](plugins/cofounder/) para instruções de instalação e uso. |

## Licença

Apache 2.0 — veja [LICENSE](LICENSE).
