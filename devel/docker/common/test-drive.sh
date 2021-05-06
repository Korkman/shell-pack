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

# script location
whereiam="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

# 'debian-buster'
tagname="$( basename "${whereiam}")"

# the location of the current source to be packaged
srcdir="$( cd "${whereiam}/../../.." >/dev/null 2>&1 && pwd )"
context="${srcdir}/devel/docker"

# the temporary directory which will be shared as a docker volume
tmpdir="/tmp/docker-shell-pack-test-drive-$tagname"
mkdir -p "$tmpdir"
download_file="korkman-shell-pack-latest.tar.gz"

# build
echo "${whereiam}"
echo "${tagname}"
echo "${context}"
docker build -t shell-pack:test-drive-${tagname} -f "${whereiam}/Dockerfile" "${context}"

# package src
echo "Packaging ${srcdir}"
(cd ../../.. && tar -czf "${tmpdir}/${download_file}" ".")
cp -f "$srcdir/get.sh" "$tmpdir/get.sh"

# run
docker run --rm \
-e AUTOSTART="$AUTOSTART" \
-e TERM="$TERM" \
--volume "$tmpdir":"/root/Downloads":rw \
--interactive \
--tty shell-pack:test-drive-${tagname}

# clean-up
rm -rf "$tmpdir"

exit
}