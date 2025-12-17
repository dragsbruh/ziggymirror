FROM alpine:latest

ENV HTTP_DIR="/srv/http"

ENV PORT=80
ENV TEMP_DIR=/tmp/zigtemp
ENV DOWNLOAD_CONCURRENCY=4
ENV SYNC_INTERVAL=86400
ENV DOWNLOAD_INDEX=https://ziglang.org/download/index.json
ENV COMMUNITY_MIRRORS_FALLBACK=/src/community-mirrors.txt
ENV AUTOMATION_SOURCE=github-dragsbruh-ziggymirror
ENV MINISIGN_PUBKEY=RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U
ENV COMMUNITY_MIRRORS_URL=https://ziglang.org/download/community-mirrors.txt
ENV COMMUNITY_MIRRORS_CUSTOM=
ENV SYNC_MASTER=

RUN apk add --no-cache bash jq minisign wget busybox-extras tini

RUN mkdir $(dirname "${COMMUNITY_MIRRORS_FALLBACK}")
RUN wget -O "${COMMUNITY_MIRRORS_FALLBACK}" "$COMMUNITY_MIRRORS_URL"

COPY ./run.sh ./sync.sh ./template.sh /src/

ENTRYPOINT ["/sbin/tini", "--"]
CMD [ "/src/run.sh" ]
