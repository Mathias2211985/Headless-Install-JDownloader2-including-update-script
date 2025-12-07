#!/bin/bash

# ============================================
# JDownloader Installation Script
# Installiert JDownloader komplett neu
# ============================================

echo "========================================"
echo "  JDownloader Installation"
echo "========================================"
echo ""

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${YELLOW}→${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Prüfe ob bereits installiert
echo "=== Schritt 1: Prüfe bestehende Installation ==="
if [ -f "/opt/JDownloader.jar" ]; then
    info "JDownloader ist bereits in /opt installiert"
    ls -la /opt/JDownloader.jar
    echo ""
    read -p "Möchtest du die Installation neu durchführen? (j/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        info "Sichere alte Installation..."
        sudo mv /opt/JDownloader.jar /opt/JDownloader.jar.backup.$(date +%Y%m%d_%H%M%S)
        [ -d "/opt/cfg" ] && sudo mv /opt/cfg /opt/cfg.backup.$(date +%Y%m%d_%H%M%S)
        success "Backup erstellt"
    else
        echo "Installation abgebrochen."
        exit 0
    fi
fi

echo ""
echo "=== Schritt 2: Java prüfen/installieren ==="
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    success "Java ist installiert: $JAVA_VERSION"
else
    info "Java wird installiert..."
    sudo apt update
    sudo apt install default-jre -y
    
    if command -v java &> /dev/null; then
        success "Java erfolgreich installiert"
    else
        error "Java Installation fehlgeschlagen!"
        exit 1
    fi
fi

echo ""
echo "=== Schritt 3: Vorbereitung ==="
info "Stelle sicher, dass /opt beschreibbar ist..."
sudo chown -R $USER:$USER /opt
success "Berechtigungen gesetzt"

echo ""
echo "=== Schritt 4: JDownloader herunterladen ==="
cd /opt
info "Lade JDownloader.jar herunter..."

if wget -O JDownloader.jar http://installer.jdownloader.org/JDownloader.jar; then
    success "JDownloader.jar heruntergeladen"
else
    error "Download fehlgeschlagen!"
    exit 1
fi

# Prüfe ob Datei existiert
if [ -f "JDownloader.jar" ]; then
    FILE_SIZE=$(du -h JDownloader.jar | cut -f1)
    success "Datei vorhanden (Größe: $FILE_SIZE)"
else
    error "JDownloader.jar nicht gefunden!"
    exit 1
fi

echo ""
echo "=== Schritt 5: JDownloader initialisieren ==="
info "Starte JDownloader erstmalig (dies kann einige Minuten dauern)..."
echo "Hinweis: Der Prozess wird nach 2 Minuten automatisch beendet."
echo ""

# Starte JDownloader im Hintergrund und beende nach 120 Sekunden
timeout 120s java -Djava.awt.headless=true -jar JDownloader.jar -norestart &
JDOWNLOADER_PID=$!

# Warte und zeige Fortschritt
for i in {1..120}; do
    if ! ps -p $JDOWNLOADER_PID > /dev/null 2>&1; then
        break
    fi
    if [ $((i % 10)) -eq 0 ]; then
        echo "  ... $i Sekunden vergangen ..."
    fi
    sleep 1
done

# Beende JDownloader wenn noch läuft
if ps -p $JDOWNLOADER_PID > /dev/null 2>&1; then
    kill $JDOWNLOADER_PID 2>/dev/null || true
    sleep 2
fi

success "JDownloader initialisiert"

# Prüfe ob notwendige Dateien erstellt wurden
echo ""
echo ""
info "Prüfe Installation..."
if [ -f "/opt/JDownloader.jar" ]; then
    success "JDownloader.jar vorhanden"
else
    error "JDownloader.jar fehlt!"
    exit 1
fi
echo ""
echo "=== Schritt 6: Systemd Service einrichten ==="
info "Erstelle Service-Datei..."

sudo tee /etc/systemd/system/jdownloader.service > /dev/null <<EOF
[Unit]
Description=JDownloader Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /opt/JDownloader.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

success "Service-Datei erstellt"

echo ""
echo "=== Schritt 7: Service aktivieren und starten ==="
info "Lade Systemd neu..."
sudo systemctl daemon-reload

info "Aktiviere JDownloader Service..."
sudo systemctl enable jdownloader

info "Starte JDownloader Service..."
sudo systemctl start jdownloader

# Warte kurz
sleep 5

# Prüfe Status
if systemctl is-active --quiet jdownloader; then
    success "JDownloader Service läuft!"
    echo ""
    systemctl status jdownloader --no-pager
else
    error "Service konnte nicht gestartet werden!"
    echo ""
    echo "Zeige Logs:"
    sudo journalctl -u jdownloader -n 30 --no-pager
    exit 1
fi

echo ""
echo "=== Schritt 8: Finale Prüfung ==="
sleep 5
PROCESS_COUNT=$(ps aux | grep "JDownloader.jar" | grep -v grep | wc -l)

if [ $PROCESS_COUNT -eq 1 ]; then
    success "✓ JDownloader läuft korrekt (1 Prozess)"
elif [ $PROCESS_COUNT -gt 1 ]; then
    error "WARNUNG: $PROCESS_COUNT Prozesse laufen!"
else
    error "Kein JDownloader-Prozess läuft!"
fi

echo ""
echo "========================================"
echo "  Installation abgeschlossen!"
echo "========================================"
echo ""

# Informationen
info "Nützliche Befehle:"
echo "  Status prüfen:     sudo systemctl status jdownloader"
echo "  Logs anzeigen:     sudo journalctl -u jdownloader -f"
echo "  Service stoppen:   sudo systemctl stop jdownloader"
echo "  Service starten:   sudo systemctl start jdownloader"
echo "  Service neustarten: sudo systemctl restart jdownloader"
echo ""

info "Zugriff auf JDownloader:"
echo "  Web-Interface:     http://$(hostname -I | awk '{print $1}'):8080"
echo "  MyJDownloader:     https://my.jdownloader.org"
echo ""

info "Weitere Schritte:"
echo "  1. Verbinde JDownloader mit MyJDownloader-Account"
echo "  2. Konfiguriere Download-Pfad"
echo "  3. Installiere update-system.sh für automatische Updates"
echo ""
