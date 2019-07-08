#!/bin/bash -eux

# This script installs VSCode with a custom configuration for technical writing (Markdown).
# Supports macOS and Ubuntu
# Dependencies: git, curl, bash and homebrew (macOS)
# Usage: ./setup.sh

set -euo pipefail

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
#COL_RED=$ESC_SEQ"31;01m"
#COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"

# Functions
greeter() {
    echo
    echo -en "${COL_GREEN} VSCode setup script ${COL_RESET}\n"
    echo "Works on macOS and Ubuntu"
    echo "This script will install and setup VSCode"
    echo
    echo "Dependencies: sudo, git, curl"
    echo
}

ubuntu() {
    echo "Checking if VSCode is already installed"
    if ! dpkg-query -W -f='${Status}' code | grep -q "ok installed"; then
        echo -en "${COL_YELLOW} ==> Installing Visual Studio Code ${COL_RESET}\n"
        sudo snap install --classic code
        echo ""
    fi
    echo -en "${COL_YELLOW}Checking if Node is installed${COL_RESET}\n"
    if ! dpkg-query -W -f='${Status}' node | grep -q "ok installed"; then
        echo -en "${COL_YELLOW} ==> Installing Node ${COL_RESET}\n"
        sudo snap install node --channel=10/stable --classic
        echo ""
    fi
        echo -en "${COL_YELLOW}Checking for Hunspell${COL_RESET}\n"
    if ! dpkg-query -W -f='${Status}' hunspell | grep -q "ok installed"; then
        sudo apt install -y hunspell
    fi
    echo -en "${COL_YELLOW}Installing FiraCode Font${COL_RESET}\n"
    sudo apt install -y -qq fonts-firacode
    echo ""
    echo -en "${COL_YELLOW}Installing Vale${COL_RESET}\n"
    sudo curl -sfL https://install.goreleaser.com/github.com/ValeLint/vale.sh | sudo bash -s -- -b /usr/local/bin
    echo ""
    echo "Setting path for node"
    echo "export PATH="$PATH:/$HOME/node_modules/.bin"" >> ~/.bashrc
    echo ""
    echo "Downloading VSCode settings"
    wget https://gist.githubusercontent.com/ocular-d/cda72372a8168f0711700d417fa8a13e/raw/5f23d12b395dd62d271c02e5ee3af26a000c06c7/settings.json -O /"$HOME"/.config/Code/User/settings.json
}
# Check if Homebrew is installed, install if we don't have it, update if we do
homebrew() {

    # $() is for command substitution, commands don't _return_ values, they _capture_ them
    # more here: https://stackoverflow.com/a/12137501/890814
    # [[ ]] is the newer _test command_ for evaluations, is more literal
    # more here: http://mywiki.wooledge.org/BashFAQ/031
    # the double [[ ]], and $() is important
    # `command -v brew` will output nothing if Homebrew is not installed
    if [[ $(command -v brew) == "" ]]; then
        echo "Installing X-Code"
        xcode-select --install
        echo "Installing Homebrew.. "
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        echo "Updating Homebrew..."
        brew update
    fi
}

# NPM install dependencies
npm_modules() {
    npm install remark-cli remark-preset-lint-recommended
    npm install remark-preset-lint-consistent remark-validate-links
    npm install remark-preset-lint-markdown-style-guide
}

# Determine if we are on macOS or Linux
initOS() {
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    case "$OS" in
    darwin) OS='darwin' ;;
    linux) OS='linux' ;;
    *)
        echo -en "${COL_RED} OS ${OS} is not supported by this installation script ${COL_RESET}\n"
        exit 1
        ;;
    esac
}

extensions() {
    echo
    echo " ==> Installing VSCode extensions"
    code --install-extension pnp.polacode
    code --install-extension bierner.markdown-emoji
    code --install-extension AlanWalk.markdown-toc
    code --install-extension CoenraadS.bracket-pair-colorizer
    code --install-extension streetsidesoftware.code-spell-checker
    code --install-extension ms-vscode.wordcount
    code --install-extension ybaumes.highlight-trailing-white-spaces
    code --install-extension myh.preview-vscode
    code --install-extension mrmlnc.vscode-remark
    code --install-extension swyphcosmo.spellchecker
    code --install-extension johnpapa.read-time
    code --install-extension vincaslt.highlight-matching-tag
    code --install-extension PKief.material-icon-theme
    code --install-extension Hyzeta.vscode-theme-github-light
    code --install-extension eamodio.gitlens
    code --install-extension drewbourne.vscode-remark-lint
    code --install-extension testthedocs.vale
}

# Run the functions
# 1. The greeter
greeter

# 2.Identify platform based on uname output
initOS

# 3. Find out which OS and run steps according to the OS.
# Find out which Linux you are on, currently we only support Ubuntu
if [ "$OS" = "linux" ]; then
    LD=$(lsb_release -is)
    if [ "$LD" != "Ubuntu" ]; then
        echo -en "${COL_RED} Can not detect Ubuntu as OS, stopping now ${COL_RESET}\n"
        exit 0
    fi
    if [ "$LD" = "Ubuntu" ]; then
        # Prepare Ubuntu
        echo
        echo "Looks like you are using Ubuntu, great !"
        echo
        ubuntu
    fi
fi

# Run setup on macOS
if [ "$OS" = "darwin" ]; then
    # RUN
    echo "Looks like you are on macOS"
    # Homebrew
    echo
    echo "=> Checking for homebrew"
    homebrew
    echo
    echo "Checking for dependencies"
    brew list --verbose hunspell || brew install hunspell
    brew list --verbose vale || brew tap ValeLint/vale && brew install vale
    brew list --verbose node || brew install node
    echo
    # Install VSCode
    echo "Installing VSCode"
    brew list -- verbose visual-studio-code || brew cask install visual-studio-code
    echo ""
    echo "Installing FiraCode Font"
    brew tap homebrew/cask-fonts
    brew cask install font-fira-code
    echo ""
    echo "Downloading VSCode settings"
    wget https://gist.githubusercontent.com/ocular-d/cda72372a8168f0711700d417fa8a13e/raw/5f23d12b395dd62d271c02e5ee3af26a000c06c7/settings.json -O /"$HOME"/Library/Application Support/Code/User
    echo ""
    mac_code_cli
fi

mac_code_cli(){
echo "Setting path for commandline"
cat <<EOF >> ~/.bash_profile
# Add Visual Studio Code (code)
export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
EOF
echo ""
}

# Same steps for every OS.
# 4. Install NPM modules
npm_modules

# 5. Install VSCode extensions
extensions

exit 0