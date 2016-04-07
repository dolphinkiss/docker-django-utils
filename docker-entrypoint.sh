#!/bin/bash

if [ "$1" == "backup" ]; then
    while [ 1 ]; do
        missing_env=""
        for required_env in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_BUCKET_NAME UTILS_BACKUP_SLEEP AWS_BUCKET_PREFIX; do
            environment_value=`printenv "$required_env"` || { missing_env="yes"; echo "ERROR: Environment variable '$required_env' is required for backup to function"; }
        done
        if [ "$missing_env" != "" ]; then
            exit 1
        fi

        echo "Sleeping $UTILS_BACKUP_SLEEP seconds until next backup"
        sleep $UTILS_BACKUP_SLEEP

        BACKUP_TIME=`date +%F_%R`
        BASE_BACKUP_LOCATION="s3://$AWS_BUCKET_NAME/$AWS_BUCKET_PREFIX/$BACKUP_TIME"

        if [ "$UTILS_BACKUP_DB_HOST" != "" ]; then
            missing_env=""
            for required_env in UTILS_BACKUP_DB_HOST UTILS_BACKUP_DB_PORT UTILS_BACKUP_DB_USER UTILS_BACKUP_DB_NAME; do
                environment_value=`printenv "$required_env"` || { missing_env="yes"; echo "ERROR: Environment variable '$required_env' is required for backup to function"; }
            done
            if [ "$missing_env" != "" ]; then
                exit 1
            fi
            for optional_env in UTILS_BACKUP_DB_PASS; do
                environment_value=`printenv "$optional_env"` || { echo "INFO: Optional environment variable '$optional_env' not in use"; }
            done
            if [ "$UTILS_BACKUP_DB_PASS" != "" ]; then
                export PGPASSWORD="$UTILS_BACKUP_DB_PASS"
            fi

            BACKUP_LOCATION="$BASE_BACKUP_LOCATION/db.sql.gz"
            echo "pg_dump to $BACKUP_LOCATION of postgres://$UTILS_BACKUP_DB_USER:****@$UTILS_BACKUP_DB_HOST:$UTILS_BACKUP_DB_PORT/$UTILS_BACKUP_DB_NAME"
            pg_dump --no-owner --clean -d "$UTILS_BACKUP_DB_NAME" -h "$UTILS_BACKUP_DB_HOST" -p "$UTILS_BACKUP_DB_PORT" -U "$UTILS_BACKUP_DB_USER" | gzip | /venv/bin/aws s3 cp - "$BACKUP_LOCATION"
        else
            echo "Environment variable 'UTILS_BACKUP_DB_HOST' is not set, so no database backup is performed"
        fi

        if [ "$UTILS_BACKUP_DIRS" == "" ]; then
            echo "Environment variable UTILS_BACKUP_DIRS not set, so not performing any file backups"
        else
            for source_directory in ${UTILS_BACKUP_DIRS//;/ }; do
                archive_filename=`echo "$source_directory" | sed 's,^/,,g' | sed 's,/$,,g' | sed 's,/,--,g'`
                BACKUP_LOCATION="$BASE_BACKUP_LOCATION/$archive_filename.tar.gz"
                echo "Backing up $source_directory to $BACKUP_LOCATION"
                tar -czf - "$source_directory/" | /venv/bin/aws s3 cp - "$BACKUP_LOCATION"
            done
        fi
    done
else
    if [ "$1" == "stayalive" ]; then
        touch /tmp/stayalive.file
        tail -f /tmp/stayalive.file
    else
        exec "$@"
    fi
fi
