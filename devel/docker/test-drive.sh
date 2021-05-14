#! /usr/bin/env sh
{

# this script
# - packages the source dir as a tar.gz
# - builds a docker container
# - runs docker, with tar.gz and get.sh inside
# - runs get.sh, unless started with env AUTOSTART=no

# be more strict about errors
set -eu
IFS=$'\n\t'
AUTOSTART=${AUTOSTART:-yes}

do_build=no

if [ "${2:-}" = "build" ]
then
	do_build=yes
fi

BUILD_FROM="${1:-debian:buster}"
case "$BUILD_FROM" in
	'debian:buster')
		tagname='debian-buster'
		dockerfile="Dockerfile-Debian"
		;;
	'debian:stretch')
		tagname='debian-stretch'
		dockerfile="Dockerfile-Debian"
		;;
	'ubuntu:xenial')
		tagname='ubuntu-xenial'
		dockerfile="Dockerfile-Debian"
		;;
	*)
		echo "Please provide distro name"
		echo " - debian:buster"
		echo " - ubuntu:xenial"
		exit 1
		;;
esac

# script location
whereiam="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

# the location of the current source to be packaged
srcdir="$( cd "${whereiam}/../.." >/dev/null 2>&1 && pwd )"

# the temporary directory which will be shared as a docker volume
tmpdir="/tmp/docker-shell-pack-test-drive-$tagname"
mkdir -p "$tmpdir"
download_file="korkman-shell-pack-latest.tar.gz"

# build
if [ "$do_build" = "yes" ]
then
	#echo "${whereiam}"
	#echo "${tagname}"
	docker build \
		--build-arg BUILD_FROM=$BUILD_FROM \
		-t shell-pack:test-drive-${tagname} -f "${dockerfile}" .
fi

# package src
echo "Packaging ${srcdir}"
(cd "${srcdir}" && tar '--exclude=rg' '--exclude=fzf' '--exclude=sk' -czf "${tmpdir}/${download_file}" ".")

cp -f "$srcdir/get.sh" "$tmpdir/get.sh"

# create caching directory
cachedir="$HOME/.cache/shell-pack-devel/docker/$tagname"
mkdir -p "$cachedir"

# copy over cached rg, sk, if present
if [ -e "$cachedir/rg" ]
then
	cp "$cachedir/rg" "$tmpdir/rg"
fi
if [ -e "$cachedir/fzf" ]
then
	cp "$cachedir/fzf" "$tmpdir/fzf"
fi
if [ -e "$cachedir/sk" ]
then
	cp "$cachedir/sk" "$tmpdir/sk"
fi

# run
docker run --rm \
-e AUTOSTART="$AUTOSTART" \
-e TERM="$TERM" \
--volume "$tmpdir":"/root/Downloads":rw \
--interactive \
--tty shell-pack:test-drive-${tagname}

# save downloaded rg, sk to cache
if [ -e "$tmpdir/rg" -a ! -e "$cachedir/rg" ]
then
	echo "Caching downloaded rg ..."
	cp "$tmpdir/rg" "$cachedir/rg"
fi
if [ -e "$tmpdir/fzf" -a ! -e "$cachedir/fzf" ]
then
	echo "Caching downloaded fzf ..."
	cp "$tmpdir/fzf" "$cachedir/fzf"
fi
if [ -e "$tmpdir/sk" -a ! -e "$cachedir/sk" ]
then
	echo "Caching downloaded sk ..."
	cp "$tmpdir/sk" "$cachedir/sk"
fi

# clean-up
rm -rf "$tmpdir"

exit
}