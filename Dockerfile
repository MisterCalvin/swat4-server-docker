FROM i386/alpine

ARG S6_OVERLAY_VERSION=3.1.5.0

ENV \
  WINEDEBUG="-all" \
  WINEARCH="win32" \
  WINEPREFIX="/container/.wine/" \
  CONTENT_VERSION="SWAT4" \
  SERVER_NAME="A SWAT4 Docker Server" \
  SERVER_PASSWORD="" \
  GAME_TYPE="CO-OP" \
  MAP="SP-FairfaxResidence" \
  LAN_ONLY="False" \
  MAX_PLAYERS="10" \
  ADMIN_PASSWORD="" \
  NUM_ROUNDS="15" \
  ROUND_TIME_LIMIT="900" \
  DEATH_LIMIT="50" \
  MP_MISSION_READY_TIME="90" \
  POST_GAME_TIME_LIMIT="15" \
  PUID="1000" \
  PGID="1000" \
  S6_VERBOSITY="0"

RUN apk add --no-cache \ 
  	'wine' \
	'xvfb-run' \
	'findutils' \
	'shadow' \
	'wget' && \
	mkdir /tmp/SWAT4 /tmp/TSS && \
	wget -q -nc --show-progress --progress=bar:force:noscroll --no-hsts -O /tmp/SWAT4/Engine.dll --user-agent=Mozilla --content-disposition -E -c "https://raw.githubusercontent.com/sergeii/swat-patches/master/swat4stats-masterserver/1.1/Engine.dll" && \
	wget -q -nc --show-progress --progress=bar:force:noscroll --no-hsts -O /tmp/TSS/Engine.dll --user-agent=Mozilla --content-disposition -E -c "https://raw.githubusercontent.com/sergeii/swat-patches/master/swat4stats-masterserver/TSS/Engine.dll" && \
	wget -q -nc --show-progress --progress=bar:force:noscroll --no-hsts -O /tmp/s6-overlay-noarch.tar.xz --user-agent=Mozilla --content-disposition -E -c "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" && \
	wget -q -nc --show-progress --progress=bar:force:noscroll --no-hsts -O /tmp/s6-overlay-x86_64.tar.xz --user-agent=Mozilla --content-disposition -E -c "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" && \
	tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
	tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
	rm /tmp/*.tar.xz && \
	apk --purge del wget && \
	mkdir -m 760 /container && \
	wineboot -i && \
	addgroup --gid $PGID wine && \
	adduser --uid $PUID --home /container --disabled-password --no-create-home --shell /bin/false --ingroup wine wine && \
	chown -R wine:wine /container

WORKDIR /container/swat4

COPY	./root /
COPY ./swat4.sh /usr/bin/swat4.sh

EXPOSE 10480-10483/udp

ENTRYPOINT [ "/init" ]
LABEL \
  org.opencontainers.image.authors="Kevin Moore" \
  org.opencontainers.image.title="SWAT 4 Docker" \
  org.opencontainers.image.description="Docker container for running a SWAT 4 Dedicated Server" \
  org.opencontainers.image.source=https://github.com/MisterCalvin/swat4-server-docker \
  org.opencontainers.image.version="1.0" \
  org.opencontainers.image.licenses=MIT
