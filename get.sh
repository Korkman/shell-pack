#! /usr/bin/env sh
{

# wrapping in curly braces to protect against http disconnect and
# other modification during runtime

# be more strict about errors
set -eu

# optional argument to download specific tag
DOWNLOAD_TAG="${1:-latest}"

# this will be the location where shell-pack code, config and deps will be installed to
SHELL_PACK_BASEDIR_STR='$HOME/.local/share/shell-pack' # NOTE: do not use {brackets} so the path is fish compatible
SHELL_PACK_BASEDIR="${HOME}/.local/share/shell-pack"
SHELL_PACK_SRCDIR="${SHELL_PACK_BASEDIR}/src"

# these lines will be added to config.fish and POSIX shell config (.profile, .zprofile, .bash_profile) respectively
SHELL_PACK_FISH_SOURCE_LINE="source \"${SHELL_PACK_BASEDIR_STR}/config/fish/config.fish\""
NERDLEVEL_DOT_PROFILE_LINE=". \"${SHELL_PACK_BASEDIR_STR}/config/nerdlevel.sh\""

# this is deprecated and will be removed if present
NERDLEVEL_OLD_DOT_PROFILE_LINE="source \"${SHELL_PACK_BASEDIR_STR}/config/nerdlevel.sh\""

# this is the location config.fish which will be modified
TARGET_FISH_CONFIG_DIR="${HOME}/.config/fish"
TARGET_FISH_CONFIG="${TARGET_FISH_CONFIG_DIR}/config.fish"

# detect OS and machine type
MACHINE="$(uname -m)" # x86_64 / i386 / ...
META_DISTRO="$(uname -s)" # Darwin / Linux / ...
DISTRO_NAME="unknown"
DISTRO_RELEASE="unknown"
case "${META_DISTRO}" in
	"Darwin")
		META_DISTRO="macos"
		;;
	"Linux")
		META_DISTRO="linux"
		# TODO: fill in DISTRO_NAME, DISTRO_RELEASE with lsb_release if available?
		# currently, maintaining distro specific installation routines is not feasible
		;;
	*)
		#echo "WARNING: Meta distribution unknown: ${META_DISTRO}"
		#echo "         Trouble ahead"
		;;
esac

# ---------------------------------------------
# Check if fish is installed and give advice if not
# ---------------------------------------------
if ! command -v fish > /dev/null; then
	echo "Fish is not installed"
	if [ "${META_DISTRO}" = "macos" ]; then
		echo "Recommeded for macOS:"
		echo " - brew install fish"
		echo " - or see https://fishshell.com/"
		exit 1
	else
		echo "See: https://fishshell.com/"
		exit 1
	fi
fi

# ---------------------------------------------
# Download shell-pack
# ---------------------------------------------

if [ -d "${SHELL_PACK_SRCDIR}/.git" ]; then
	echo "Detected .git directory in ${SHELL_PACK_SRCDIR}!"
	echo "Are you a developer? Trying not to ruin your day, aborting."
	echo "Use 'git pull' ;-)"
	exit 1
fi

DOWNLOAD_FILENAME="korkman-shell-pack-${DOWNLOAD_TAG}.tar.gz"

if [ "${FORCE_PRE_DOWNLOADED:-n}" = "n" ]
then
	PRE_DOWNLOADED=n
	if [ -t 0 ] && [ -e "${DOWNLOAD_FILENAME}" ]; then
		# when in terminal, ask whether to re-use downloaded file
		echo "Pre-downloaded file detected, use for installation? (y/N)"
		read answer || answer=n
		if [ "$answer" = "y" ]; then
			PRE_DOWNLOADED=y
		fi
	fi
else
	PRE_DOWNLOADED=y
fi

if [ "${PRE_DOWNLOADED}" = "n" ]; then
	echo "Downloading ${DOWNLOAD_FILENAME} ..."
	curl -sL "https://github.com/Korkman/shell-pack/archive/refs/tags/${DOWNLOAD_TAG}.tar.gz" > "${DOWNLOAD_FILENAME}"
fi

echo "Verifying archive ${DOWNLOAD_FILENAME} ..."
tar --strip-components=1 -xzf "${DOWNLOAD_FILENAME}" -O > /dev/null

echo "Extracting ${DOWNLOAD_FILENAME} ..."

# purging previous install if present
if [ -d "${SHELL_PACK_SRCDIR}" ]; then
	rm -rf "${SHELL_PACK_SRCDIR}"
fi

# creating install dir
mkdir -p "${SHELL_PACK_SRCDIR}"

tar --strip-components=1 -xzf "${DOWNLOAD_FILENAME}" -C "${SHELL_PACK_SRCDIR}"

# sanity check: if README.md does not manifest in src dir, something failed
if [ ! -e "${SHELL_PACK_SRCDIR}/README.md" ]; then
	echo "ERROR: ${SHELL_PACK_SRCDIR}/README.md does not exist!"
	exit 57
fi

rm "${DOWNLOAD_FILENAME}"

# ---------------------------------------------
# Symlink stuff
# ---------------------------------------------

# slightly defensive here: if any links pre-exist, they won't be changed

# the main fish config
if [ ! -e "${SHELL_PACK_BASEDIR}/config" ]; then
	echo "Linking ${SHELL_PACK_BASEDIR}/config → src/config"
	ln -s "src/config" "${SHELL_PACK_BASEDIR}/config"
else
	echo "Skipping present ${SHELL_PACK_BASEDIR}/config"
fi

# this directory will hold ripgrep, skim and maybe more in the future
# it is added to the PATH in shell-pack and can also be added to PATH
# in your POSIX shell to proxy some commands to fish (see 'fishcall')
SHELL_PACK_BINDIR="${SHELL_PACK_BASEDIR}/bin"

mkdir -p "${SHELL_PACK_BINDIR}"

# this merges several symlinks into SHELL_PACK_BINDIR
for item in "${SHELL_PACK_SRCDIR}/bin/"*; do
	item=$(basename "$item")
	if [ ! -e "${SHELL_PACK_BINDIR}/${item}" ]; then
		echo "Linking ${SHELL_PACK_BINDIR}/${item} → ../src/bin/${item}"
		ln -s "../src/bin/${item}" "${SHELL_PACK_BINDIR}/${item}"
	else
		echo "Skipping present ${SHELL_PACK_BINDIR}/${item}"
	fi
done

# remove deprecated symlinks from SHELL_PACK_BINDIR
for item in 'ggrep' 'ggrep-in-file' 'ggrep-help'; do
	if [ -e "${SHELL_PACK_BINDIR}/${item}" ]; then
		echo "Removing ${SHELL_PACK_BINDIR}/${item}"
		rm "${SHELL_PACK_BINDIR}/${item}"
	fi
done

# ---------------------------------------------
# Add Shell-Pack to user's config.fish
# ---------------------------------------------
if ! [ -f "${TARGET_FISH_CONFIG}" ] || ! grep -Fxq "${SHELL_PACK_FISH_SOURCE_LINE}" "${TARGET_FISH_CONFIG}" ; then
	mkdir -p "${TARGET_FISH_CONFIG_DIR}"
	echo "Adding shell-pack to ${TARGET_FISH_CONFIG}"
	echo "${SHELL_PACK_FISH_SOURCE_LINE}" >> "${TARGET_FISH_CONFIG}"
else
	echo "Not modifying already modified ${TARGET_FISH_CONFIG}"
fi

# ---------------------------------------------
# Add nerdlevel command or give advice
# ---------------------------------------------
NERDLEVELED=no
for PROFILE in "${HOME}/.bash_profile" "${HOME}/.zprofile" "${HOME}/.profile"; do
	if [ -f "${PROFILE}" ]; then
		if ! grep -Fxq "${NERDLEVEL_DOT_PROFILE_LINE}" "${PROFILE}" ; then
			echo "Added nerdlevel to ${PROFILE}"
			echo "${NERDLEVEL_DOT_PROFILE_LINE}" >> "${PROFILE}"
		else
			echo "Not modifying already modified ${PROFILE}"
		fi
		# if already present, mark nerdleveled
		NERDLEVELED=yes
	fi
done

# ---------------------------------------------
# Remove deprecated source line if present
# ---------------------------------------------
for PROFILE in "${HOME}/.bash_profile" "${HOME}/.zprofile" "${HOME}/.profile"; do
	if [ -f "${PROFILE}" ]; then
		if grep -Fxq "${NERDLEVEL_OLD_DOT_PROFILE_LINE}" "${PROFILE}" ; then
			grep -Fxv "${NERDLEVEL_OLD_DOT_PROFILE_LINE}" > "${PROFILE}.new" < "${PROFILE}"
			cat "${PROFILE}.new" > "${PROFILE}"
			rm "${PROFILE}.new"
		fi
	fi
done

if [ "${NERDLEVELED}" != "yes" ]; then
	echo "Please add the following line to your profile: "
	echo "${NERDLEVEL_DOT_PROFILE_LINE}"
	exit 0
else
	echo "All systems go. Happy fishing!"
	exit 0
fi


exit
}
