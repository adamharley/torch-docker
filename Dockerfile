FROM debian:stable-slim
LABEL maintainer="Adam Harley"

ARG TORCH_BUILD=99

VOLUME /torch-server/Instance
VOLUME /torch-server/Logs
VOLUME /torch-server/Plugins

EXPOSE 5900/tcp
EXPOSE 6080/tcp
EXPOSE 27016/udp

# Download necessary packages
RUN dpkg --add-architecture i386 && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
		ca-certificates \
		cabextract \
		net-tools \
		novnc \
		procps \
		supervisor \
		wget \
		wine \
		wine32 \
		wine64 \
		x11vnc \
		xauth \
		xvfb \
		unzip && \
	apt-get clean && rm -rf /var/lib/apt/lists/* && \
	ln -s /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html

# Download Winetricks
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/bin/winetricks && \
	chmod +x /usr/bin/winetricks

# Setup Wine environment
RUN winetricks sound=disabled && \
	winetricks windowmanagermanaged=n

# Install dependencies
RUN W_OPT_UNATTENDED=1 xvfb-run winetricks \
		arial \
		dotnet462 \
		vcrun2013 \
		vcrun2017 \
	2>/dev/null && \
	rm -rf  ~/.cache ~/.config ~/.local /tmp/*

# Copy supervisord.conf
COPY supervisord.conf /torch-server/supervisord.conf

# Install Torch server
RUN wget https://build.torchapi.net/job/Torch/job/Torch/job/master/$TORCH_BUILD/artifact/bin/torch-server.zip -O /tmp/torch-server.zip && \
	unzip -d /torch-server /tmp/torch-server.zip && \
	rm /tmp/torch-server.zip

# Start supervisord
CMD ["supervisord", "-c", "/torch-server/supervisord.conf"]