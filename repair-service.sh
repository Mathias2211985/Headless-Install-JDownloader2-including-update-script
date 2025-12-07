#!/bin/bash

# ============================================
# JDownloader Service-Datei reparieren
# ============================================

echo "========================================"
echo "  Service-Datei Reparatur"
echo "========================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

success() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${YELLOW}→${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

echo "=== Schritt 1: Stoppe JDownloader ==="
info "Stoppe Service..."
sudo systemctl stop jdownloader
sleep 2
success "Service gestoppt"

echo ""
echo "=== Schritt 2: Prüfe wo JDownloader.jar liegt ==="
if [ -f "/opt/JDownloader.jar" ]; then
    success "JDownloader.jar gefunden in /opt"
    JDOWNLOADER_PATH="/opt"
    JDOWNLOADER_JAR="/opt/JDownloader.jar"
elif [ -f "/opt/JDownloader/JDownloader.jar" ]; then
    success "JDownloader.jar gefunden in /opt/JDownloader"
    JDOWNLOADER_PATH="/opt/JDownloader"
    JDOWNLOADER_JAR="/opt/JDownloader/JDownloader.jar"
else
    error "JDownloader.jar nicht gefunden!"
    echo ""
    echo "Bitte prüfe mit: find /opt -name 'JDownloader.jar'"
    exit 1
fi

echo ""
echo "=== Schritt 3: Erstelle korrekte Service-Datei ==="
info "Sichere alte Service-Datei..."
if [ -f /etc/systemd/system/jdownloader.service ]; then
    sudo cp /etc/systemd/system/jdownloader.service /etc/systemd/system/jdownloader.service.backup
    success "Backup erstellt: jdownloader.service.backup"
fi

info "Erstelle neue Service-Datei mit korrekten Pfaden..."
sudo tee /etc/systemd/system/jdownloader.service > /dev/null <<EOF
[Unit]
Description=JDownloader Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=$JDOWNLOADER_PATH
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar $JDOWNLOADER_JAR
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

success "Service-Datei erstellt"
echo ""
info "Neue Service-Datei:"
cat /etc/systemd/system/jdownloader.service

echo ""
echo "=== Schritt 4: Systemd neu laden und starten ==="
info "Lade Systemd neu..."
sudo systemctl daemon-reload
success "Systemd neu geladen"

info "Starte JDownloader..."
sudo systemctl start jdownloader
sleep 5

if systemctl is-active --quiet jdownloader; then
    success "✓ JDownloader läuft!"
    echo ""
    systemctl status jdownloader --no-pager
else
    error "JDownloader konnte nicht gestartet werden!"
    echo ""
    sudo journalctl -u jdownloader -n 20 --no-pager
    exit 1
fi

echo ""
echo "=== Finale Prüfung ==="
sleep 3
PROCESS_COUNT=$(ps aux | grep "JDownloader.jar" | grep -v grep | wc -l)

if [ $PROCESS_COUNT -eq 1 ]; then
    success "✓ JDownloader läuft korrekt (1 Prozess)"
    echo ""
    ps aux | grep "JDownloader.jar" | grep -v grep
elif [ $PROCESS_COUNT -gt 1 ]; then
    error "WARNUNG: $PROCESS_COUNT Prozesse laufen!"
else
    error "Kein Prozess läuft!"
fi

echo ""
echo "========================================"
echo "  Reparatur abgeschlossen!"
echo "========================================"
echo ""
echo "Verwendete Pfade:"
echo "  WorkingDirectory: $JDOWNLOADER_PATH"
echo "  JAR-Datei: $JDOWNLOADER_JAR"
echo ""
