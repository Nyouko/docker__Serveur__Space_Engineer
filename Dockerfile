# ========================
# Étape 1 : Build
# ========================
FROM debian:bookworm-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG WINEBRANCH=stable
ARG WINEVERSION=9.0.0.0~bookworm-1

ENV WINEARCH=win64
ENV WINEDEBUG=-all
ENV WINEPREFIX=/srv/wine
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

RUN rm -f /etc/apt/sources.list /etc/apt/sources.list.d/* && \
    echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    dpkg --add-architecture i386 && \
    apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
    curl wget ca-certificates gnupg2 cabextract xvfb libfaudio0 libfaudio0:i386 \
    libstdc++6:i386 libc6:i386 libcurl4-gnutls-dev:i386 && \
    mkdir -p /opt/steamcmd && \
    curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C /opt/steamcmd && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources && \
    apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
    winehq-${WINEBRANCH}=${WINEVERSION} \
    wine-${WINEBRANCH}-i386=${WINEVERSION} \
    wine-${WINEBRANCH}-amd64=${WINEVERSION} \
    wine-${WINEBRANCH}=${WINEVERSION} && \
    curl -sSL https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -o /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks && \
    useradd -m -U userauthorized && \
    chown -R userauthorized:userauthorized /srv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chown=userauthorized:userauthorized healthcheck.sh entrypoint.sh winetricks.sh /home/userauthorized/

WORKDIR /home/userauthorized
USER userauthorized

RUN /home/userauthorized/winetricks.sh && rm /home/userauthorized/winetricks.sh

# ========================
# Étape 2 : Image finale
# ========================
FROM debian:bookworm-slim

ARG WINEBRANCH=stable
ENV WINEARCH=win64
ENV WINEDEBUG=-all
ENV WINEPREFIX=/srv/wine
ENV PATH="/opt/wine-stable/bin:/opt/steamcmd:${PATH}"
ENV LD_LIBRARY_PATH="/opt/wine-stable/lib:/opt/wine-stable/lib64"

RUN useradd -m -U userauthorized && \
    chown -R userauthorized:userauthorized /mnt

COPY --from=builder --chown=userauthorized:userauthorized /opt/steamcmd /opt/steamcmd
COPY --from=builder --chown=userauthorized:userauthorized /srv /srv
COPY --from=builder --chown=userauthorized:userauthorized /usr/local/bin/winetricks /usr/local/bin/winetricks
COPY --from=builder --chown=userauthorized:userauthorized /home/userauthorized /home/userauthorized
COPY --from=builder --chown=userauthorized:userauthorized /etc/fonts /etc/fonts
COPY --from=builder --chown=userauthorized:userauthorized /lib/ld-linux.so.2 /lib/ld-linux.so.2
COPY --from=builder --chown=userauthorized:userauthorized /lib/i386-linux-gnu /lib/i386-linux-gnu
COPY --from=builder --chown=userauthorized:userauthorized /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
# Copie sélective de Wine
COPY --from=builder --chown=userauthorized:userauthorized /opt/wine-stable /opt/wine-stable

# Nettoyage : supprime les fichiers inutiles pour réduire la taille
RUN rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/locale/* && \
    find /opt/wine-stable -name '*.a' -delete && \
    find /opt/wine-stable -name '*.la' -delete && \
    find /opt/wine-stable -name '*.pyc' -delete && \
    apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/userauthorized
USER userauthorized

HEALTHCHECK --interval=60s --timeout=60s --start-period=600s --retries=3 CMD [ "/home/userauthorized/healthcheck.sh" ]
ENTRYPOINT ["/home/userauthorized/entrypoint.sh"]
