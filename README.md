# devterm-windows

O [devterm](https://github.com/skaisser/devterm) (de skaisser) adaptado para **Windows**: Windows Terminal + Ubuntu no WSL2, com o mesmo zsh, prompt Oh My Posh, cores skaisser, plugins, atalhos e Claude Code.

## Instalar

1. Abra o **PowerShell como administrador** (Iniciar > digite "PowerShell" > botão direito > *Executar como administrador*).
2. Cole e aperte Enter:
   ```powershell
   irm https://raw.githubusercontent.com/destravatech1/devterm-windows/main/install.ps1 | iex
   ```
   Ou, se a pasta já estiver no computador:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```
3. Na primeira vez, o Windows instala o WSL2 e pede para **reiniciar**. Depois de entrar de novo, a instalação continua sozinha.
4. O Ubuntu abre uma vez para você criar **usuário e senha**. Depois digite `exit`.
5. O instalador termina a parte Linux (pede a senha do Ubuntu uma vez).
6. Abra o **Windows Terminal**: o perfil **devterm (Ubuntu)** já é o padrão.

Pode rodar de novo quando quiser: só instala o que falta.

## O que instala

| No Windows | No Ubuntu (WSL2) |
|---|---|
| Windows Terminal | zsh como shell padrão |
| PowerShell 7 | Oh My Posh + tema skaisser |
| Git | Plugins: autosuggestions, syntax highlighting, history search, completions |
| Fonte MesloLGS Nerd Font | 50+ atalhos do devterm (git, navegação, sistema) |
| Perfil "devterm (Ubuntu)" com as cores skaisser | Cor de fundo diferente por janela e **vermelha no SSH** |
| | fzf, tree, jq, eza (quando disponível) |
| | Node.js LTS (nvm) e **Claude Code** com a barra de status |

## Diferenças para o devterm do Mac

- A cor da **aba** não muda (o Windows Terminal não aceita isso por comando); a cor de fundo da janela muda.
- Os atalhos do Laravel Herd não funcionam (o Herd é só para Mac).
- Seus arquivos do Windows ficam em `/mnt/c/Users/<você>` dentro do Ubuntu. Para projetos, prefira guardar dentro do Ubuntu (`~/`), que é bem mais rápido.

## Créditos

Baseado no [devterm](https://github.com/skaisser/devterm), de skaisser, licença Apache 2.0. Veja `NOTICE`.
