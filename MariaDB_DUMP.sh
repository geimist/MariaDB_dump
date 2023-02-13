#!/bin/bash
#####################################################################################
#                                                                                   #
#   MARIADB-BackUp                                                                  #
#   v1.0.0 @ 2023-02-13                                                             #
#   © 2023 by geimist                                                               #
#                                                                                   #
#   source:                                                                         #
#   https://stefankonarski.de/content/mysql-backup-fuer-jede-datenbank-eine-datei   #
#                                                                                   #
#####################################################################################

# MySQL-Rootkennwort:
    MYSQLPW="GanzSicherMariaDB_PW"

# Sicherungsverzeichenis:
    BACKUPDIR="/volume1/system/DS_BackUps/MariaDB_DUMP"

# ein Unterverzeichnis für jede DB nutzen? (true = ja / alles andere = nein)
    useSubDir=true

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
# List for compressing files
FILE2COMPRESS=
DBCOUNT=0
SKIPDBCOUNT=0

# Loop over all databases
for db in $DBlist ; do
    # Don't skip any database as default
    skipdb=0
    # If excludable databases are defined
    if [ "$ExDB" != "" ]; then
        # Loop over excludable databases
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

    echo "Dump Datenbank $db nach ${fn}"
    
    $mysqldump $DBLOGIN --databases $db | gzip -c -9 > "${fn}"

# Rotation, sofern man das Skript "archive_rotate" von hier verwendet: https://git.geimist.eu/geimist/archive_rotate
#   /volume1/Pfad_zu/archive_rotate.sh -vc -p="${modBACKUPDIR}" -s=MySQLdump_${db}* -h=1x4 -d=24x7 -w=7x4 -m=4x6 -y=4x*
done

echo -e
echo "    gesicherte DB's:      $DBCOUNT"
echo "    übersprungene DB's:   $SKIPDBCOUNT"

# Und zum Schluss noch ein Gesamtbackup:
    modBACKUPDIR="${BACKUPDIR}"
    if [ "$useSubDir" = true ]; then
        modBACKUPDIR="${BACKUPDIR}/GESAMT"
        if [ ! -d "${modBACKUPDIR}" ]; then
            mkdir -p "${modBACKUPDIR}"
        fi
    fi

    $mysqldump --opt $DBLOGIN --all-databases | gzip -c -9 > ${modBACKUPDIR}/MySQLdump_GESAMTBACKUP_${DATE}.gz

# Rotation, sofern man das Skript "archive_rotate" von hier verwendet: https://git.geimist.eu/geimist/archive_rotate
#   /volume1/Pfad_zu/archive_rotate.sh -vc -p="${BACKUPDIR}" -s=MySQLdump_GESAMTBACKUP_* -h=1x4 -d=24x7 -w=7x4 -m=4x6 -y=4x*


exit 0