#!/bin/bash

# ============================================
# JDownloader Diagnose Script
# ============================================

echo "========================================"
echo "  JDownloader Diagnose"
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

# Funktion für Warnung
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Funktion für Fehler
error() {
    echo -e "${RED}✗${NC} $1"
}

# 1. Prüfe alle laufenden JDownloader-Prozesse
echo "=== JDownloader Prozesse ==="
info "Suche nach laufenden JDownloader-Prozessen..."
JDOWNLOADER_PROCESSES=$(ps aux | grep -i "JDownloader.jar" | grep -v grep)

if [ -z "$JDOWNLOADER_PROCESSES" ]; then
    error "Keine JDownloader-Prozesse gefunden!"
else
    PROCESS_COUNT=$(echo "$JDOWNLOADER_PROCESSES" | wc -l)
    
    if [ $PROCESS_COUNT -gt 1 ]; then
        error "PROBLEM: Es laufen $PROCESS_COUNT JDownloader-Instanzen!"
        echo ""
        echo "Prozesse:"
        echo "$JDOWNLOADER_PROCESSES"
    else
        success "Es läuft nur 1 JDownloader-Prozess (OK)"
        echo ""
        echo "Prozess:"
        echo "$JDOWNLOADER_PROCESSES"
    fi
fi

echo ""
echo ""

# 2. Prüfe systemd Service Status
echo "=== Systemd Service Status ==="
info "Prüfe JDownloader Service..."
if systemctl is-active --quiet jdownloader; then
    success "JDownloader Service ist aktiv"
    echo ""
    systemctl status jdownloader --no-pager
else
    error "JDownloader Service ist nicht aktiv!"
    echo ""
    systemctl status jdownloader --no-pager
fi

echo ""
echo ""

# 3. Prüfe ob Service mehrfach definiert ist
echo "=== Service-Dateien ==="
info "Suche nach JDownloader Service-Dateien..."
SERVICE_FILES=$(find /etc/systemd/system /lib/systemd/system -name "*jdownloader*" 2>/dev/null)

if [ -z "$SERVICE_FILES" ]; then
    error "Keine Service-Dateien gefunden!"
else
    echo "$SERVICE_FILES"
fi

echo ""
echo ""

# 4. Prüfe Cron-Jobs (könnte automatisch starten)
echo "=== Cron-Jobs ==="
info "Prüfe Cron-Jobs für JDownloader..."
CRON_JOBS=$(sudo crontab -l 2>/dev/null | grep -i jdownloader)
USER_CRON=$(crontab -l 2>/dev/null | grep -i jdownloader)

if [ -z "$CRON_JOBS" ] && [ -z "$USER_CRON" ]; then
    success "Keine Cron-Jobs für JDownloader gefunden (OK)"
else
    warning "Cron-Jobs gefunden:"
    [ ! -z "$CRON_JOBS" ] && echo "Root Cron: $CRON_JOBS"
    [ ! -z "$USER_CRON" ] && echo "User Cron: $USER_CRON"
fi

echo ""
echo ""

# 5. Prüfe @reboot Einträge
echo "=== Autostart-Einträge ==="
info "Prüfe auf @reboot Einträge..."
REBOOT_ENTRIES=$(sudo crontab -l 2>/dev/null | grep "@reboot.*jdownloader" -i)
USER_REBOOT=$(crontab -l 2>/dev/null | grep "@reboot.*jdownloader" -i)

if [ -z "$REBOOT_ENTRIES" ] && [ -z "$USER_REBOOT" ]; then
    success "Keine @reboot Einträge gefunden (OK)"
else
    warning "@reboot Einträge gefunden (könnte Doppelstart verursachen):"
    [ ! -z "$REBOOT_ENTRIES" ] && echo "Root: $REBOOT_ENTRIES"
    [ ! -z "$USER_REBOOT" ] && echo "User: $USER_REBOOT"
fi

echo ""
echo ""

# 6. Prüfe rc.local
echo "=== rc.local Einträge ==="
if [ -f /etc/rc.local ]; then
    info "Prüfe /etc/rc.local..."
    RC_LOCAL=$(grep -i jdownloader /etc/rc.local 2>/dev/null)
    if [ -z "$RC_LOCAL" ]; then
        success "Keine JDownloader-Einträge in rc.local (OK)"
    else
        warning "JDownloader-Einträge in rc.local gefunden:"
        echo "$RC_LOCAL"
    fi
else
    success "/etc/rc.local existiert nicht (OK)"
fi

echo ""
echo ""

# 7. Prüfe .bashrc oder .profile
echo "=== Benutzer-Autostart ==="
info "Prüfe .bashrc und .profile..."
BASHRC_ENTRIES=$(grep -i jdownloader ~/.bashrc 2>/dev/null)
PROFILE_ENTRIES=$(grep -i jdownloader ~/.profile 2>/dev/null)

if [ -z "$BASHRC_ENTRIES" ] && [ -z "$PROFILE_ENTRIES" ]; then
    success "Keine Autostart-Einträge in Benutzer-Profil (OK)"
else
    warning "Autostart-Einträge gefunden:"
    [ ! -z "$BASHRC_ENTRIES" ] && echo ".bashrc: $BASHRC_ENTRIES"
    [ ! -z "$PROFILE_ENTRIES" ] && echo ".profile: $PROFILE_ENTRIES"
fi

echo ""
echo ""

# 8. Port-Überprüfung
echo "=== Port-Belegung ==="
info "Prüfe Port 8080 (JDownloader Web-Interface)..."
PORT_8080=$(sudo netstat -tulpn 2>/dev/null | grep ":8080" || sudo ss -tulpn 2>/dev/null | grep ":8080")

if [ -z "$PORT_8080" ]; then
    warning "Port 8080 nicht belegt - JDownloader läuft möglicherweise nicht richtig"
else
    echo "Port 8080 Belegung:"
    echo "$PORT_8080"
fi

echo ""
echo ""

# 9. Zusammenfassung und Empfehlungen
echo "========================================"
echo "  Zusammenfassung"
echo "========================================"
echo ""

JDOWNLOADER_COUNT=$(ps aux | grep -i "JDownloader.jar" | grep -v grep | wc -l)

if [ $JDOWNLOADER_COUNT -gt 1 ]; then
    error "PROBLEM ERKANNT: $JDOWNLOADER_COUNT JDownloader-Instanzen laufen!"
    echo ""
    echo "Empfohlene Lösung:"
    echo "1. Alle JDownloader-Prozesse beenden:"
    echo "   sudo systemctl stop jdownloader"
    echo "   sudo pkill -9 -f JDownloader.jar"
    echo ""
    echo "2. Prüfe auf doppelte Autostart-Einträge (siehe oben)"
    echo ""
    echo "3. JDownloader neu starten:"
    echo "   sudo systemctl start jdownloader"
    echo ""
    echo "Oder nutze das fix-jdownloader.sh Script!"
elif [ $JDOWNLOADER_COUNT -eq 1 ]; then
    success "Nur 1 JDownloader-Instanz läuft - System ist OK"
else
    warning "Keine JDownloader-Instanz läuft"
    echo ""
    echo "JDownloader starten mit:"
    echo "   sudo systemctl start jdownloader"
fi

echo ""
