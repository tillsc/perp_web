# perp.de – Regattaverwaltung für Ruderregatten

**perp.de** ist eine Open-Source-Webanwendung zur Durchführung und Verwaltung von Ruderregatten – entwickelt, um auch anspruchsvolle Veranstaltungen wie Deutsche Meisterschaften ohne Spezialhardware durchführbar zu machen.

Das System basiert auf **Ruby on Rails 8** und funktioniert komplett webbasiert – von der Meldung über die Zwischenzeitmessung bis zur Zieleinlauf-Auswertung.

**Projekt-Repository:**  
https://github.com/tillsc/perp_web

---

## Hauptfunktionen

- Veranstaltungs- und Rennverwaltung
- Meldesystem und Teilnehmerlisten
- Wiederholbarer Import von Meldungen aus dem DRV Meldeportal
- Integration mit einer softwarebasierten Ziel-Splitkamera: [https://github.com/tillsc/perp_finish_cam](https://github.com/tillsc/perp_finish_cam)
- Zwischenzeitmessung mit handelsüblichen Bluetooth-Fernauslösern
- Regattainformationsdienst im Browser
- Keine native App notwendig

---

## Zeitmessung ohne Spezialhardware

Ein zentrales Ziel von perp.de ist es, auch komplexe Regatten mit günstiger Standardhardware durchführbar zu machen. Zwischenzeiten können mit günstigen Bluetooth-Fernauslösern ausgelöst werden, z. B.:

[VJK Kamera-Fernauslöser bei Amazon](https://www.amazon.de/dp/B0CNSK5T9Y)

Diese Auslöser koppeln sich via Bluetooth mit einem Smartphone und senden einfache Tastendrücke an die Web-App.

Die Zielbildkamera wird als separates Softwaremodul betrieben und ist frei verfügbar: https://github.com/tillsc/perp_finish_cam

---

## Lizenz

Dieses Projekt ist unter der **[PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/)** lizenziert.

**Was bedeutet das?**

- Die Nutzung ist **kostenfrei**, solange sie **nicht kommerziell** erfolgt.
- Jegliche kommerzielle Nutzung (z. B. im Rahmen einer kostenpflichtigen Dienstleistung oder Integration in ein kommerzielles Produkt) ist **nicht gestattet**, es sei denn, es wird eine gesonderte Lizenz mit dem Urheber vereinbart.

**Copyright © Till Schulte-Coerne**

---

## Nutzung per Docker

Für den produktiven Einsatz steht ein fertiges Docker-Image bereit. Es wird bei jeder neuen Version automatisch über GitHub veröffentlicht.

Voraussetzung ist eine bestehende MySQL-Datenbank.

1. **.env-Datei anpassen:**  
   Erstelle irgendwo eine `.env`-Datei mit deinen individuellen Einstellungen (z.B. Datenbank-Zugangsdaten).

   Die benötigten Umgebungsvariablen können online eingesehen und kopiert werden unter: https://github.com/tillsc/perp_web/blob/main/.env.example

2. **Anwendung mit Docker starten:**  
   Starte die App mit folgendem Befehl:

   ```bash
   docker run --rm -p 3000:3000 \
     --env-file .env \
     ghcr.io/tillsc/perp_web:latest
   ```

   Alternativ kannst du die Umgebungsvariablen auch direkt in der Kommandozeile übergeben, ohne eine `.env`-Datei zu verwenden. Zum Beispiel:

   ```bash
   docker run --rm -p 3000:3000 \
     -e SECRET_KEY_BASE=... \
     -e PERP_DATABASE_HOST=... \
     ghcr.io/tillsc/perp_web:latest
   ```

3. **Zugriff auf die Anwendung:**  
   Nach dem Start erreichst du die Anwendung unter http://localhost:3000 in deinem Browser.

   Der Admin-Bereich ist unter http://localhost:3000/internal erreichbar.

---

## Lokale Entwicklung

### Systemanforderungen

- Ruby 3.2+
- MySQL (Standard) oder PostgreSQL (möglich, aber nicht getestet)
- bundler

### Installation

1. **Repository klonen:**

    ```bash
    git clone https://github.com/tillsc/perp_web.git
    cd perp_web
    ```

2. **Abhängigkeiten installieren:**

    ```bash
    bundle install
    ```
   
3. **Umgebungsvariablen setzen:**

    ```bash
    cp .env.example .env
    ```

    Passe die `.env`-Datei an deine lokale Konfiguration an.

4. **Datenbank vorbereiten:**

    ```bash
    bin/rails db:create
    bin/rails db:migrate
    bin/rails db:seed
    ```

5. **Anwendung starten:**

    ```bash
    bin/dev
    ```

    Die App ist dann erreichbar unter:  
    http://localhost:3000

    Der Admin-Bereich ist unter http://localhost:3000/internal erreichbar.

---

## Support & Beiträge

Beiträge sind willkommen. Bitte beachte die Lizenzbedingungen. Für größere Beiträge oder Anpassungen für konkrete Regatten: gerne Issue eröffnen oder direkt Kontakt aufnehmen.
