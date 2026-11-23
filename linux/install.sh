#!/usr/bin/env bash
# devterm-windows — parte Linux (roda DENTRO do Ubuntu no WSL2)
# Adaptação do devterm (https://github.com/skaisser/devterm, Apache 2.0) para WSL.
# Pode rodar de novo quantas vezes quiser: só instala o que falta.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ok()   { printf '\033[32m✔\033[0m %s\n' "$*"; }
info() { printf '\033[36m➜\033[0m %s\n' "$*"; }
err()  { printf '\033[31m✖\033[0m %s\n' "$*"; FALHAS+=("$*"); }
FALHAS=()

info "Pacotes do sistema (pede a senha do Ubuntu)"
sudo apt-get update -y >/dev/null
sudo apt-get install -y zsh git curl wget unzip fzf tree jq build-essential ca-certificates >/dev/null && ok "zsh, git, curl, fzf, tree, jq" || err "apt-get"
sudo apt-get install -y eza >/dev/null 2>&1 && ok "eza" || info "eza não está no apt desta versão do Ubuntu (o ls normal continua funcionando)"

info "Oh My Posh + tema skaisser"
mkdir -p "$HOME/.local/bin" "$HOME/.zsh/themes"
if ! command -v oh-my-posh >/dev/null && [[ ! -x "$HOME/.local/bin/oh-my-posh" ]]; then
  curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin" >/dev/null && ok "Oh My Posh" || err "Oh My Posh"
else ok "Oh My Posh já instalado"; fi
cp "$DIR/assets/skaisser.omp.json" "$HOME/.zsh/themes/skaisser.omp.json" && ok "tema skaisser"

info "Plugins do zsh"
mkdir -p "$HOME/.zsh/plugins"
for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-history-substring-search zsh-users/zsh-completions zdharma-continuum/fast-syntax-highlighting; do
  nome="${repo#*/}"
  if [[ -d "$HOME/.zsh/plugins/$nome" ]]; then ok "$nome já instalado"
  else git clone --depth 1 "https://github.com/$repo.git" "$HOME/.zsh/plugins/$nome" >/dev/null 2>&1 && ok "$nome" || err "$nome"; fi
done

info "Configuração do zsh (.zshrc)"
if [[ -f "$HOME/.zshrc" ]] && ! cmp -s "$HOME/.zshrc" "$DIR/assets/zshrc.wsl"; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup-$(date +%Y%m%d-%H%M%S)" && info "o .zshrc antigo foi guardado como backup"
fi
cp "$DIR/assets/zshrc.wsl" "$HOME/.zshrc" && ok ".zshrc"
[[ -f "$HOME/.zshrc.local" ]] || cp "$DIR/assets/zshrc.local.example" "$HOME/.zshrc.local"

info "Node.js (nvm, versão LTS)"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash >/dev/null 2>&1 || err "nvm"
fi
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" && { nvm install --lts >/dev/null 2>&1 && ok "Node $(node -v)" || err "Node LTS"; }

info "Claude Code (instalador oficial)"
if command -v claude >/dev/null || [[ -x "$HOME/.local/bin/claude" ]]; then ok "Claude Code já instalado"
else curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1 && ok "Claude Code" || err "Claude Code"; fi

info "Barra de status do Claude Code"
mkdir -p "$HOME/.claude"
cp "$DIR/assets/statusline.sh" "$HOME/.claude/statusline.sh" && chmod +x "$HOME/.claude/statusline.sh"
S="$HOME/.claude/settings.json"
if [[ ! -f "$S" ]]; then
  printf '{\n  "statusLine": { "type": "command", "command": "$HOME/.claude/statusline.sh" }\n}\n' > "$S" && ok "statusline ligada"
elif ! grep -q statusLine "$S"; then
  cp "$S" "$S.backup-$(date +%Y%m%d-%H%M%S)"
  jq '. + {statusLine:{type:"command",command:"$HOME/.claude/statusline.sh"}}' "$S" > "$S.tmp" && mv "$S.tmp" "$S" && ok "statusline ligada"
else ok "statusline já configurada"; fi

info "zsh como shell padrão"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
  sudo chsh -s "$(command -v zsh)" "$USER" && ok "zsh é o padrão" || err "chsh"
else ok "zsh já é o padrão"; fi

echo
if (( ${#FALHAS[@]} )); then
  printf '\033[33mTerminou com %d falha(s):\033[0m\n' "${#FALHAS[@]}"; printf '  - %s\n' "${FALHAS[@]}"
  echo "Rode de novo para tentar só o que faltou."
else
  printf '\033[32mTudo pronto!\033[0m Feche e abra o Windows Terminal.\n'
fi
