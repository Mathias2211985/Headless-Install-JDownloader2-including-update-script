# JDownloader auf Raspberry Pi ohne Display

## Schritt-für-Schritt Anleitung zur Installation und Einrichtung

### Schritt 1: Raspberry Pi OS auf SD-Karte installieren

1. **Raspberry Pi Imager herunterladen**
   - Gehe zu https://www.raspberrypi.com/software/
   - Lade den Raspberry Pi Imager herunter und installiere ihn

2. **SD-Karte vorbereiten**
   - Stecke die SD-Karte in deinen Computer
   - Öffne den Raspberry Pi Imager

3. **Betriebssystem auswählen**
   - Klicke auf "CHOOSE OS"
   - Wähle "Raspberry Pi OS (other)"
   - Wähle "Raspberry Pi OS Lite (64-bit)"

4. **SD-Karte auswählen**
   - Klicke auf "CHOOSE STORAGE"
   - Wähle deine SD-Karte aus

5. **Einstellungen konfigurieren (WICHTIG!)**
   - Klicke auf das Zahnrad-Symbol (⚙️) unten rechts
   - **Hostname:** "JDownloader" (oder ein anderer Name)
   - **SSH aktivieren:** ✓ Häkchen setzen
   - **Benutzername:** pi (oder eigener Name)
   - **Passwort:** Sicheres Passwort festlegen (merken!)
   - **WLAN NICHT konfigurieren** (leer lassen)
   - **Locale Settings:** Zeitzone und Tastaturlayout einstellen
   - Klicke auf "SAVE"

6. **SD-Karte flashen**
   - Klicke auf "WRITE"
   - Bestätige mit "YES"
   - Warte bis der Vorgang abgeschlossen ist

7. **Raspberry Pi starten**
   - SD-Karte in den Raspberry Pi einlegen
   - Ethernet-Kabel anschließen (mit Router verbinden)
   - Stromkabel anschließen
   - Warte ca. 2-3 Minuten bis der Pi hochgefahren ist

---

### Schritt 2: Erste Verbindung via SSH

1. **IP-Adresse herausfinden** (eine der folgenden Methoden):
   - Im Router nachschauen (z.B. Fritz!Box unter Heimnetz → Netzwerk)
   - Mit Hostname verbinden: `raspberrypi.local` oder `jdownloader.local`

2. **SSH-Verbindung herstellen** (Windows PowerShell):
```powershell
ssh pi@raspberrypi.local
# oder mit IP-Adresse:
ssh pi@192.168.x.x
```

3. **Beim ersten Mal:**
   - Frage "Are you sure you want to continue connecting?" → Tippe `yes` und Enter
   - Passwort eingeben (das du in Schritt 1.5 festgelegt hast)

4. **Du bist jetzt verbunden!** Der Prompt zeigt: `pi@JDownloader:~ $`

---

### Schritt 3: System aktualisieren

```bash
sudo apt update
sudo apt upgrade -y
```
Warte bis der Vorgang abgeschlossen ist (kann einige Minuten dauern).

---

### Schritt 4: Java installieren

```bash
sudo apt install default-jre -y
```

**Prüfen ob Java installiert ist:**
```bash
java -version
```
Sollte etwas wie `openjdk version "17.x.x"` anzeigen.

---

### Schritt 5: JDownloader installieren

1. **Verzeichnis erstellen:**
```bash
sudo mkdir -p /opt/JDownloader
cd /opt/JDownloader
```

2. **JDownloader herunterladen:**
```bash
sudo wget http://installer.jdownloader.org/JDownloader.jar
```

3. **JDownloader installieren:**
```bash
sudo java -Djava.awt.headless=true -jar JDownloader.jar -norestart
```

**WICHTIG:** Warte bis die Installation vollständig abgeschlossen ist (du siehst "Installation finished" oder ähnlich). Dann drücke `Ctrl+C` um den Prozess zu beenden.

---

### Schritt 6: JDownloader als Systemdienst einrichten

1. **Service-Datei erstellen:**
```bash
sudo nano /etc/systemd/system/jdownloader.service
```

2. **Folgenden Inhalt einfügen** (mit Rechtsklick oder Strg+Shift+V):
```ini
[Unit]
Description=JDownloader Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/JDownloader
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /opt/JDownloader/JDownloader.jar
Restart=always

[Install]
WantedBy=multi-user.target
```

3. **Datei speichern:**
   - Drücke `Ctrl+X`
   - Drücke `Y` (Yes)
   - Drücke `Enter`

---

### Schritt 7: JDownloader-Dienst aktivieren und starten

```bash
sudo systemctl daemon-reload
sudo systemctl enable jdownloader
sudo systemctl start jdownloader
```

**Status prüfen:**
```bash
sudo systemctl status jdownloader
```

Du solltest "active (running)" sehen. Mit `Q` (Taste drücken) verlässt du die Ansicht.

**✓ JDownloader startet jetzt automatisch bei jedem Neustart!**

---

### Schritt 8: Auf JDownloader zugreifen

#### Option A: MyJDownloader (empfohlen für externen Zugriff)

1. Gehe zu https://my.jdownloader.org
2. Erstelle ein kostenloses Konto
3. Verbinde deinen JDownloader:
   - JDownloader erkennt automatisch deinen Account
   - Oder im Web-Interface: Einstellungen → MyJDownloader → Anmelden
4. Zugriff von überall über Browser oder App

#### Option B: Direkter Web-Zugriff (im lokalen Netzwerk)

- Öffne Browser und gehe zu: `http://raspberrypi.local:8080`
- Oder mit IP-Adresse: `http://192.168.x.x:8080`

---

### Schritt 9: Update-Script installieren (automatische Updates)

1. **Script von Windows auf den Raspberry Pi kopieren** (PowerShell auf deinem PC):
```powershell
scp c:\Test\autostart\JDownlaoder\update-system.sh pi@raspberrypi.local:/home/pi/
```
Passwort eingeben.

2. **Auf dem Raspberry Pi (in der SSH-Sitzung):**
```bash
sudo mv /home/pi/update-system.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/update-system.sh
```

3. **Script testen:**
```bash
sudo update-system.sh
```

Das Script aktualisiert automatisch System und JDownloader.

---

### Schritt 10: Automatische Updates einrichten (jeden Freitag um Mitternacht)

1. **Crontab öffnen:**
```bash
sudo crontab -e
```

2. **Beim ersten Mal:** Wähle einen Editor (z.B. `1` für nano) und drücke Enter

3. **Ganz unten folgende Zeile hinzufügen:**
```bash
0 0 * * 5 /usr/local/bin/update-system.sh >> /var/log/update-system.log 2>&1
```

4. **Speichern:**
   - Drücke `Ctrl+X`
   - Drücke `Y`
   - Drücke `Enter`

**✓ Updates laufen jetzt automatisch jeden Freitag um 00:00 Uhr!**

**Logs anschauen:**
```bash
sudo tail -f /var/log/update-system.log
```

---

### Schritt 11 (Optional): Automatische Sicherheitsupdates aktivieren

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

Wähle "Yes" mit den Pfeiltasten und drücke Enter.

---

## ✅ Installation abgeschlossen!

**Zusammenfassung:**
- ✓ Raspberry Pi läuft headless (ohne Display)
- ✓ JDownloader ist installiert und läuft als Dienst
- ✓ Automatischer Start bei jedem Neustart
- ✓ Updates laufen automatisch jeden Freitag
- ✓ Zugriff über MyJDownloader oder Web-Interface
- ✓ WLAN ist deaktiviert (nur Ethernet)

**Wichtige IP-Adresse notieren:**
```bash
hostname -I
```
Notiere dir diese IP-Adresse für den Zugriff!

---

## Nützliche Befehle für den Alltag

### JDownloader-Dienst verwalten
```bash
# Status prüfen
sudo systemctl status jdownloader

# Logs ansehen
sudo journalctl -u jdownloader -f

# Dienst neustarten
sudo systemctl restart jdownloader

# Dienst stoppen
sudo systemctl stop jdownloader

# Dienst starten
sudo systemctl start jdownloader
```

### System-Informationen
```bash
# IP-Adresse anzeigen
hostname -I

# WLAN Status prüfen (sollte deaktiviert sein)
ip link show wlan0

# Freier Speicher
df -h

# Uptime anzeigen
uptime

# Temperatur anzeigen
vcgencmd measure_temp
```

### Update-Logs überprüfen
```bash
# Letzte Update-Logs anzeigen
sudo tail -f /var/log/update-system.log

# Komplette Log-Datei
sudo cat /var/log/update-system.log

# Cron-Jobs anzeigen
sudo crontab -l
```

### Manuelles Update durchführen
```bash
# Update-Script ausführen
sudo update-system.sh
```

---

## Tipps und Optimierungen

### Externe Festplatte für Downloads einbinden
```bash
# USB-Festplatte anschließen und automatisch mounten
sudo mkdir -p /mnt/downloads
sudo mount /dev/sda1 /mnt/downloads

# Automatisches Mounten beim Start
sudo nano /etc/fstab
# Zeile hinzufügen: /dev/sda1 /mnt/downloads ext4 defaults 0 0
```

### Feste IP-Adresse vergeben
Im Router (z.B. Fritz!Box):
- Heimnetz → Netzwerk → Netzwerkverbindungen
- Raspberry Pi auswählen → "Diesem Netzwerkgerät immer die gleiche IPv4-Adresse zuweisen"

### Regelmäßige Backups
- SD-Karte regelmäßig sichern (z.B. mit Win32DiskImager)
- Backup-Intervall: Alle 1-2 Monate

### SSH-Key statt Passwort (erhöhte Sicherheit)
```bash
# Auf Windows-PC: SSH-Key generieren
ssh-keygen -t ed25519

# Key auf Raspberry Pi kopieren
scp ~/.ssh/id_ed25519.pub pi@raspberrypi.local:~/.ssh/authorized_keys
```

---

## Fehlerbehebung

### JDownloader startet nicht

**Problem:** Service ist "failed" oder "inactive"

**Lösung 1 - Logs prüfen:**
```bash
sudo journalctl -u jdownloader -n 50
```

**Lösung 2 - Java prüfen:**
```bash
java -version
```

**Lösung 3 - JDownloader.jar prüfen:**
```bash
ls -la /opt/JDownloader/JDownloader.jar
```

**Lösung 4 - Manuell starten zum Testen:**
```bash
cd /opt/JDownloader
sudo -u pi java -Djava.awt.headless=true -jar JDownloader.jar
```

### Kein Zugriff über Netzwerk

**Problem:** Web-Interface nicht erreichbar

**Lösung 1 - IP-Adresse prüfen:**
```bash
hostname -I
```

**Lösung 2 - JDownloader läuft:**
```bash
sudo systemctl status jdownloader
```

**Lösung 3 - Port prüfen:**
```bash
sudo netstat -tulpn | grep 8080
```

### SSH-Verbindung funktioniert nicht

**Lösung 1 - Hostname vs IP:**
```bash
# Statt raspberrypi.local:
ssh pi@192.168.x.x
```

**Lösung 2 - IP im Router nachschauen**

**Lösung 3 - SSH-Service prüfen:**
```bash
sudo systemctl status ssh
```

### Update-Script schlägt fehl

**Problem:** Fehler beim Ausführen von update-system.sh

**Lösung:**
```bash
# Berechtigungen prüfen
ls -la /usr/local/bin/update-system.sh

# Sollte ausführbar sein (-rwxr-xr-x)
sudo chmod +x /usr/local/bin/update-system.sh

# Logs prüfen
sudo cat /var/log/update-system.log
```

### WLAN deaktivieren (falls aktiviert)

**Temporär:**
```bash
sudo ifconfig wlan0 down
```

**Dauerhaft:**
```bash
sudo nano /boot/firmware/config.txt
# Oder bei älteren Versionen: /boot/config.txt
```
Hinzufügen:
```
dtoverlay=disable-wifi
dtoverlay=disable-bt
```
Dann: `sudo reboot`

---

## Häufig gestellte Fragen (FAQ)

**Q: Wie ändere ich das Passwort?**
```bash
passwd
```

**Q: Wie finde ich die IP-Adresse heraus?**
```bash
hostname -I
```

**Q: Wie mache ich ein Backup der SD-Karte?**
- Raspberry Pi herunterfahren: `sudo shutdown -h now`
- SD-Karte in PC einlegen
- Mit Win32DiskImager oder Raspberry Pi Imager ein Image erstellen

**Q: Wie stelle ich einen Neustart ein?**
```bash
# Sofort neustarten
sudo reboot

# In 10 Minuten neustarten
sudo shutdown -r +10

# Um bestimmte Uhrzeit (z.B. 03:00 Uhr)
sudo shutdown -r 03:00
```

**Q: Wie schalte ich den Raspberry Pi aus?**
```bash
sudo shutdown -h now
```

**Q: Wie viel Speicherplatz ist noch frei?**
```bash
df -h
```

**Q: Läuft das Update-Script?**
```bash
# Cron-Jobs anzeigen
sudo crontab -l

# Letzte Logs anzeigen
sudo tail /var/log/update-system.log
```

---

## Anhang: Technische Details

### Was macht das Update-Script?
Das Script (`update-system.sh`) führt folgende Aktionen aus:
1. Aktualisiert die Paketlisten (`apt update`)
2. Installiert verfügbare Updates (`apt upgrade`)
3. Entfernt nicht mehr benötigte Pakete (`apt autoremove`)
4. Räumt den Paket-Cache auf (`apt autoclean`)
5. Stoppt JDownloader
6. Aktualisiert JDownloader
7. Startet JDownloader neu
8. Zeigt System-Informationen an
9. Warnt bei notwendigem Neustart

### Systemanforderungen
- Raspberry Pi 3, 4 oder 5
- Mindestens 1GB RAM (2GB empfohlen)
- SD-Karte mindestens 8GB (16GB empfohlen)
- Ethernet-Verbindung
- Stromversorgung mindestens 5V/2.5A

### Verwendete Ports
- SSH: 22
- JDownloader Web-Interface: 8080
- MyJDownloader: Verwendet sichere Verbindung über my.jdownloader.org

### Sicherheitshinweise
- Ändere das Standard-Passwort
- Halte das System aktuell (automatische Updates aktiv)
- Nutze MyJDownloader für externen Zugriff statt Port-Forwarding
- WLAN ist deaktiviert für mehr Sicherheit
- SSH läuft nur im lokalen Netzwerk

---

**Erstellt:** Dezember 2025  
**Version:** 1.0  
**Support:** Bei Problemen die Fehlerbehebung konsultieren oder Logs prüfen
