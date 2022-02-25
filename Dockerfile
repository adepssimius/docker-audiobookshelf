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
    curl && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache --upgrade \
    ffmpeg \
    nodejs \
    npm && \
  npm config set unsafe-perm true && \
  echo "**** download latest audiobookshelf release ****" && \
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
    /app/audiobookshelf/ --strip-components=1

WORKDIR /app/audiobookshelf/client
RUN npm install
RUN npm run generate
RUN mv /app/audiobookshelf/client/dist /tmp/dist
RUN rm -rf /app/audiobookshelf/client
RUN mkdir -p /app/audiobookshelf/client
RUN mv /tmp/dist /app/audiobookshelf/client/
ENV NODE_ENV=production
WORKDIR /app/audiobookshelf
RUN npm ci --production


RUN \
echo "**** cleanup ****" && \
   apk del --purge \
   build-dependencies

# add local files
COPY root/ /

EXPOSE 80
CMD ["npm", "start"]