FROM ghcr.io/linuxserver/baseimage-alpine:3.15

# set version label
ARG BUILD_DATE
ARG VERSION
ARG AUDIOBOOKSHELF_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="adepssimius"

# environment settings
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    curl \
    npm && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache --upgrade \
    nodejs \
    sudo && \
  npm config set unsafe-perm true && \
  echo "**** install Audiobookshelf ****" && \
  mkdir -p \
    /app/audiobookshelf && \
  if [ -z ${AUDIOBOOKSHELF_RELEASE+x} ]; then \
    AUDIOBOOKSHELF_RELEASE=$(curl -sX GET "https://api.github.com/repos/advplyr/audiobookshelf/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/audiobookshelf.tar.gz -L \
    "https://github.com/advplyr/audiobookshelf/archive/${AUDIOBOOKSHELF_RELEASE}.tar.gz" && \
  tar -xzf \
    /tmp/audiobookshelf.tar.gz -C \
    /app/audiobookshelf/ --strip-components=1 && \
  echo "**** install node modules ****" && \
  npm install --prefix /app/audiobookshelf && \
  echo "**** cleanup ****" && \
    apk del --purge \
    build-dependencies && \
  rm -rf \
    /root \
    /tmp/* && \
  mkdir -p \
    /root

# add local files
COPY root/ /

EXPOSE 80