#!/bin/bash

# ============================================
# Raspberry Pi System & JDownloader Update Script
# ============================================

echo "========================================"
echo "  System & JDownloader Update"
echo "========================================"
echo ""

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funktion für Erfolg
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Funktion für Info
info() {
    echo -e "${YELLOW}→${NC} $1"
}

# Funktion für Fehler
error() {
    echo -e "${RED}✗${NC} $1"
}

# 1. System Updates
echo "=== System Updates ==="
info "Aktualisiere Paketlisten..."
if sudo apt update; then
    success "Paketlisten aktualisiert"
else
    error "Fehler beim Aktualisieren der Paketlisten"
    exit 1
fi

echo ""
info "Installiere Updates..."
if sudo apt upgrade -y; then
    success "System aktualisiert"
else
    error "Fehler beim Aktualisieren des Systems"
    exit 1
fi

echo ""
info "Entferne nicht mehr benötigte Pakete..."
if sudo apt autoremove -y; then
    success "Aufgeräumt"
else
    error "Fehler beim Aufräumen"
fi

echo ""
info "Räume Paket-Cache auf..."
if sudo apt autoclean; then
    success "Cache geleert"
else
    error "Fehler beim Leeren des Cache"
fi

# 2. JDownloader Updates
echo ""
echo "=== JDownloader Update ==="
info "Prüfe JDownloader Status..."

if systemctl is-active --quiet jdownloader; then
    info "Stoppe JDownloader für Update..."
    sudo systemctl stop jdownloader
    sleep 2
    JDOWNLOADER_WAS_RUNNING=true
else
    info "JDownloader läuft nicht"
    JDOWNLOADER_WAS_RUNNING=false
fi

if [ -f "/opt/JDownloader/JDownloader.jar" ]; then
    info "JDownloader gefunden, starte Update..."
    cd /opt/JDownloader
    
    # Update im Hintergrund, max 60 Sekunden warten
    timeout 60s sudo java -jar JDownloader.jar -update 2>/dev/null || true
    
    success "JDownloader Update durchgeführt"
else
    error "JDownloader.jar nicht gefunden in /opt/JDownloader"
fi

# JDownloader wieder starten wenn er vorher lief
if [ "$JDOWNLOADER_WAS_RUNNING" = true ]; then
    info "Starte JDownloader neu..."
    sudo systemctl start jdownloader
    sleep 5
    
    if systemctl is-active --quiet jdownloader; then
        success "JDownloader läuft wieder"
    else
        error "JDownloader konnte nicht gestartet werden - prüfe Logs mit: sudo journalctl -u jdownloader -n 30"
    fi
else
    info "JDownloader wurde nicht automatisch gestartet (lief vorher nicht)"
fi

# 3. Zusammenfassung
echo ""
echo "========================================"
echo "  Update abgeschlossen!"
echo "========================================"
echo ""

# Zeige System-Infos
info "System-Informationen:"
echo "  Hostname: $(hostname)"
echo "  IP-Adresse: $(hostname -I | awk '{print $1}')"
echo "  Uptime: $(uptime -p)"
echo "  Freier Speicher: $(df -h / | awk 'NR==2 {print $4}')"
echo ""

# Prüfe ob Neustart nötig ist
if [ -f /var/run/reboot-required ]; then
    echo -e "${YELLOW}⚠${NC}  Ein Neustart wird empfohlen!"
    echo "   Führe aus: sudo reboot"
else
    success "Kein Neustart erforderlich"
fi

echo ""
