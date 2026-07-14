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
EXTRA_MOUNTS=${EXTRA_MOUNTS:-} # list of mounts to add to the container under /mnt
AUTOSTART=${AUTOSTART:-yes} # run installer in guest-startup.sh
FORCE_DOCKER=${FORCE_DOCKER:-no} # force use of docker although podman is available
FORCE_NO_SUDO=${FORCE_NO_SUDO:-no} # force skipping sudo for docker
USE_CACHED_DOWNLOADS=${USE_CACHED_DOWNLOADS:-yes} # use cached downloads (rg, fzf, etc.)
INSTALL_FISH=${INSTALL_FISH:-static-latest} # none|distro|repo-nightly|repo-release|static-latest|static-VERSION
PLATFORM=${PLATFORM:-} # set for example to linux/arm64 for aarch64

usage() {
	cat << EOF
Usage: $0 <distro> [build|build-uncached|run|persist|rm] [persist]

Options:
  build              Build the Docker image (allow cache, but pull base)
  build-uncached     Build the Docker image (no cache)
  run                Run container, build if inexistent
  persist            Persist container (default is ephemeral)
  rm                 Remove persisted container

Environment Variables:
  EXTRA_MOUNTS           Space-separated host paths to mount under /mnt
                         (supports host_path[:container_path[:options]])
  AUTOSTART              Run installer on startup (default: yes)
  FORCE_DOCKER           Force Docker instead of Podman (default: no)
  FORCE_NO_SUDO          Skip sudo for Docker (default: no)
  USE_CACHED_DOWNLOADS   Use cached downloads (default: yes)
  INSTALL_FISH           Fish install method (default: static-latest)
                           none            - skip fish installation
                           distro          - use distro package manager
                           repo-release    - add release repo, install fish
                           repo-nightly    - add nightly repo, install fish
                           static-latest   - download latest static binary
                           static-VERSION  - download specific static binary
  PLATFORM               Set platform e.g. linux/arm64 (default: auto)
                         (add support with qemu-user-binfmt)

Examples:
  $0 debian:latest
  $0 alpine:latest run
  $0 fedora:latest build
  PLATFORM=linux/arm64 $0 debian:bookworm run

  Distro examples:
    debian:latest
    debian:unstable
    alpine:latest
    fedora:latest
    archlinux:latest
    almalinux:latest
  Specific releases like:
    debian:bookworm
    debian/eol:jessie
    ubuntu:xenial
    redhat/ubi9:latest

EOF
}

PLATFORM_TAG_SUFFIX=""
PLATFORM_NATIVE="$(uname)/$(uname --machine)"
if [ "$PLATFORM" != "" ]
then
	PLATFORM_TAG_SUFFIX=$(echo "-$PLATFORM" | sed 's/[/]/-/g')
	PLATFORM_ARG="--platform $PLATFORM"
else
	PLATFORM="$PLATFORM_NATIVE"
	PLATFORM_ARG="--platform $PLATFORM_NATIVE"
fi
do_build="no" # perform docker build (append "build" to CLI to trigger)
build_uncached="no" # perform docker build and invalidate any cache (append "build-uncached")
persist="no" # whether to run a persisting container
do_remove="no" # remove persisted container
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
	"rm" | "remove" | "unpersist")
		do_remove="yes"
		persist="yes"
		;;
	"persist")
		persist="yes"
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
	"" ) ;;
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
	if podman machine inspect 2>/dev/null | grep -qE "State.*stopped"
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
		usage
		
		exit 1
		;;
esac

tagname="$(echo "$BUILD_FROM" | sed 's/[:\/]/-/g')${PLATFORM_TAG_SUFFIX}"
# append INSTALL_FISH variant to tagname
tagname="${tagname}-fish-$(echo "$INSTALL_FISH" | sed 's/[^a-zA-Z0-9._-]/-/g')"

# script location
whereiam="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

# the location of the current source to be packaged
srcdir="$( cd "${whereiam}/../.." >/dev/null 2>&1 && pwd )"

# the temporary directory which will be shared as a docker volume
tmpdir="$XDG_RUNTIME_DIR/shell-pack-test-drive-$tagname"
mkdir -p "$tmpdir"
download_file="korkman-shell-pack-latest.tar.gz"

if [ "$persist" = "yes" ]
then
	persist_container_name="shell-pack-test-drive-$tagname"
	container_id=$($docker ps -a --format '{{ .ID }}' --filter "name=^$persist_container_name\$" 2>/dev/null) || container_id=""
	arg_container_name="--name $persist_container_name"
else
	container_id=""
	arg_container_name=""
fi

if [ "$do_remove" = "yes" ]
then
	if [ "${container_id:-}" = "" ]
	then
		echo "⚠️ No container found to remove: $persist_container_name"
		exit 1
	fi
	echo "❌ Discarding $persist_container_name ..."
	$docker rm "$container_id"
	if $docker image inspect "shell-pack:test-drive-${tagname}-committed" >/dev/null 2>&1
	then
		echo "🧹 Removing committed image shell-pack:test-drive-${tagname}-committed ..."
		$docker rmi "shell-pack:test-drive-${tagname}-committed" || true
	fi
	exit 0
fi

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
		--pull \
		--build-arg "INSTALL_FISH=$INSTALL_FISH" \
		--build-arg "BUILD_FROM=docker.io/$BUILD_FROM" \
		$PLATFORM_ARG \
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
	'--exclude=dool.d' \
	-czf "${tmpdir}/${download_file}" \
".")

echo "Copy get.sh"
cp -f "$srcdir/get.sh" "$tmpdir/get.sh"

echo "Create caching directory"
cachedir="$HOME/.cache/shell-pack-devel/docker/$tagname"
mkdir -p "$cachedir"

echo "Run $docker"

CACHED_FILES="rg fzf dool.d"
if [ "$USE_CACHED_DOWNLOADS" = "yes" ]
then
	echo "Copy over available cached files …"
	for cached_file in $CACHED_FILES
	do
		if [ -e "$cachedir/$cached_file" ]
		then
			echo "$cached_file …"
			cp -a "$cachedir/$cached_file" "$tmpdir/"
		fi
	done
fi

extra_mounts_args=""
desired_mount_list=""
if [ -n "$EXTRA_MOUNTS" ]
then
	for mount in $EXTRA_MOUNTS
	do
		# Format is: host_path[:container_path[:options]]
		host_path=""
		container_path=""
		opts="rw"

		case "$mount" in
			*:*:* )
				host_path="${mount%%:*}"
				rest="${mount#*:}"
				container_path="${rest%%:*}"
				opts="${rest#*:}"
				;;
			*:* )
				host_path="${mount%%:*}"
				container_path="${mount#*:}"
				;;
			* )
				host_path="$mount"
				container_path="/mnt/$(basename "$host_path")"
				;;
		esac

		# Ensure host_path is absolute
		case "$host_path" in
			/* ) ;;
			* ) host_path="$PWD/$host_path" ;;
		esac

		# Ensure container_path starts with /
		case "$container_path" in
			/* ) ;;
			* ) container_path="/mnt/$container_path" ;;
		esac

		extra_mounts_args="$extra_mounts_args --volume $host_path:$container_path:$opts"
		desired_mount_list="$desired_mount_list $host_path:$container_path:$opts"
	done
fi

if [ "${container_id:-}" != "" ]
then
	# Check if mounted volumes have changed. Since docker/podman do not support
	# changing volumes of an existing container via "start", we commit the state,
	# destroy the old container, and recreate it with the new mounts.
	existing_mounts=$($docker inspect --format '{{range .Mounts}}{{.Source}}:{{.Destination}}:{{.Mode}} {{end}}' "$container_id" 2>/dev/null || true)
	mounts_changed="no"

	for dm in $desired_mount_list
	do
		dm_host="${dm%%:*}"
		rest="${dm#*:}"
		dm_container="${rest%%:*}"
		dm_opts="${rest#*:}"

		found="no"
		for em in $existing_mounts
		do
			em_host="${em%%:*}"
			em_rest="${em#*:}"
			em_container="${em_rest%%:*}"
			em_mode="${em_rest#*:}"

			if [ "$dm_host" = "$em_host" ] && [ "$dm_container" = "$em_container" ]
			then
				case "$em_mode" in
					*"$dm_opts"* ) found="yes"; break ;;
					* )
						if [ "$dm_opts" = "rw" ] || [ -z "$dm_opts" ]
						then
							found="yes"
							break
						fi
						;;
				esac
			fi
		done

		if [ "$found" = "no" ]
		then
			echo "🔍 Detected missing or modified mount: $dm_host -> $dm_container"
			mounts_changed="yes"
			break
		fi
	done

	if [ "$mounts_changed" = "no" ]
	then
		for em in $existing_mounts
		do
			em_host="${em%%:*}"
			em_rest="${em#*:}"
			em_container="${em_rest%%:*}"

			case "$em_container" in
				/mnt/* )
					found="no"
					for dm in $desired_mount_list
					do
						dm_host="${dm%%:*}"
						rest="${dm#*:}"
						dm_container="${rest%%:*}"
						if [ "$em_host" = "$dm_host" ] && [ "$em_container" = "$dm_container" ]
						then
							found="yes"
							break
						fi
					done
					if [ "$found" = "no" ]
					then
						echo "🔍 Detected stale mount to remove: $em_container"
						mounts_changed="yes"
						break
					fi
					;;
			esac
		done
	fi

	if [ "$mounts_changed" = "yes" ]
	then
		echo "🔄 Volume mounts changed. Committing container state and recreating container..."
		if $docker commit "$container_id" "shell-pack:test-drive-${tagname}-committed" >/dev/null 2>&1
		then
			echo "💾 Container state saved to shell-pack:test-drive-${tagname}-committed"
			$docker rm -f "$container_id" >/dev/null
			container_id=""
		else
			echo "⚠️ Failed to commit container state. Recreating container from base image..."
			$docker rm -f "$container_id" >/dev/null
			container_id=""
		fi
	fi
fi

run_image="shell-pack:test-drive-${tagname}"
if [ "${container_id:-}" = "" ]
then
	if [ "$persist" = "yes" ] && $docker image inspect "shell-pack:test-drive-${tagname}-committed" >/dev/null 2>&1
	then
		run_image="shell-pack:test-drive-${tagname}-committed"
	fi

	# a new container must be created
	container_id=$(
		$docker run \
		-e AUTOSTART="$AUTOSTART" \
		-e TERM="$TERM" \
		--hostname "test-${tagname}" \
		--volume "$tmpdir:/root/Downloads:rw" \
		--volume "./added/guest-startup.sh:/guest-startup.sh:ro" \
		$extra_mounts_args \
		$PLATFORM_ARG \
		--interactive \
		--tty \
		--detach \
		$arg_container_name \
		"$run_image"
	)

	echo "Attaching $container_id ..."
	rs=0
	$docker attach "$container_id" || rs=$?
else
	echo "Starting persisted container $container_id …"
	$docker start --interactive --attach "$container_id"
fi

echo "Save downloads from installer / autoupdate to cache …"
for cached_file in $CACHED_FILES
do
	if [ -e "$tmpdir/$cached_file" ]
	then
		echo "$cached_file from installer …"
		cp -r "$tmpdir/$cached_file" "$cachedir/"
	fi
done

if [ "$persist" = "yes" ]
then
		echo "💾 Persisting container $container_id …"
else
	echo "❌ Discarding ephermal container …"
	#$docker start --interactive "$container_id"
	#$docker exec "$container_id" sh -c 'rm -rf /root/.local/share/shell-pack/bin/*'
	$docker rm -f "$container_id" > /dev/null
fi

# clean-up
echo "❌ Discarding ephermal data outside of container …"
rm -rf "$tmpdir"

exit
}