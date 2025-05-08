# Utilise une image de base légère
FROM debian:bookworm-slim

# Variables d'environnement de base
ENV DEBIAN_FRONTEND=noninteractive \
    WINEPREFIX=/home/spaceuser/.wine \
    WINEDLLOVERRIDES="mscoree=d;mshtml=d" \
    DISPLAY=:0

# Ajout d'un utilisateur non-root
RUN useradd -m spaceuser

# Mise à jour et installation minimale de Wine + dépendances
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wine \
    winetricks \
    xvfb \
    unzip \
    wget \
    cabextract \
    ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Copie des fichiers utiles
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
COPY winetricks.sh /winetricks.sh

# Donne les droits à l'utilisateur
RUN chown -R spaceuser:spaceuser /entrypoint.sh /healthcheck.sh /winetricks.sh && \
    chmod +x /entrypoint.sh /healthcheck.sh /winetricks.sh

# Définit l'utilisateur non-root
USER spaceuser

# Répertoire de travail
WORKDIR /home/spaceuser

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Healthcheck (optionnel)
HEALTHCHECK --interval=30s --timeout=10s CMD /healthcheck.sh || exit 1
