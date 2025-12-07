#!/bin/bash

# ============================================
# JDownloader Fix Script
# Behebt das Problem mit mehrfach laufenden Instanzen
# ============================================

echo "========================================"
echo "  JDownloader Fix Script"
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

# Sicherheitsfrage
echo "Dieses Script wird:"
echo "  1. Alle laufenden JDownloader-Prozesse beenden"
echo "  2. Doppelte Autostart-Einträge entfernen"
echo "  3. JDownloader sauber neu starten"
echo ""
read -p "Fortfahren? (j/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[JjYy]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

echo ""
echo "=== Schritt 1: Alle JDownloader-Prozesse beenden ==="
info "Stoppe JDownloader Service..."
sudo systemctl stop jdownloader
sleep 2

info "Beende alle JDownloader-Prozesse..."
JDOWNLOADER_PIDS=$(pgrep -f "JDownloader.jar")

if [ ! -z "$JDOWNLOADER_PIDS" ]; then
    info "Gefundene Prozesse: $(echo $JDOWNLOADER_PIDS | wc -w)"
    sudo pkill -9 -f JDownloader.jar
    sleep 2
    success "Alle JDownloader-Prozesse beendet"
else
    success "Keine JDownloader-Prozesse gefunden"
fi

# Nochmal prüfen
REMAINING=$(pgrep -f "JDownloader.jar")
if [ ! -z "$REMAINING" ]; then
    error "Einige Prozesse konnten nicht beendet werden!"
    echo "Verbleibende PIDs: $REMAINING"
    exit 1
else
    success "Alle Prozesse erfolgreich beendet"
fi

echo ""
echo ""

# Schritt 2: Prüfe und entferne doppelte Autostart-Einträge
echo "=== Schritt 2: Prüfe Autostart-Einträge ==="

# Prüfe Cron-Jobs
info "Prüfe Cron-Jobs..."
CRON_BACKUP="/tmp/crontab_backup_$(date +%Y%m%d_%H%M%S)"

# Root Cron
ROOT_JDOWNLOADER_CRON=$(sudo crontab -l 2>/dev/null | grep -i jdownloader | grep -v "update-system")
if [ ! -z "$ROOT_JDOWNLOADER_CRON" ]; then
    warning "JDownloader-Einträge in Root Cron gefunden:"
    echo "$ROOT_JDOWNLOADER_CRON"
    echo ""
    read -p "Diese Einträge entfernen? (j/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        sudo crontab -l > "$CRON_BACKUP.root"
        sudo crontab -l | grep -v -i jdownloader | grep -v "update-system" | sudo crontab -
        success "Einträge entfernt (Backup: $CRON_BACKUP.root)"
    fi
else
    success "Keine problematischen Cron-Einträge gefunden"
fi

# User Cron
USER_JDOWNLOADER_CRON=$(crontab -l 2>/dev/null | grep -i jdownloader)
if [ ! -z "$USER_JDOWNLOADER_CRON" ]; then
    warning "JDownloader-Einträge in User Cron gefunden:"
    echo "$USER_JDOWNLOADER_CRON"
    echo ""
    read -p "Diese Einträge entfernen? (j/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        crontab -l > "$CRON_BACKUP.user"
        crontab -l | grep -v -i jdownloader | crontab -
        success "Einträge entfernt (Backup: $CRON_BACKUP.user)"
    fi
else
    success "Keine User Cron-Einträge gefunden"
fi

echo ""
echo ""

# Schritt 3: Prüfe Service-Konfiguration
echo "=== Schritt 3: Prüfe Service-Konfiguration ==="
info "Prüfe /etc/systemd/system/jdownloader.service..."

if [ ! -f /etc/systemd/system/jdownloader.service ]; then
    error "Service-Datei nicht gefunden!"
    echo ""
    echo "Erstelle Service-Datei neu? (j/n): "
    read -p "" -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        info "Erstelle Service-Datei..."
        sudo tee /etc/systemd/system/jdownloader.service > /dev/null <<EOF
[Unit]
Description=JDownloader Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /opt/JDownloader.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        success "Service-Datei erstellt"
    fi
else
    success "Service-Datei existiert"
    echo ""
    info "Inhalt der Service-Datei:"
    cat /etc/systemd/system/jdownloader.service
fi

echo ""
echo ""

# Schritt 4: Prüfe auf doppelte Service-Dateien
echo "=== Schritt 4: Prüfe auf doppelte Service-Dateien ==="
info "Suche nach weiteren Service-Dateien..."
ADDITIONAL_SERVICES=$(find /etc/systemd/system /lib/systemd/system -name "*jdownload*" 2>/dev/null | grep -v "jdownloader.service$")

if [ ! -z "$ADDITIONAL_SERVICES" ]; then
    warning "Zusätzliche Service-Dateien gefunden:"
    echo "$ADDITIONAL_SERVICES"
    echo ""
    echo "Diese könnten zu Konflikten führen!"
else
    success "Keine doppelten Service-Dateien gefunden"
fi

echo ""
echo ""

# Schritt 5: Systemd neu laden und Service starten
echo "=== Schritt 5: JDownloader neu starten ==="
info "Lade Systemd-Konfiguration neu..."
sudo systemctl daemon-reload
success "Systemd neu geladen"

info "Aktiviere JDownloader Service..."
sudo systemctl enable jdownloader
success "Service aktiviert"

info "Starte JDownloader..."
sudo systemctl start jdownloader
sleep 5

# Status prüfen
if systemctl is-active --quiet jdownloader; then
    success "JDownloader läuft!"
    echo ""
    systemctl status jdownloader --no-pager
else
    error "JDownloader konnte nicht gestartet werden!"
    echo ""
    echo "Zeige Logs:"
    sudo journalctl -u jdownloader -n 30 --no-pager
    exit 1
fi

echo ""
echo ""

# Finale Prüfung
echo "=== Finale Prüfung ==="
info "Prüfe laufende Prozesse..."
sleep 3
PROCESS_COUNT=$(ps aux | grep -i "JDownloader.jar" | grep -v grep | wc -l)

if [ $PROCESS_COUNT -eq 1 ]; then
    success "✓ PROBLEM BEHOBEN: Nur 1 JDownloader-Instanz läuft!"
elif [ $PROCESS_COUNT -gt 1 ]; then
    error "WARNUNG: Es laufen immer noch $PROCESS_COUNT Instanzen!"
    echo ""
    echo "Prozesse:"
    ps aux | grep -i "JDownloader.jar" | grep -v grep
else
    error "Keine JDownloader-Instanz läuft!"
fi

echo ""
echo "========================================"
echo "  Fix abgeschlossen!"
echo "========================================"
echo ""

# Empfehlungen
echo "Empfehlungen:"
echo "1. Prüfe den Status mit: sudo systemctl status jdownloader"
echo "2. Zeige Logs mit: sudo journalctl -u jdownloader -f"
echo "3. Bei erneutem Problem: ./diagnose-jdownloader.sh ausführen"
echo ""

# Zeige Prozesse
info "Aktuelle JDownloader-Prozesse:"
ps aux | grep -i "JDownloader.jar" | grep -v grep || echo "Keine gefunden"
echo ""
