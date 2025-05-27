#!/bin/bash
clear

# -----------------------------------------------------
# Repository
# -----------------------------------------------------
repo="Empester/gentoo-dotfiles"

# -----------------------------------------------------
# Download Folder
# -----------------------------------------------------
download_folder="$HOME/.ml4w"

# Create download_folder if not exists
if [ ! -d $download_folder ]; then
    mkdir -p $download_folder
fi

# Get latest tag from GitHub
get_latest_release() {
    curl --silent "https://api.github.com/repos/$repo/releases/latest" | # Get latest release from GitHub api
        grep '"tag_name":' |                                             # Get tag line
        sed -E 's/.*"([^"]+)".*/\1/'                                     # Pluck JSON value
}

# Get latest zip from GitHub
get_latest_zip() {
    curl --silent "https://api.github.com/repos/$repo/releases/latest" | # Get latest release from GitHub api
        grep '"zipball_url":' |                                          # Get tag line
        sed -E 's/.*"([^"]+)".*/\1/'                                     # Pluck JSON value
}

# Check if package is installed
_isInstalled() {
    package="$1"

    # Ensure gentoolkit is installed
    if ! command -v equery &> /dev/null; then
        echo "gentoolkit not found. Installing..."
        sudo emerge --quiet app-portage/gentoolkit || {
            echo "Failed to install gentoolkit"
            echo 1
            return
        }
    fi

    check="$(equery list -i "${package}" 2>/dev/null | grep -E "^\\[I\\].*${package}")"
    if [ -n "${check}" ]; then
        echo 0 #'0' means 'true' in Bash
        return
    fi
    echo 1 #'1' means 'false' in Bash
    return
}

# Check if command exists
_checkCommandExists() {
    package="$1"
    if ! command -v "$package" >/dev/null; then
        return 1
    else
        return 0
    fi
}

# Check if package is installed (Gentoo version)
_isInstalled() {
    package="$1"

    # Ensure gentoolkit is installed
    if ! command -v equery &> /dev/null; then
        echo "gentoolkit not found. Installing..."
        sudo emerge --quiet app-portage/gentoolkit || {
            echo "Failed to install gentoolkit"
            echo 1
            return
        }
    fi

    check="$(equery list -i "${package}" 2>/dev/null | grep -E "^\[I\].*${package}")"
    if [ -n "${check}" ]; then
        echo 0
        return
    fi
    echo 1
    return
}

# Install required packages (Gentoo version)
_installPackages() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        toInstall+=("${pkg}")
    done
    if [[ "${#toInstall[@]}" -eq 0 ]]; then
        return
    fi
    printf "Package(s) not installed:\n%s\n" "${toInstall[@]}"
    sudo emerge --quiet "${toInstall[@]}"
}

# # install yay if needed
# _installYay() {
#     _installPackages "base-devel"
#     SCRIPT=$(realpath "$0")
#     temp_path=$(dirname "$SCRIPT")
#     git clone https://aur.archlinux.org/yay.git $download_folder/yay
#     cd $download_folder/yay
#     makepkg -si
#     cd $temp_path
#     echo ":: yay has been installed successfully."
# }

# Required packages for the installer
packages=(
    "gui-wm/hyprland"
    "net-misc/wget"
    "app-arch/unzip"
    "net-misc/rsync"
    "dev-vcs/git"
)

latest_version=$(get_latest_release)

# Some colors
GREEN='\033[0;32m'
NONE='\033[0m'

# Header
echo -e "${GREEN}"
cat <<"EOF"
   ____         __       ____
  /  _/__  ___ / /____ _/ / /__ ____
 _/ // _ \(_-</ __/ _ `/ / / -_) __/
/___/_//_/___/\__/\_,_/_/_/\__/_/

EOF
echo "ML4W Dotfiles for Hyprland"
echo -e "${NONE}"
while true; do
    read -p "DO YOU WANT TO START THE INSTALLATION NOW? (Yy/Nn): " yn
    case $yn in
        [Yy]*)
            echo ":: Installation started."
            echo
            break
            ;;
        [Nn]*)
            echo ":: Installation canceled"
            exit
            break
            ;;
        *)
            echo ":: Please answer yes or no."
            ;;
    esac
done

# Create Download folder if not exists
if [ ! -d $download_folder ]; then
    mkdir -p $download_folder
    echo ":: $download_folder folder created"
fi

# Remove existing download folder and zip files
if [ -f $download_folder/dotfiles-main.zip ]; then
    rm $download_folder/dotfiles-main.zip
fi
if [ -f $download_folder/dotfiles-dev.zip ]; then
    rm $download_folder/dotfiles-dev.zip
fi
if [ -f $download_folder/dotfiles.zip ]; then
    rm $download_folder/dotfiles.zip
fi
if [ -d $download_folder/dotfiles ]; then
    rm -rf $download_folder/dotfiles
fi
if [ -d $download_folder/dotfiles_temp ]; then
    rm -rf $download_folder/dotfiles_temp
fi
if [ -d $download_folder/dotfiles-main ]; then
    rm -rf $download_folder/dotfiles-main
fi
if [ -d $download_folder/dotfiles-dev ]; then
    rm -rf $download_folder/dotfiles-dev
fi

# Synchronizing package databases
sudo emerge --sync
echo

# Install gentoolkit if not already installed (needed for equery)
if ! command -v equery >/dev/null; then
    echo ":: Installing gentoolkit (required for checking packages)..."
    sudo emerge --noreplace app-portage/gentoolkit
fi

# Install required packages
echo ":: Checking that required packages are installed..."
_installPackages "${packages[@]}"

echo

#!/bin/bash

# Variables from PKGBUILD
pkgname='ml4w-hyprland'
pkgver='2.9.8.6'
srcurl="https://github.com/empester/gentoo-dotfiles/archive/refs/tags/${pkgver}.tar.gz"
tmpdir="/tmp/${pkgname}-${pkgver}-install"
installprefix="/usr"

# Select the dotfiles version
echo "Please choose between: "
echo "- ML4W Dotfiles for Hyprland $pkgver (latest stable release)"
echo "- ML4W Dotfiles for Hyprland Rolling Release (main branch including the latest commits)"
echo

# version=$(gum choose "main-release" "rolling-release" "CANCEL")

if [ "$version" == "main-release" ]; then
    echo ":: Installing Main Release"

    # Prepare temp directory
    rm -rf "$tmpdir"
    mkdir -p "$tmpdir"

    echo ":: Downloading source tarball..."
    wget -qO "$tmpdir/${pkgname}.tar.gz" "$srcurl" || {
        echo ":: ERROR: Failed to download source."
        exit 1
    }

    echo ":: Extracting files..."
    tar -xzf "$tmpdir/${pkgname}.tar.gz" -C "$tmpdir" --strip-components=1 || {
        echo ":: ERROR: Failed to extract source."
        exit 1
    }

    echo ":: Installing files..."

    # Copy share files
    sudo install -dm 755 "${installprefix}/share/${pkgname}"
    sudo cp -r "$tmpdir/share/." "${installprefix}/share/${pkgname}/"

    # Copy lib files
    sudo install -dm 755 "${installprefix}/lib/${pkgname}"
    sudo cp -r "$tmpdir/lib/." "${installprefix}/lib/${pkgname}/"

    # Copy binary
    sudo install -Dm 755 "$tmpdir/bin/ml4w-hyprland-setup" "${installprefix}/bin/ml4w-hyprland-setup"

    # Copy license
    sudo install -Dm 644 "$tmpdir/LICENSE" "${installprefix}/share/licenses/${pkgname}/LICENSE"

    # Copy documentation
    sudo install -Dm 644 "$tmpdir/README.md" "${installprefix}/share/doc/${pkgname}/README.md"

    echo ":: Installation done."

elif [ "$version" == "rolling-release" ]; then
    echo ":: Installing Rolling Release"

    # Clone rolling release repo (main branch latest)
    repodir="$HOME/ml4w-hyprland-rolling"

    if [ -d "$repodir" ]; then
        echo ":: Updating existing repo..."
        git -C "$repodir" pull || {
            echo ":: ERROR: Failed to update repo."
            exit 1
        }
    else
        echo ":: Cloning rolling release repo..."
        git clone https://github.com/empester/gentoo-dotfiles.git "$repodir" || {
            echo ":: ERROR: Failed to clone repo."
            exit 1
        }
    fi

    # Install from rolling repo similar to main release
    echo ":: Installing files from rolling release repo..."

    sudo install -dm 755 "${installprefix}/share/${pkgname}"
    sudo cp -r "$repodir/share/." "${installprefix}/share/${pkgname}/"

    sudo install -dm 755 "${installprefix}/lib/${pkgname}"
    sudo cp -r "$repodir/lib/." "${installprefix}/lib/${pkgname}/"

    sudo install -Dm 755 "$repodir/bin/ml4w-hyprland-setup" "${installprefix}/bin/ml4w-hyprland-setup"

    sudo install -Dm 644 "$repodir/LICENSE" "${installprefix}/share/licenses/${pkgname}/LICENSE"

    sudo install -Dm 644 "$repodir/README.md" "${installprefix}/share/doc/${pkgname}/README.md"

    echo ":: Rolling release installation done."

elif [ "$version" == "CANCEL" ]; then
    echo ":: Setup canceled"
    exit 130
else
    echo ":: Setup canceled"
    exit 130
fi

echo ":: Installation complete."
echo

# Start Spinner
gum spin --spinner dot --title "Starting setup now..." -- sleep 3

# Run setup with Gentoo platform flag
ml4w-hyprland-setup -p gentoo

