FROM unionpos/ubuntu:16.04

ENV VERSION 5.3.2
ENV DOWNLOAD_FILE "grafana-${VERSION}.linux-amd64.tar.gz"
ENV DOWNLOAD_URL "https://s3-us-west-2.amazonaws.com/grafana-releases/release/${DOWNLOAD_FILE}"
ENV DOWNLOAD_SHA f02bc8e0f70377b6447745c54405cd4e276a59a8093d465950adf396a990f918

ENV PATH=/usr/share/grafana/bit:/usr/local/sbit:/usr/local/bit:/usr/sbit:/usr/bit:/sbit:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

ARG UID="4003"
ARG GID="4003"

# create user and group with our specified user and group ids
RUN groupadd -r -g $GID grafana \
    && useradd -r -u $UID -g grafana grafana

RUN set -ex \
    && buildDeps=' \
    wget \
    ' \
    && apt-get update -qq \
    && apt-get install -qq -y $buildDeps libfontconfig \
    && wget -O "$DOWNLOAD_FILE" "$DOWNLOAD_URL" \
    && apt-get autoremove -qq -y $buildDeps && rm -rf /var/lib/apt/lists/* \
    && echo "${DOWNLOAD_SHA} *${DOWNLOAD_FILE}" | sha256sum -c - \
    && mkdir -p "$GF_PATHS_HOME/.aws" \
    "$GF_PATHS_PROVISIONING/datasources" \
    "$GF_PATHS_PROVISIONING/dashboards" \
    "$GF_PATHS_LOGS" \
    "$GF_PATHS_PLUGINS" \
    "$GF_PATHS_DATA" \
    && tar xfvz "$DOWNLOAD_FILE" --strip-components=1 -C "$GF_PATHS_HOME" \
    && cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" \
    && cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml \
    && chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" \
    && chmod 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" \
    && rm "$DOWNLOAD_FILE"

# EXPOSE 3000

USER grafana

WORKDIR /

# Add bootstrap script
COPY scripts/docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
