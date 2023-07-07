FROM i386/alpine

ENV \
  WINEDEBUG="-all" \
	WINEARCH="win32" \
	WINEPREFIX="/root/.wine/" \
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
  POST_GAME_TIME_LIMIT="15"

RUN apk add --no-cache \ 
  'wine' \
	'xvfb-run' \
	'findutils' \
	'tini' \
	'sudo' \
	'wget' && \
	mkdir /tmp/SWAT4 /tmp/TSS && \
	wget -q -nc --show-progress --progress=bar:force:noscroll --no-hsts -O /tmp/SWAT4/Engine.dll --user-agent=Mozilla --content-disposition -E -c "https://raw.githubusercontent.com/sergeii/swat-patches/master/swat4stats-masterserver/1.1/Engine.dll" && \
	wget -q -nc --show-progress --progress=bar:force:noscroll --no-hsts -O /tmp/TSS/Engine.dll --user-agent=Mozilla --content-disposition -E -c "https://raw.githubusercontent.com/sergeii/swat-patches/master/swat4stats-masterserver/TSS/Engine.dll" && \
	apk --purge del wget && \
	wineboot --init

WORKDIR /swat4

EXPOSE 10480-10483/udp

COPY	./entrypoint.sh /usr/bin/entrypoint.sh
CMD	[ "/sbin/tini", "--", "/usr/bin/entrypoint.sh" ]
LABEL \
  org.opencontainers.image.authors="Kevin Moore" \
  org.opencontainers.image.title="SWAT 4 Docker" \
  org.opencontainers.image.description="Docker container for running a SWAT 4 Dedicated Server" \
  org.opencontainers.image.source=https://github.com/MisterCalvin/swat4-server-docker \
  org.opencontainers.image.version="1.0" \
  org.opencontainers.image.licenses=MIT
