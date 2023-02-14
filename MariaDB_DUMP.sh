#!/bin/bash
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

# MySQL-Rootkennwort:
    MYSQLPW="GanzSicherMariaDB_PW"

# Sicherungsverzeichenis:
    BACKUPDIR="/volume1/system/DS_BackUps/MariaDB_DUMP_test"

# ein Unterverzeichnis für jede DB nutzen? (true = ja / alles andere = nein)
    useSubDir=true

# auch ein Gesamtbackup anlegen? (true = ja / alles andere = nein)
    DumpAll=true

# Datumsformat für Dateiname:
    DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Programmpfade:
    DBengine="/var/packages/MariaDB10/target/usr/local/mariadb10/bin/mysql"
    mysqldump="/usr/local/mariadb10/bin/mysqldump"

# auszuschließende Datenbanken:
    ExDB="phpmyadmin information_schema performance_schema"

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
        SKIPDBCOUNT=$(($SKIPDBCOUNT + 1))
        continue
    fi
 
    DBCOUNT=$(($DBCOUNT + 1))

    modBACKUPDIR="${BACKUPDIR}"
    if [ "$useSubDir" = true ]; then
        modBACKUPDIR="${BACKUPDIR}/${db}"
        if [ ! -d "${modBACKUPDIR}" ]; then
            mkdir -p "${modBACKUPDIR}"
        fi        
    fi

    fn="${modBACKUPDIR}/MySQLdump_${db}_${DATE}.sql.gz"

    printf "\n\nDump Datenbank $db nach ${fn}\n\n"
    
    $mysqldump $DBLOGIN --databases $db | gzip -c -9 > "${fn}"
    sleep 1

# Rotation, sofern man das Skript "archive_rotate" von hier verwendet: https://git.geimist.eu/geimist/archive_rotate
#    /volume1/Pfad_zu/archive_rotate.sh -vc -p="${modBACKUPDIR}" -s=MySQLdump_${db}* -h=1x4 -d=24x7 -w=7x4 -m=4x6 -y=4x*
done

# Und zum Schluss noch ein Gesamtbackup:
    if [ "$DumpAll" = true ]; then
        printf "\n\nDump GESAMT $db nach ${fn}\n\n"
        DBCOUNT=$(($DBCOUNT + 1))
        modBACKUPDIR="${BACKUPDIR}"
        if [ "$useSubDir" = true ]; then
            modBACKUPDIR="${BACKUPDIR}/GESAMT"
            if [ ! -d "${modBACKUPDIR}" ]; then
                mkdir -p "${modBACKUPDIR}"
            fi
        fi

        $mysqldump --opt $DBLOGIN --all-databases | gzip -c -9 > ${modBACKUPDIR}/MySQLdump_GESAMTBACKUP_${DATE}.gz
        sleep 1

    # Rotation, sofern man das Skript "archive_rotate" von hier verwendet: https://git.geimist.eu/geimist/archive_rotate
#        /volume1/Pfad_zu/archive_rotate.sh -vc -p="${modBACKUPDIR}" -s=MySQLdump_GESAMTBACKUP_* -h=1x4 -d=24x7 -w=7x4 -m=4x6 -y=4x*
    fi

echo -e
echo "    gesicherte DB's:      $DBCOUNT"
echo "    übersprungene DB's:   $SKIPDBCOUNT"

exit 0