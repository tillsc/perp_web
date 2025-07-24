# perp.de – Regattaverwaltung für Ruderregatten

**perp.de** ist eine Open-Source-Webanwendung zur Durchführung und Verwaltung von Ruderregatten – entwickelt, um auch anspruchsvolle Veranstaltungen wie Deutsche Meisterschaften ohne Spezialhardware durchführbar zu machen.

Das System basiert auf **Ruby on Rails 8** und funktioniert komplett webbasiert – von der Meldung über die Zwischenzeitmessung bis zur Zieleinlauf-Auswertung.

**Projekt-Repository:**  
https://github.com/tillsc/perp_web

## Hauptfunktionen

- Veranstaltungs- und Rennverwaltung
- Meldesystem und Teilnehmerlisten
- Wiederholbarer Import von Meldungen aus dem DRV Meldeportal
- Integration mit einer softwarebasierten Ziel-Splitkamera:  
  [https://github.com/tillsc/perp_finish_cam](https://github.com/tillsc/perp_finish_cam)
- Zwischenzeitmessung mit handelsüblichen Bluetooth-Fernauslösern
- Regattainformationsdienst im Browser
- Keine native App notwendig


## Zeitmessung ohne Spezialhardware

Ein zentrales Ziel von perp.de ist es, auch komplexe Regatten mit günstiger Standardhardware durchführbar zu machen. Zwischenzeiten können mit günstigen Bluetooth-Fernauslösern ausgelöst werden, z. B.:

[VJK Kamera-Fernauslöser bei Amazon](https://www.amazon.de/dp/B0CNSK5T9Y)

Diese Auslöser koppeln sich via Bluetooth mit einem Smartphone und senden einfache Tastendrücke an die Web-App.

Die Zielbildkamera wird als separates Softwaremodul betrieben und ist frei verfügbar:
https://github.com/tillsc/perp_finish_cam


## Lizenz

Dieses Projekt ist unter der **[PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/)** lizenziert.

**Was bedeutet das?**

- Die Nutzung ist **kostenfrei**, solange sie **nicht kommerziell** erfolgt.
- Jegliche kommerzielle Nutzung (z.B. im Rahmen einer kostenpflichtigen Dienstleistung oder Integration in ein kommerzielles Produkt) ist **nicht gestattet**, es sei denn, es wird eine gesonderte Lizenz mit dem Urheber vereinbart.

**Copyright © Till Schulte-Coerne**


## Systemanforderungen

- Ruby 3.2+
- MySQL (Standard) oder PostgreSQL (möglich, aber nicht getestet)
- bundler


## Installation (lokale Entwicklung)

### 1. Repository klonen

```bash
git clone https://github.com/tillsc/perp_web.git
cd perp_web
```

### 2. Abhängigkeiten installieren

```bash
bundle install
```

### 3. Konfiguration einrichten

```bash
cp config/database.yml.template config/database.yml
```

### 4. Datenbank vorbereiten

```bash
bin/rails db:setup
```

Alternativ manuell:

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 5. Anwendung starten

```bash
bin/dev
```

Die App ist dann erreichbar unter:
http://localhost:3000


## Docker (optional, empfohlen für Deployment)

Ein Docker-Setup befindet sich in Vorbereitung und wird bald ergänzt. Ziel ist ein standardisiertes Setup für Hosting und Betrieb auf günstigen Cloud-VMs oder bare-metal-Rechnern vor Ort.


## Support & Beiträge

Beiträge sind willkommen. Bitte beachte die Lizenzbedingungen. Für größere Beiträge oder Anpassungen für konkrete Regatten: gerne Issue eröffnen oder direkt Kontakt aufnehmen.
