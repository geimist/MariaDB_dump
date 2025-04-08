#!/bin/bash
# shellcheck disable=SC2154

#####################################################################################
#                                                                                   #
#   MARIADB-BackUp                                                                  #
#   v1.1.1 @ 2023-02-14                                                             #
#                                                                                   #
#   source:                                                                         #
#   https://stefankonarski.de/content/mysql-backup-fuer-jede-datenbank-eine-datei   #
#                                                                                   #
#####################################################################################

# changelog v1.1.1:
#   - 1 Sekunde Wartepause zwichen jedem Backup eingebaut, damit das Rotationsskript korret läuft
#   - Schalter für ein Gesamtbackup eingebaut

# -----------------------------------------------------

# Variablen
# Umgebungsvariablen
SPATH=$(dirname "$0")

# Konfigurationsdatei festlegen:
ENV_CONFIG="$1"
if [ -z "$ENV_CONFIG" ]; then
    # Wenn kein Parameter übergeben wurde, dann die Konfigurationsdatei aus dem Verzeichnis cnf verwenden:
    ENV_CONFIG="${SPATH}/../cnf/config.cnf"
fi

# Prüfen ob die Konfigurationsdatei existiert:
if [ ! -f "$ENV_CONFIG" ]; then
    # Wenn die Konfigurationsdatei nicht existiert, dann eine Fehlermeldung ausgeben und das Skript beenden:
    echo "Konfigurationsdatei $ENV_CONFIG nicht gefunden!"
    exit 1
else
    # Wenn die Konfigurationsdatei existiert, dann die Variablen aus der Konfigurationsdatei laden:
    # shellcheck disable=SC1090
    source "$ENV_CONFIG"
fi

# -----------------------------------------------------

# ggf. abschließenden Slash entfernen und Ordner ggf. erstellen:
BACKUPDIR="${BACKUPDIR%/}"
[ ! -d "${BACKUPDIR}" ] && mkdir -p "${BACKUPDIR}"

# Prüfen ob mysqldump existiert:
if [ "" = "$MYSQLPW" ]; then
    echo "Login ohne Passwort"
    DBLOGIN='-u root'
else
    DBLOGIN="-u root -p$MYSQLPW"
fi

# Das Kommando festlegen um die Datenbanken aufzulisten:
# shellcheck disable=SC2086
DBlist="$($DBengine $DBLOGIN -Bse 'show databases')"

# Variablen anlegen und initialisieren:
# Zähler für gesicherte und übersprungene Datenbanken:
DBCOUNT=0
SKIPDBCOUNT=0

# Variablen für die gesicherten und übersprungenen Datenbanken:
DUMPED_DBS=()
SKIPPED_DBS=()

# Schleife über alle Datenbanken:
for db in $DBlist ; do
    # überspringe keine Datenbank als Standardwert:
    skipdb=0
    # Wenn ausgeschlossene Datenbanken definiert sind:
    if [ "$ExDB" != "" ]; then
        # Schleife über die ausgeschlossenen Datenbanken und ggf. Flag setzen:
        for n in $ExDB; do
            if [ "$db" = "$n" ]; then
                skipdb=1
                break;
            fi
        done
    fi

    # Prüfen ob die Datenbank übersprungen werden soll:
    if [ "$skipdb" = "1" ] ; then
        echo "überspringe Datenbank $db"
        # Datenbank überspringen und in die Liste der übersprungenen Datenbanken eintragen:
        SKIPPED_DBS+=("$db")
        # Zähler der übersprungenen Datenbanken erhöhen:
        SKIPDBCOUNT=$((SKIPDBCOUNT + 1))
        # dump überspringen und Schleife fortsetzen:
        continue
    fi

    # Den entsprechenden Pfad für die Sicherung anlegen:
    modBACKUPDIR="${BACKUPDIR}"
    # Wenn ein Unterverzeichnis für die DBs genutzt werden soll, dann einen Unterordner für die jeweilige DB anlegen und modBACKUPDIR anpassen:
    if [ "$useSubDir" = true ]; then
        modBACKUPDIR="${BACKUPDIR}/${db}"
        # Prüfen ob das Unterverzeichnis existiert:
        if [ ! -d "${modBACKUPDIR}" ]; then
            # Wenn das Unterverzeichnis nicht existiert, dann anlegen:
            mkdir -p "${modBACKUPDIR}"
        fi
    fi

    # Dateinamen inklusive Pfad festlegen:
    fn="${modBACKUPDIR}/MySQLdump_${db}_${DATE}.sql.gz"

    # Ausgabe des zu sichernden Datenbanknamens:
    printf "\n\nDump Datenbank $db nach %s\n\n" "${fn}"

    # Dump der Datenbank erstellen:
    # shellcheck disable=SC2086
    # shellcheck disable=SC2154
    $mysqldump $DBLOGIN --databases $db | gzip -c -9 > "${fn}"
    retcode=$?
    if [ $retcode -ne 0 ]; then
        echo "Fehler beim Erzeugen eines Dumps der Datenbank $db"
        exit $retcode
    else
        echo "Dump der Datenbank $db erfolgreich"
        # dump erfolgreich, also in die Liste der gesicherten Datenbanken eintragen:
        DUMPED_DBS+=("$db")
        # Zähler der gesicherten Datenbanken erhöhen:
        DBCOUNT=$((DBCOUNT + 1))
    fi
    sleep 1

    # Rotation, sofern man das Skript "archive_rotate" von hier verwendet: https://github.com/geimist/archive_rotate
    if [ "$Rotate" = true ]; then
        echo "Starte Rotation der Abbilder der einzelnen Datenbanken..."
        # Prüfe ob ScriptRotate ist gesetzt and existiert:
        if [ -z "$ScriptRotate" ] || [ ! -f "$ScriptRotate" ]; then
            echo "Der Parameter für das Skript Rotate ist nicht gesetzt oder die Datei existier nicht. Überspringe Rotation."
            exit 1
        else
            # shellcheck disable=SC2154
            "${ScriptRotate}" -vc -p="${modBACKUPDIR}" -s=MySQLdump_"${db}"_* -h="$HOURS" -d="$DAYS" -w="$WEEKS" -m="$MONTHS" -y="$YEARS"
        fi
    fi
done

# Und zum Schluss noch ein Gesamtbackup:
if [ "$DumpAll" = true ]; then
    modBACKUPDIR="${BACKUPDIR}"
    # Wenn ein Unterverzeichnis für die DBs genutzt werden soll, dann einen Unterordner für das Gesamtbackup anlegen und modBACKUPDIR anpassen:
    if [ "$useSubDir" = true ]; then
        # Prüfen ob das Unterverzeichnis existiert:
        modBACKUPDIR="${BACKUPDIR}/GESAMT"
        if [ ! -d "${modBACKUPDIR}" ]; then
            # Wenn das Unterverzeichnis nicht existiert, dann anlegen:
            mkdir -p "${modBACKUPDIR}"
        fi
    fi

    # Dateinamen inklusive Pfad für das GESAMT-Backup festlegen:
    fn="${modBACKUPDIR}/MySQLdump_GESAMTBACKUP_${DATE}.sql.gz"
    # Ausgabe des zu sichernden Datenbanknamens:
    printf "\n\nDump GESAMT nach %s\n\n" "${fn}"

    # shellcheck disable=SC2086
    $mysqldump --opt $DBLOGIN --all-databases | gzip -c -9 > "${fn}"
    retcode=$?
    if [ $retcode -ne 0 ]; then
        echo "Fehler beim Erzeugen eines Dumps der GESAMT-Datenbank"
        exit $retcode
    else
        echo "Dump der GESAMT-Datenbank erfolgreich"
        # dump erfolgreich, also in die Liste der gesicherten Datenbanken eintragen:
        DUMPED_DBS+=("GESAMT")
        # Zähler der gesicherten Datenbanken erhöhen:
        DBCOUNT=$((DBCOUNT + 1))
    fi
    sleep 1


    # Rotation, sofern man das Skript "archive_rotate" von hier verwendet: https://github.com/geimist/archive_rotate
    if [ "$Rotate" = true ]; then
        echo echo "Starte Rotation der Abbilder der GESAMT-Datenbank..."
        # Prüfe ob ScriptRotate ist gesetzt and existiert:
        if [ -z "$ScriptRotate" ] || [ ! -f "$ScriptRotate" ]; then
            echo "Der Parameter für das Skript Rotate ist nicht gesetzt oder die Datei existier nicht. Überspringe Rotation."
            exit 1
        else
            "${ScriptRotate}" -vc -p="${modBACKUPDIR}" -s=MySQLdump_GESAMTBACKUP_* -h="$HOURS" -d="$DAYS" -w="$WEEKS" -m="$MONTHS" -y="$YEARS"
        fi
    fi
fi

# Ausgabe der Ergebnisse:
printf "\n%-30s %-30s\n" "Anzahl gesicherter DB's:" "$DBCOUNT"
printf "%-30s %-30s\n" "Liste der gesicherten DB's:" "$(IFS=,; echo "${DUMPED_DBS[*]}")"
printf "%-30s %-30s\n" "Anzahl übersprungener DB's:" "$SKIPDBCOUNT"
printf "%-30s %-30s\n" "Liste der übersprungenen DB's:" "$(IFS=,; echo "${SKIPPED_DBS[*]}")"

exit 0
