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

# Konfigurationsdatei:
ENV_CONFIG="$1"
if [ -z "$ENV_CONFIG" ]; then
    ENV_CONFIG="${SPATH}/../cnf/config.cnf"
fi

if [ ! -f "$ENV_CONFIG" ]; then
    echo "Konfigurationsdatei $ENV_CONFIG nicht gefunden!"
    exit 1
else
    # shellcheck disable=SC1090
    source "$ENV_CONFIG"
fi


# -----------------------------------------------------

# ggf. abschließenden Slash entfernen und Ordner ggf. erstellen:
BACKUPDIR="${BACKUPDIR%/}"
[ ! -d "${BACKUPDIR}" ] && mkdir -p "${BACKUPDIR}"

if [ "" = "$MYSQLPW" ]; then
    echo "Login ohne Passwort"
    DBLOGIN='-u root'
else
    DBLOGIN="-u root -p$MYSQLPW"
fi

# shellcheck disable=SC2086
DBlist="$($DBengine $DBLOGIN -Bse 'show databases')"

DBCOUNT=0
SKIPDBCOUNT=0

# Schleife über alle Datenbanken:
for db in $DBlist ; do
    # überspringe keine Datenbank als Standardwert:
    skipdb=0
    # Wenn ausgeschlossene Datenbanken definiert sind:
    if [ "$ExDB" != "" ]; then
        # Loop über die ausgeschlossenen Datenbanken und ggf. Flag setzen:
        for n in $ExDB; do
            if [ "$db" = "$n" ]; then
                skipdb=1
                break;
            fi
        done
    fi

    if [ "$skipdb" = "1" ] ; then
        echo "überspringe Datenbank $db"
        SKIPDBCOUNT=$((SKIPDBCOUNT + 1))
        continue
    fi

    DBCOUNT=$((DBCOUNT + 1))

    modBACKUPDIR="${BACKUPDIR}"
    if [ "$useSubDir" = true ]; then
        modBACKUPDIR="${BACKUPDIR}/${db}"
        if [ ! -d "${modBACKUPDIR}" ]; then
            mkdir -p "${modBACKUPDIR}"
        fi
    fi

    fn="${modBACKUPDIR}/MySQLdump_${db}_${DATE}.sql.gz"

    printf "\n\nDump Datenbank $db nach %s\n\n" "${fn}"

    # shellcheck disable=SC2086
    # shellcheck disable=SC2154
    $mysqldump $DBLOGIN --databases $db | gzip -c -9 > "${fn}"
    retcode=$?
    if [ $retcode -ne 0 ]; then
        echo "Fehler beim Erzeugen eines Dumps der Datenbank $db"
        exit $retcode
    else
        echo "Dump der Datenbank $db erfolgreich"
        DBCOUNT=$((DBCOUNT + 1))
    fi
    sleep 1

    # Rotation, sofern man das Skript "archive_rotate" von hier verwendet: https://github.com/geimist/archive_rotate
    if [ "$Rotate" = true ]; then
        echo "Start Rotation of Dumps..."
        # shellcheck disable=SC2154
        "${ScriptRotate}" -vc -p="${modBACKUPDIR}" -s=MySQLdump_"${db}"_* -h=1x4 -d=24x7 -w=7x4 -m=4x6 -y=4x*
    fi
done

# Und zum Schluss noch ein Gesamtbackup:
if [ "$DumpAll" = true ]; then
    modBACKUPDIR="${BACKUPDIR}"
    # Wenn ein Unterverzeichnis für die DBs genutzt werden soll, dann einen Unterordner für das Gesamtbackup anlegen und modBACKUPDIR anpassen:
    if [ "$useSubDir" = true ]; then
        modBACKUPDIR="${BACKUPDIR}/GESAMT"
        if [ ! -d "${modBACKUPDIR}" ]; then
            mkdir -p "${modBACKUPDIR}"
        fi
    fi
    fn="${modBACKUPDIR}/MySQLdump_GESAMTBACKUP_${DATE}.sql.gz"
    printf "\n\nDump GESAMT nach %s\n\n" "${fn}"

    # shellcheck disable=SC2086
    $mysqldump --opt $DBLOGIN --all-databases | gzip -c -9 > "${fn}"
    retcode=$?
    if [ $retcode -ne 0 ]; then
        echo "Fehler beim Erzeugen eines Dumps der GESAMT-Datenbank"
        exit $retcode
    else
        echo "Dump der GESAMT-Datenbank erfolgreich"
        DBCOUNT=$((DBCOUNT + 1))
    fi
    sleep 1


    # Rotation, sofern man das Skript "archive_rotate" von hier verwendet: https://github.com/geimist/archive_rotate
    if [ "$Rotate" = true ]; then
        echo "Start Rotation of Dumps..."
        "${ScriptRotate}" -vc -p="${modBACKUPDIR}" -s=MySQLdump_GESAMTBACKUP_* -h=1x4 -d=24x7 -w=7x4 -m=4x6 -y=4x*
    fi
fi

echo -e
echo "    gesicherte DB's:      $DBCOUNT"
echo "    übersprungene DB's:   $SKIPDBCOUNT"

exit 0
