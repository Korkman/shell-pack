#! /usr/bin/env sh
{

# this script
# - packages the source dir as a tar.gz
# - builds a docker / podman container
# - runs docker / podman, with tar.gz and get.sh inside
# - runs get.sh, unless started with env AUTOSTART=no

# be more strict about errors
set -eu
# initialize defaults
AUTOSTART=${AUTOSTART:-yes} # run installer in guest-startup.sh
FORCE_DOCKER=${FORCE_DOCKER:-no} # force use of docker although podman is available
FORCE_NO_SUDO=${FORCE_NO_SUDO:-no} # force skipping sudo for docker
USE_CACHED_DOWNLOADS=${USE_CACHED_DOWNLOADS:-yes} # use cached downloads (rg, fzf, etc.)
FISH_STATIC=${FISH_STATIC:-no} # install fish static binary (4.0 beta and up)
FISH_NIGHTLY=${FISH_NIGHTLY:-no} # install fish nightly
PLATFORM=${PLATFORM:-} # set for example to linux/arm64 for aarch64

usage() {
	cat << EOF
Usage: $0 <distro> [build|build-uncached|run] [persist]

Options:
  build              Build the Docker image (allow cache)
  build-uncached     Build the Docker image (invalidate cache)
  run                Run container, build if inexistent
  persist            Persist container (default is ephemeral)

Environment Variables:
  AUTOSTART              Run installer on startup (default: yes)
  FORCE_DOCKER           Force Docker instead of Podman (default: no)
  FORCE_NO_SUDO          Skip sudo for Docker (default: no)
  USE_CACHED_DOWNLOADS   Use cached downloads (default: yes)
  FISH_STATIC            Force install fish static binary (default: no)
  FISH_NIGHTLY           Force install fish nightly (default: no)
  PLATFORM               Set platform e.g. linux/arm64 (default: auto)

Examples:
  $0 debian:latest
  $0 alpine:latest run
  $0 fedora:latest build
  PLATFORM=linux/arm64 $0 debian:bookworm run
EOF
}

PLATFORM_TAG_SUFFIX=""
if [ "$PLATFORM" != "" ]
then
	PLATFORM_TAG_SUFFIX=$(echo "-$PLATFORM" | sed 's/[/]/-/g')
	PLATFORM="--platform $PLATFORM"
fi
do_build="no" # perform docker build (append "build" to CLI to trigger)
build_uncached="no" # perform docker build and invalidate any cache (append "build-uncached")
persist="no"
if [ -z "${XDG_RUNTIME_DIR+x}" ]
then
	# XDG_RUNTIME_DIR missing, try fixing
	XDG_RUNTIME_DIR="/run/user/$(id -u)"
	# if it doesn't exist where we expect it, this might be macos or other unix
	# since podman on macos doesn't have access to /tmp (and it is arguably a bad idea to change that)
	# use a directory in $HOME instead
	if [ ! -e "$XDG_RUNTIME_DIR" ]
	then
		 XDG_RUNTIME_DIR="$HOME/.cache/shell-pack-devel/test-drive-runtime-dir"
	fi
fi
echo "Using $XDG_RUNTIME_DIR for temporary files"

case "${2:-}" in
	"build" )
		# trigger build, but allow cache
		do_build="yes"
		;;
	"build-uncached" )
		# trigger build, but invalidate cache
		do_build="yes"
		build_uncached="yes"
		;;
	"run" | "" )
		;;
	"help"| * )
		usage
		exit 1
		;;
esac

case "${3:-}" in
	"persist" )
		persist="yes"
		;;
	"help"| * )
		usage
		exit 1
		;;
esac

export DOCKER_BUILDKIT=1
if command -v "podman" > /dev/null && [ "$FORCE_DOCKER" != "yes" ]
then
	echo "Using podman to run test-drive (if you prefer docker, run with env FORCE_DOCKER=yes)"
	docker="podman"
	if podman machine inspect | grep -qE "State.*stopped"
	then
		echo "podman machine start"
		podman machine start
	fi
else
	if [ "$FORCE_NO_SUDO" = "yes" ] || [ "$(whoami)" = "root" ]
	then
		echo "Using docker to run test-drive (I am root)"
		docker="docker"
	else
		echo "Using docker to run test-drive (via sudo)"
		docker="sudo docker"
	fi
fi

BUILD_FROM="${1:-help}"
case "$BUILD_FROM" in
	debian:jessie | debian:stretch | debian:buster | debian:bullseye )
		echo "EOL distros need the /eol namespace, so debian:jessie becomes debian/eol:jessie, etc."
		exit 1
		;;
	debian:* | debian/eol:* | ubuntu:* )
		dockerfile="Dockerfile-Debian"
		;;
	fedora:* | centos:* | redhat/*:* | rockylinux:* | almalinux:* )
		dockerfile="Dockerfile-Redhat"
		;;
	archlinux:* )
		dockerfile="Dockerfile-Archlinux"
		;;
	alpine:* )
		dockerfile="Dockerfile-Alpine"
		;;
	*)
		echo "Please provide a distro name, examples:"
		echo " - debian:latest"
		echo " - debian:unstable"
		echo " - alpine:latest"
		echo " - fedora:latest"
		echo " - archlinux:latest"
		echo " - almalinux:latest"
		echo "Specific releases like:"
		echo " - debian:bookworm"
		echo " - debian/eol:jessie"
		echo " - ubuntu:xenial"
		echo " - redhat/ubi9:latest"
		exit 1
		;;
esac

tagname="$(echo "$BUILD_FROM" | sed 's/[:\/]/-/g')${PLATFORM_TAG_SUFFIX}"
# append "fish4" to tagname if SP_FISH4 is yes
if [ "$FISH_STATIC" = "yes" ]
then
	tagname="${tagname}-fish-static"
fi
if [ "$FISH_NIGHTLY" = "yes" ]
then
	tagname="${tagname}-fish-nightly"
fi
if [ "$persist" = "yes" ]
then
	tagname="${tagname}-persist"
fi

# script location
whereiam="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

# the location of the current source to be packaged
srcdir="$( cd "${whereiam}/../.." >/dev/null 2>&1 && pwd )"

# the temporary directory which will be shared as a docker volume
tmpdir="$XDG_RUNTIME_DIR/shell-pack-test-drive-$tagname"
mkdir -p "$tmpdir"
download_file="korkman-shell-pack-latest.tar.gz"

# test if image is present, otherwise force build
if [ "$($docker images --quiet "shell-pack:test-drive-${tagname}")" = "" ]
then
	do_build="yes"
fi

# build
if [ "$do_build" = "yes" ]
then
	#echo "${whereiam}"
	#echo "${tagname}"
	cache_arg=""
	[ "$build_uncached" = "yes" ] && cache_arg="--no-cache "
	$docker build \
		$cache_arg \
		--build-arg "FISH_STATIC=$FISH_STATIC" \
		--build-arg "FISH_NIGHTLY=$FISH_NIGHTLY" \
		--build-arg "BUILD_FROM=docker.io/$BUILD_FROM" \
		$PLATFORM \
		-t "shell-pack:test-drive-${tagname}" -f "${dockerfile}" .
fi

# package src
# exclude unnecessary .git and binaries potentially unsuitable for platform
# also exclude dool.d to simulate first use experience (clear download cache for this)
echo "Package ${srcdir}"
(cd "${srcdir}" && tar \
	'--exclude=.git' \
	'--exclude=rg' \
	'--exclude=fzf' \
	'--exclude=sk' \
	'--exclude=dool.d' \
	-czf "${tmpdir}/${download_file}" \
".")

echo "Copy get.sh"
cp -f "$srcdir/get.sh" "$tmpdir/get.sh"

echo "Create caching directory"
cachedir="$HOME/.cache/shell-pack-devel/docker/$tagname"
mkdir -p "$cachedir"

echo "Copy over cached rg, fzf, dool.d … if present"
if [ "$USE_CACHED_DOWNLOADS" = "yes" ]
then
	if [ -e "$cachedir/rg" ]
	then
		echo "found cached rg"
		cp "$cachedir/rg" "$tmpdir/rg"
	fi
	if [ -e "$cachedir/fzf" ]
	then
		echo "found cached fzf"
		cp "$cachedir/fzf" "$tmpdir/fzf"
	fi
	if [ -e "$cachedir/sk" ]
	then
		echo "found cached sk"
		cp "$cachedir/sk" "$tmpdir/sk"
	fi
	if [ -e "$cachedir/dool.d" ]
	then
		echo "found cached dool.d"
		cp -a "$cachedir/dool.d" "$tmpdir/"
	fi
fi

echo "Run $docker"
container_id=$(
	$docker run \
	-e AUTOSTART="$AUTOSTART" \
	-e TERM="$TERM" \
	--hostname "test-${tagname}" \
	--volume "$tmpdir:/root/Downloads:rw" \
	$PLATFORM \
	--interactive \
	--tty \
	--detach \
	"shell-pack:test-drive-${tagname}"
)
echo "Attaching $container_id ..."
rs=0
$docker attach "$container_id" || rs=$?
if [ "$persist" = "yes" ]
then
	if [ $rs -ne 0 ]
	then
		echo "❌ Persist: Non-zero exit, not commiting container"
	else
		echo "💾 Persist: Commiting container to shell-pack:test-drive-${tagname}"
		$docker commit "$container_id" "shell-pack:test-drive-${tagname}" > /dev/null
	fi
fi
$docker rm -f "$container_id" > /dev/null

echo "Save downloaded rg, fzf, dool.d, … to cache"
if [ -e "$tmpdir/rg" ] && [ ! -e "$cachedir/rg" ]
then
	echo "Caching downloaded rg ..."
	cp "$tmpdir/rg" "$cachedir/rg"
fi
if [ -e "$tmpdir/fzf" ] && [ ! -e "$cachedir/fzf" ]
then
	echo "Caching downloaded fzf ..."
	cp "$tmpdir/fzf" "$cachedir/fzf"
fi
if [ -e "$tmpdir/sk" ] && [ ! -e "$cachedir/sk" ]
then
	echo "Caching downloaded sk ..."
	cp "$tmpdir/sk" "$cachedir/sk"
fi
if [ -e "$tmpdir/dool.d" ] && [ ! -e "$cachedir/dool.d" ]
then
	echo "Caching downloaded dool.d ..."
	cp -r "$tmpdir/dool.d" "$cachedir/"
fi

# clean-up
rm -rf "$tmpdir"

exit
}