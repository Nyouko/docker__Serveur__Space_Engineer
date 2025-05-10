FROM debian:bookworm-slim

# ---------------------------
# Configuration initiale
# ---------------------------
ARG DEBIAN_FRONTEND=noninteractive
ARG WINEBRANCH=stable
ARG WINEVERSION=9.0.0.0~bookworm-1

ENV WINEARCH=win64
ENV WINEDEBUG=-all
ENV WINEPREFIX=/srv/wine
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

WORKDIR /root

# ---------------------------
# Nettoyage des dépôts, installation et setup propre
# ---------------------------
RUN rm -f /etc/apt/sources.list /etc/apt/sources.list.d/* && \
    echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    dpkg --add-architecture i386 && \
    apt-get update -qq && \
    apt-get install -y -qq \
    curl wget gnupg2 ca-certificates \
    software-properties-common \
    cabextract xvfb \
    libfaudio0 libfaudio0:i386 \
    libstdc++6:i386 libc6:i386 libcurl4-gnutls-dev:i386 && \
    mkdir -p /opt/steamcmd && \
    curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C /opt/steamcmd && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources && \
    apt-get update -qq && \
    apt-get install -y -qq --install-recommends \
    winehq-${WINEBRANCH}=${WINEVERSION} \
    wine-${WINEBRANCH}-i386=${WINEVERSION} \
    wine-${WINEBRANCH}-amd64=${WINEVERSION} \
    wine-${WINEBRANCH}=${WINEVERSION} && \
    curl -sSL https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -o /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks

# ---------------------------
# Création de l'utilisateur
# ---------------------------
RUN useradd -m -U userauthorized && \
    chown -R userauthorized:userauthorized /mnt /srv /opt/steamcmd

COPY --chown=userauthorized:userauthorized healthcheck.sh entrypoint.sh /home/userauthorized/

WORKDIR /home/userauthorized
USER userauthorized

# Script Winetricks (peut être long)
COPY winetricks.sh /home/userauthorized/
RUN /home/userauthorized/winetricks.sh && \
    rm -f /home/userauthorized/winetricks.sh

# ---------------------------
# Nettoyage final
# ---------------------------
USER root
RUN apt-get purge -y -qq cabextract gnupg2 && \
    apt-get autoremove -y -qq && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /usr/share/doc /usr/share/man /usr/share/locale

# ---------------------------
# Entrée et healthcheck
# ---------------------------
USER userauthorized
HEALTHCHECK --interval=60s --timeout=60s --start-period=600s --retries=3 CMD [ "/home/userauthorized/healthcheck.sh" ]
ENTRYPOINT ["/home/userauthorized/entrypoint.sh"]
