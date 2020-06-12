#
# firefox Dockerfile
#

# Pull base image.
FROM jlesage/baseimage-gui:ubuntu-18.04

RUN apt-get update && apt-get install -y curl software-properties-common && add-apt-repository -y ppa:ubuntu-mozilla-security/ppa && apt-get update && apt-get install -y firefox

ARG JSONLZ4_VERSION=c4305b8
ARG LZ4_VERSION=1.8.1.2
ARG JSONLZ4_URL=https://github.com/avih/dejsonlz4/archive/${JSONLZ4_VERSION}.tar.gz
ARG LZ4_URL=https://github.com/lz4/lz4/archive/v${LZ4_VERSION}.tar.gz

WORKDIR /tmp
RUN apt-get install -y gcc build-essential && \
    mkdir jsonlz4 && \
    mkdir lz4 && \
    curl -# -L {$JSONLZ4_URL} | tar xz --strip 1 -C jsonlz4 && \
    curl -# -L {$LZ4_URL} | tar xz --strip 1 -C lz4 && \
    mv jsonlz4/src/ref_compress/*.c jsonlz4/src/ && \
    cp lz4/lib/lz4.* jsonlz4/src/ && \
    cd jsonlz4 && \
    gcc -static -Wall -o dejsonlz4 src/dejsonlz4.c src/lz4.c && \
    gcc -static -Wall -o jsonlz4 src/jsonlz4.c src/lz4.c && \
    strip dejsonlz4 jsonlz4 && \
    cp -v dejsonlz4 /usr/bin/ && \
    cp -v jsonlz4 /usr/bin/ && \
    cd .. && \
    # Cleanup.
    rm -rf tmp/* /tmp/.[!.]* && \
    apt-get remove -y gcc build-essential

# Set default settings.
RUN \
    CFG_FILE="/usr/lib/firefox/browser/defaults/preferences/firefox-branding.js" && \
    echo '' >> "$CFG_FILE" && \
    echo '// Default download directory.' >> "$CFG_FILE" && \
    echo 'pref("browser.download.dir", "/config/downloads");' >> "$CFG_FILE" && \
    echo 'pref("browser.download.folderList", 2);' >> "$CFG_FILE"

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/firefox-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="Firefox"

# Define mountable directories.
VOLUME ["/config"]

# Metadata.
LABEL \
      org.label-schema.name="firefox" \
      org.label-schema.description="Docker container for Firefox" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/acaranta/docker-firefox" \
      org.label-schema.schema-version="1.0"
