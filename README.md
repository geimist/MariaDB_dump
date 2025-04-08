Deutsch | [English](README_en.md)

# MariaDB_dump

## Beschreibung
MariaDB_dump ist ein shell Skript um alle vorhandenen Datenbanken aus einer bestehenden mysql oder mariadb Datenbank-Engine einzeln zu exportieren um diese an einem angegebenen Speicherort zu sichern.
Um eine zyklische Sicherung der Datenbanken durchzuführen eignet sich die Definition eines Cron-Job. Hier wird jedoch nicht weiter darauf eingegangen wie eine solche automatische Ausführung des Skripts mittels Cron-Job durchgeführt wird.

## Installation
Klone das Git-Archiv mittels `git clone`.

Zuerst erstellt man Verzeichnis in welchem das Abbild des Repository erstellt werden soll.
Anschließend wechselt man in dieses Verzeichnis und führt abschließend den git Befehlt zum Klonen aus.
<ins>Beispiel:</ins>
```
mkdir -p /root/github
cd /root/github
git clone https://github.com/geimist/MariaDB_dump.git
```

## Konfiguration
Verwende die Konfigurationsvorlage [config.cnf.template](cnf/config.cnf.template) um deine eigene Konfiguration zu erzeugen indem du eine Kopie dieser Datei unter dem Namen *config.cnf* erstellst.

Die zu konfigurierenden Parameter die sich innerhalb dieser Konfigiurationsdatei befinden sind folgende:
### MySQL-Rootkennwort
Hierbei handelt es sich um das mysql/mariadb Passwort des Benutzers *root*.
Die Angabe des Passworts ist nur notwendig wenn das Shell Skript nicht als root auf dem System ausgeführt wird von dem die Datenbanken gesichert werden.
Nur wenn das Skript als ein gewöhnlicher Benutzer ausgeführt wird ist die Angabe des Root-Kennworts der mysql/mariadb Datenbank notwendig.

<ins>Beispiel:</ins>
Ohne Angabe eines Passworts weil das Skript als System Benutzer root ausgeführt wird kann die Variable mit einem Leerstring definiert werden.
```
MYSQLPW=""
```
Anderenfalls wird das Passwort zwischen doppelten Anführungszeichen angegeben.
```
MYSQLPW="GanzSicherMariaDB_PW"
```

### Sicherungsverzeichenis
Das Sicherungsverzeichnis ist dasjenige an dem die exportierten Datenbanken gespeichert werden sollen.
Dies muss zwingend angegeben werden sonst können keine Daten exportiert werden.

<ins>Beispiel:</ins>
```
BACKUPDIR="/volume1/system/DS_BackUps/MariaDB_DUMP_test"
```

### Unterverzeichnis verwenden
Mit diesem Parameter kann angegeben werden ob für jede einzeln exportierte Datenbank jeweils ein Unterverzeichnis mit dessen Namen in dem vorher definierten Sicherungsziel abgelegt werden soll.
Dies kann bei sehr vielen verfügbaren Datenbanken sehr hilfreich um eine bessere strukturierte Verzeichnisstruktur zu erhalten indem dem die Datenbanken gespeichert werden.

Möchte man für jede einzelne Datenbank ein separates Unterverzeichnis erstellen so ist es notwendig den Paramter zu aktivieren.

<ins>Beispiel:</ins>
Unterverzeichnisse aktivieren
```
useSubDir=true
```

Möchte man keine Unterverzeichnisse erstellen kann der Parameter jeden beliebigen Wert annhemen.
In diesem Beispiel wird der Begriff *false* verwendet um dies zu erzielen.
```
useSubDir=false
```

### Gesamtsicherung
Zusätzlich zu dem Export der einzelnen Datenbanken ist es auch möglich eine gesamte Sicherung der kompletten mysql/mariadb Datenbank in einer einzigen Datei zu erstellen.

Möchte man zusätzlich eine gesamte Sicherung der kompletten Datenbank erstellen so ist es notwendig den Parameter zu aktivieren.

<ins>Beispiel:</ins>
Gesamtsicherung aktivieren
```
DumpAll=true
```

Möchte man auf eine gesamte Sicherung der Datenbank in einer einzelnen Datei verzichten kann der Parameter jeden beliebigen Wert annehmen.
In diesem Beispiel wird der Begriff *false* verwendet um dies zu erzielen.
```
DumpAll=false
```

### Format des Datums für den Dateinamen
Zu jeder exportierten Datei wird der jeweilige Datenbankname und zusätzlich das Datum für die Sicherungsdatei verwendet.

Das Standardformat aus der Vorlage ist wie folgt festgelegt: `YYYY-MM-DD_hh-mm-ss` (z.B. 2025-04-08_19-04-27)

<ins>Beispiel:</ins>
```
DATE=$(date +%Y-%m-%d_%H-%M-%S)
```

Welche Formate verfügbar sind und wie sie anzuwenden sind findet man in der Bedienungsanleitung der Schnittstellenbeschreibung [date(1)](https://man7.org/linux/man-pages/man1/date.1.html).

### Programmpfade
Die Programmpfade sind notwendig um den Speicherort der benötigten Werkzeuge zu definieren. Dies ist notwendig weil sich diese systemübergreifend nicht am gleichen Installationsort befinden.
Bei den meisten Linux Distributionen ist dies aber bei den Standardwerkzeugen meistens der Fall.

Die Standardeinstellung der Konfigurationsvorlage definiert diese automatisch indem der Befehl `which` verwendet wird.
Sollte dies aus unbekannten Gründen nicht funktioneren besteht die Möglichkeit die Pfade der benötigten Werkzeute auch manuell zu definieren.

Die benötigten Werkzeuge sind zum einen die Datenbank-Engine `mysql` und `mysqldump` um die Datenbanken zu exportieren.

Die Standardkonfiguration dieser ist.
```
DBengine="$(which mysql)"
mysqldump="$(which mysqldump)"
```

Eine manuelle Zuweisung würde z.B. wie folt aussehen.
```
DBengine="/usr/bin/mysql"
mysqldump="/usr/bin/mysqldump"
```

### Von der Sicherung auszuschließende Datenbanken
Es kommt vor dass es nicht erwünscht ist alle vorhandenen Datenbanken der Datenbank-Engine zu exportieren vor allem wenn es sich um Datenbanken zu Testzwecken handelt.

Jede einzelne Datenbank die von der Sicherung ausgeschlossen werden soll kann in diesem Parameter angegeben werden. Handelt es sich um mehr als eine einzelne Datenbank die man ausschließen möchte können multiple Datenbanken getrennt durch ein Leerzeichen angegeben werden.

<ins>Beispiel:</ins>
```
ExDB="mysql sys phpmyadmin information_schema performance_schema"
```
In diesem Beispiel werden in Summe 5 Datenbanken von der Sicherung ausgeschlossen.
1. mysql
2. sys
3. phpmyadmin
4. information_schema
5. performance_schema

### Rotation der erstellten Sicherungsarchive
Um Speicherplatz einzusparen ist es sinnvoll nicht jede einzelene Archivdatei für immer auszuwählen. Um die gespeicherten Archive auszudünnen gibt es die Möglichkeit ein weiteres Skript für diese Zwecke einzubinden.
Dazu wird z.B. das Skript [archive_rotate](https://github.com/geimist/archive_rotate) eingebunden.

#### Rotation einschalten
Um die Rotation zu verwenden so ist es notwendig den Paramter zu aktivieren.
<ins>Beispiel:</ins>
Rotation aktivieren
```
Rotate=true
```
Möchte man ohne Rotaion fortfahren kann der Parameter jeden beliebigen Wert annhemen.
In diesem Beispiel wird der Begriff *false* verwendet um dies zu erzielen.
```
Rotate=false
```

#### Pfad zum Skript welches zur Rotation verwendet wird
Das Skript `archive_rotate` kann an beliebiger Stelle auf dem System gespeichert werden. Um dies zu verwenden benötigt es lediglich die Konfigurationd des Parameters mit dem Pfad zur ausfürhbaren Skript Datei.

<ins>Beispiel:</ins>
```
ScriptRotate="/volume1/Pfad_zu/archive_rotate.sh"
```

#### Parameter für die Rotation
Es kann definiert werden wie viele Sicherungen der Vergangenheit aufbewahrt werden sollen.
Die zur Verfügung stehenden Parameter sind hierbei die Anzahl der Archive die pro Jahr, Monat, Woche, Tag und Stunden aufbewahrt werden sollen.

Eine detailierte Beschreibung hierzu ist im angegebenen Repository zu `archive_rotate` finden.

<ins>Beispiel:</ins>
```
# Parameter für die Rotation:
HOURS="1x4"
DAYS="24x7"
WEEKS="7x4"
MONTHS="4x6"
YEARS="4x1"
```

## Ausführung
Sofern die Konfigurationsdatei [cnf/config.cnf](cnf/config.cnf) vorhanden ist kann das Skript ohne weitere Angabe von Argumenten ausgeführt werden.
Optional ist auch die Übergabe einer Konfigurationsdatei als erstes Argument möglich.

Ausführung ohne Argument bei vorhandener Konfigurationsdatei im Unterverzeichnis `./cnf`.
```
./bin/MariaDB_DUMP.sh
```
Mit Übergabe eines Arguments für die Konfigurationsdatei.
```
./bin/MariaDB_DUMP.sh /<PATH_TO_CONFIG>
```

## Ausgaben
Das Skript erzeugt nützliche Ausgaben und protokolliert somit den Ablauf.

<ins>Beispiel:</ins>
Hier wird die Ausgabe gezeigt bei dem alle einzelnen Datenbanken und die Gesamt-Datenbank exportiert werden.
Zudem werden die Datenbank welche unter dem Parameter für das Ausschlusskriterium definiert sind ignoriert und von einer Sicherung ausgeschlossen.
```
Login ohne Passwort


Dump Datenbank Test_Datenbank nach /volume2/backup/MariaDB_DUMP/Test_Datenbank/MySQLdump_Test_Datenbank_2025-04-08_22-35-26.sql.gz

Dump der Datenbank Test_Datenbank erfolgreich
Überspringe Datenbank: "information_schema"
Überspringe Datenbank: "mysql"
Überspringe Datenbank: "performance_schema"
Überspringe Datenbank: "sys"


Dump GESAMT nach /volume2/backup/MariaDB_DUMP/GESAMT/MySQLdump_GESAMTBACKUP_2025-04-08_22-35-26.sql.gz

Dump der GESAMT-Datenbank erfolgreich


Resultate der Sicherung:
------------------------
 Gesicherte DB's
 Anzahl: 2
 Datenbanken:
   1.) Test_Datenbank
   2.) GESAMT

 Übersprungene DB's
 Anzahl: 4
 Datenbanken:
   1.) information_schema
   2.) mysql
   3.) performance_schema
   4.) sys
```
