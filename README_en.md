[Deutsch](README.md) | English

# MariaDB_dump

## Description
MariaDB_dump is a shell script designed to export all existing databases from a MySQL or MariaDB database engine individually, allowing them to be backed up to a specified storage location.
To enable periodic backups of the databases, it is recommended to define a Cron job. However, this document does not cover the setup of automatic script execution using a Cron job.

## Installation
Clone the Git repository using `git clone`.

First, create a directory where the repository's snapshot will be stored.  
Then, navigate to this directory and execute the Git command to clone the repository.  
<ins>Example:</ins>
```
mkdir -p /root/github
cd /root/github
git clone https://github.com/geimist/MariaDB_dump.git
```

## Configuration
Use the configuration template [config.cnf.template](cnf/config.cnf.template) to create your own configuration by making a copy of this file and naming it *config.cnf*.

The parameters to be configured within this configuration file are as follows:

### MySQL Root Password
This refers to the MySQL/MariaDB password for the *root* user.  
Providing the password is only necessary if the shell script is not executed as the root user on the system from which the databases are being backed up.  
Only when the script is executed as a regular user is it required to specify the root password for the MySQL/MariaDB database.

<ins>Example:</ins>  
If no password is provided because the script is executed as the system user root, the variable can be defined as an empty string.
```
MYSQLPW=""
```
Otherwise, the password is specified within double quotes.
```
MYSQLPW="VerySecureMariaDB_PW"
```

### Backup Directory
The backup directory is the location where the exported databases will be stored.  
This must be specified or otherwise no data can be exported.

<ins>Example:</ins>
```
BACKUPDIR="/volume1/system/DS_BackUps/MariaDB_DUMP_test"
```

### Use Subdirectories
This parameter specifies whether a subdirectory should be created for each individually exported database within the previously defined backup destination.  
This can be helpful for better organization when dealing with a large number of databases.

To create a separate subdirectory for each database, this parameter must be enabled.

<ins>Example:</ins>  
Enable subdirectories:
```
useSubDir=true
```
If no subdirectories are desired, the parameter can take any value. In this example, the term *false* is used to achieve this.
```
useSubDir=false
```

### Full Backup
In addition to exporting individual databases, it is also possible to create a full backup of the entire MySQL/MariaDB database in a single file.

To enable additionally a full backup of the entire database, this parameter must be activated.

<ins>Example:</ins>  
Enable full backup:
```
DumpAll=true
```
To skip creating a full backup of the database in a single file, the parameter can take any value. In this example, the term *false* is used to achieve this.
```
DumpAll=false
```

### Date Format for File Names
Each exported file will include the respective database name and the date in the file name.

The default format from the template is as follows: `YYYY-MM-DD_hh-mm-ss` (e.g., 2025-04-08_19-04-27).

<ins>Example:</ins>
```
DATE=$(date +%Y-%m-%d_%H-%M-%S)
```
Available formats and their usage can be found in the [date(1)](https://man7.org/linux/man-pages/man1/date.1.html) manual.

### Program Paths
The program paths are necessary to define the location of the required tools. This is important because these tools may not be installed in the same location across different systems.  
For most Linux distributions, the default tools are usually located in standard paths.

The default configuration in the template automatically defines these paths using the `which` command.  
If this does not work for unknown reasons, the paths to the required tools can also be manually defined.

The required tools are the database engine `mysql` and `mysqldump` for exporting the databases.

The default configuration is:
```
DBengine="$(which mysql)"
mysqldump="$(which mysqldump)"
```
A manual assignment would look like this:
```
DBengine="/usr/bin/mysql"
mysqldump="/usr/bin/mysqldump"
```

### Excluding Databases from Backup
Sometimes, it is not desirable to export all available databases, especially if they are used for testing purposes.

Each database to be excluded from the backup can be specified in this parameter. If more than one database needs to be excluded, multiple databases can be listed, separated by spaces.

<ins>Example:</ins>
```
ExDB="mysql sys phpmyadmin information_schema performance_schema"
```
In this example, a total of 5 databases are excluded from the backup:
1. mysql  
2. sys  
3. phpmyadmin  
4. information_schema  
5. performance_schema  

### Rotation of Backup Archives
To save storage space, it is useful not to keep every single archive file indefinitely. To manage stored archives, an additional script can be integrated for this purpose.  
For example, the script [archive_rotate](https://github.com/geimist/archive_rotate) can be used.

#### Enable Rotation
To use rotation, this parameter must be activated.  
<ins>Example:</ins>  
Enable rotation:
```
Rotate=true
```
To proceed without rotation, the parameter can take any value. In this example, the term *false* is used to achieve this.
```
Rotate=false
```

#### Path to the Rotation Script
The `archive_rotate` script can be stored anywhere on the system. To use it, the parameter must be configured with the path to the executable script file.

<ins>Example:</ins>
```
ScriptRotate="/volume1/path_to/archive_rotate.sh"
```

#### Parameters for Rotation
It can be defined how many backups from the past should be retained.  
The available parameters specify the number of archives to keep per year, month, week, day, and hour.

A detailed description can be found in the `archive_rotate` repository.

<ins>Example:</ins>
```
# Parameters for rotation:
HOURS="1x4"
DAYS="24x7"
WEEKS="7x4"
MONTHS="4x6"
YEARS="4x1"
```

## Execution
If the configuration file [cnf/config.cnf](cnf/config.cnf) is present, the script can be executed without providing additional arguments.  
Optionally, a configuration file can also be passed as the first argument.

Execution without arguments when the configuration file is located in the subdirectory `./cnf`:
```
./bin/MariaDB_DUMP.sh
```
With a configuration file passed as an argument:
```
./bin/MariaDB_DUMP.sh /<PATH_TO_CONFIG>
```

## Output
The script generates useful output and logs the process.

<ins>Example:</ins>  
This example shows the output when all individual databases and the entire database are exported.  
Additionally, databases defined under the exclusion parameter are ignored and excluded from the backup.

```
Login ohne Passwort


Dump Datenbank Test_Datenbank nach /volume2/backup/MariaDB_DUMP/Test_Datenbank/MySQLdump_Test_Datenbank_2025-04-08_22-35-26.sql.gz

Dump der Datenbank "Test_Datenbank" erfolgreich
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
