#! /usr/bin/env bash

# Unofficial bash strict mode, engage!
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'
AUTOSTART=${AUTOSTART:-yes}

whereiam="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
tagname="$( basename "${whereiam}")"
srcdir="$( cd "${whereiam}/../../.." >/dev/null 2>&1 && pwd )"
context="${srcdir}/devel/docker"

echo "${whereiam}"
echo "${tagname}"
echo "${context}"
docker build -t shell-pack:test-drive-${tagname} -f "${whereiam}/Dockerfile" "${context}"
docker run -e AUTOSTART="$AUTOSTART" -e TERM="$TERM" --volume "$srcdir":"/root/.local/share/shell-pack/src":ro --interactive --tty shell-pack:test-drive-${tagname}
