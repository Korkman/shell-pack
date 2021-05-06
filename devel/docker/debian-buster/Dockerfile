FROM debian:buster

# upgrade from LC_ALL "C" to add utf-8 support (prompt does not display glyphs otherwise)
ENV LC_ALL C.UTF-8

RUN apt-get update && apt-get install -y \
	lsb-release gettext-base man-db xz-utils \
	htop tmux procps libncurses6 mc screen curl gpg
# NOTE: use cache to run more apt-get lines during development, then
#       move them to the combined line above.

# procps is required for 'kill', which is used inside fish mc subshell

# actually, keep lists in container for now
#RUN rm -rf /var/lib/apt/lists/*

RUN echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_10/ /' > /etc/apt/sources.list.d/shells:fish:release:3.list
RUN curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_10/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg
RUN apt-get update
RUN apt-get install -y fish

# nerdlevel 3 by default
ENV LC_NERDLEVEL 3

COPY common/guest-startup.sh /guest-startup.sh
WORKDIR /root/Downloads
ENTRYPOINT [ "/guest-startup.sh" ]
