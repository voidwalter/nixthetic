#!/bin/bash

# colors
BLUE=$(gum style --foreground 33 --bold)
CYAN=$(gum style --foreground 39 --bold)
GREEN=$(gum style --foreground 76 --bold)
YELLOW=$(gum style --foreground 220 --bold)
RED=$(gum style --foreground 196 --bold)
RESET=$(gum style --foreground 7)

if (whoami != root); then
  echo "Try as root"
  exit 1
fi

echo "Alert: This script only support pacman."

PKG_MANAGER="pacman"
INSTALL_CMD="sudo pacman -Syu --noconfirm"
SEARCH_CMD="pacman -Ss"

# gum is installed?
if ! command -v gum &>/dev/null; then
  echo -e "${RED}gum is not installed!${RESET}"
  echo "Install it first: https://github.com/charmbracelet/gum"
  echo -e "${GREEN}Installing gum....${RESET}"
  $INSTALL_CMD gum
  echo "Run this script again..."
fi

header() {
  gum style \
    --foreground 39 --border-foreground 39 --border double \
    --align center --width 60 --margin "1 2" --padding "1 2" \
    "$1"
}

#  Main Menu
header "Package Installer"

CHOICE=$(
  gum choose \
    --height 10 \
    "Search & Install packages" \
    "Development Tools" \
    "Listed Packages" \
    "Quit" \
    --header "What would you like to do?" \
    --cursor.foreground="39" \
    --selected.foreground="39"
)

case "$CHOICE" in
"Quit")
  success "Bye!"
  exit 0
  ;;

"Search & Install packages")
  header "Package Search & Install"

  while true; do
    QUERY=$(gum input --placeholder "Type package name or part of it (empty to go back)" \
      --header "Search packages" \
      --width 60)

    [[ -z "$QUERY" ]] && break

    info "Searching for: ${YELLOW}${QUERY}${RESET}"

    RESULTS=$($SEARCH_CMD "$QUERY" 2>/dev/null | grep -v "^ " | head -n 60 | awk '{print $1}' | sort -u)

    if [[ -z "$RESULTS" ]]; then
      gum style --foreground 208 "No packages found matching '$QUERY'"
      continue
    fi

    SELECTED=$(gum choose --no-limit --height 18 \
      --header "Select packages to install (Space = select, Enter = confirm)" \
      $RESULTS)

    if [[ -z "$SELECTED" ]]; then
      info "Nothing selected."
      continue
    fi

    gum confirm --default=false \
      --affirmative "Install" \
      --negative "Cancel" \
      --timeout 30s \
      "Install these packages?

${GREEN}$(echo "$SELECTED" | tr '\n' ' ')${RESET}"

    if [[ $? -eq 0 ]]; then
      info "Installing selected packages..."
      echo "$SELECTED" | xargs $INSTALL_CMD
      success "Installation completed!"
    else
      info "Installation cancelled."
    fi
  done
  ;;

"Development Tools")
  header "Development Tools"

  DEV_TOOLS=(
    "git" "curl" "wget" "build-essential" "gcc" "g++" "make"
    "python3" "python3-pip" "python3-venv"
    "nodejs" "npm"
    "neovim" "vim" "nano"
    "htop" "jq" "tree" "bat" "fd-find" "ripgrep" "fzf"
    "tmux" "zsh"
    "docker.io" "docker-compose"
  )

  SELECTED=$(gum choose --no-limit --height 20 \
    --header "Select development tools to install (Space = toggle)" \
    "${DEV_TOOLS[@]}")

  if [[ -z "$SELECTED" ]]; then
    info "No tools selected."
    exit 0
  fi

  gum confirm --default=false \
    --affirmative "Install Now" \
    --negative "Cancel" \
    "Going to install:

${GREEN}$(echo "$SELECTED" | tr '\n' ' ')${RESET}"

  if [[ $? -eq 0 ]]; then
    echo "$SELECTED" | xargs $INSTALL_CMD
    success "Development tools installed!"
  else
    info "Cancelled."
  fi
  ;;

"Listed Packages")
  header "Listed Packages"

  #  If enyone seeing this script EDIT This Array with packages
  CUSTOM_PKGS=(
    "neovim" "tmux" "starship" "fastfetch" "btop" "bat" "fd-find" "ripgrep" "fzf"
    "lazygit" "bottom" "dust" "duf" "procs" "tokei" "exa" "lsd"
    "httpie" "jq" "yq" "glow"
    "python3-pip" "python3-venv"
    "docker.io" "docker-compose"
  )

  SELECTED=$(gum choose --no-limit --height 18 \
    --header "Your custom favorite packages" \
    "${CUSTOM_PKGS[@]}")

  if [[ -z "$SELECTED" ]]; then
    info "Nothing selected."
    exit 0
  fi

  gum confirm --default=false \
    --affirmative "Install" \
    --negative "Cancel" \
    "Install these custom packages?

${GREEN}$(echo "$SELECTED" | tr '\n' ' ')${RESET}"

  if [[ $? -eq 0 ]]; then
    echo "$SELECTED" | xargs $INSTALL_CMD
    success "Custom packages installed!"
  else
    info "Cancelled."
  fi
  ;;
esac
gum style --foreground 39 --bold --margin "1 2" "Done!"
