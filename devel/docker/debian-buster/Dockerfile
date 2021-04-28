FROM debian:buster

RUN apt-get update && apt-get install -y \
	lsb-release wget gettext-base man-db xz-utils \
	htop tmux
# NOTE: use cache to run more apt-get lines during development, then
#       move them to the combined line above.
RUN apt-get install -y libncurses6
RUN apt-get install -y mc
# actually, keep lists in container for now
#RUN rm -rf /var/lib/apt/lists/*

#COPY . /root/.local/share/shell-pack/src
COPY common/guest-startup.sh /etc/profile.d/guest-startup.sh

#WORKDIR /usr/local/src/shell-pack/deps/x86_64/debian-buster
#RUN dpkg -i fish-common.deb fish.deb
#RUN /root/.local/share/shell-pack/src/get.sh

# upgrade from LC_ALL "C" to add utf-8 support (prompt does not display glyphs otherwise)
ENV LC_ALL C.UTF-8

# nerdlevel 3 by default
ENV LC_NERDLEVEL 3

ENTRYPOINT [ "/bin/bash",  "-l" ]
