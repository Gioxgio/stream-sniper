# syntax=docker/dockerfile:1

# ---- builder: compile stream-sniper and install it under /usr/local ----
FROM alpine:3.24 AS builder

# build-base: gcc + make; curl-dev: libcurl headers + pkg-config file,
# which the Makefile uses for its link flags.
RUN apk add --no-cache build-base pkgconf curl-dev

WORKDIR /src
COPY . .

# make install: binary -> /usr/local/bin/stream-sniper,
# ffmpeg-quiet + ffprobe -> /usr/local/libexec/stream-sniper
RUN make && make install PREFIX=/usr/local

# ---- runtime ----
FROM alpine:3.24

# libcurl: stream-sniper's only runtime library. ffmpeg installs to
# /usr/bin/ffmpeg, exactly where the wrappers look by default.
# python3: the standalone yt-dlp binary is a Python zipapp.
# curl: fetches yt-dlp below, and is handy for debugging inside.
RUN apk add --no-cache libcurl ffmpeg ca-certificates python3 curl \
    && curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
       -o /usr/local/bin/yt-dlp \
    && chmod 0755 /usr/local/bin/yt-dlp

COPY --from=builder /usr/local/bin/stream-sniper /usr/local/bin/stream-sniper
COPY --from=builder /usr/local/libexec/stream-sniper/ /usr/local/libexec/stream-sniper/

ENV SS_WRAPPER_DIR=/usr/local/libexec/stream-sniper

WORKDIR /data
# Template channel list; a compose/bind mount over /data/channels.txt
# (or a rebuilt image with the real list) overrides it.
COPY channels.txt.example /data/channels.txt

ENTRYPOINT ["stream-sniper"]
CMD ["/data/channels.txt", "-o", "/data/recordings"]
