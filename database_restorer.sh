#!/bin/bash
logger -p local0.debug -it tumlab_database_restorer "Start Execution script"

# Path where the tumlab folders are located
devices_path="/tumlab/syncthing/"
echo "devices_path="$devices_path
logger -p local0.debug -it tumlab_database_restorer "Path where the tumlab folders are located: $devices_path"

# Path where the json file are located
json_restored_dbs="/tumlab/syncthing/dbs_restored_list.json"
echo "$json_restored_dbs"
logger -p local0.debug -it tumlab_database_restorer "Path where the json file are located: $json_restored_dbs"

# Txt file location to list .sql files to restore
dump_list="/tumlab/syncthing/dump.txt"
echo "dump_list="$dump_list
logger -p local0.debug -it tumlab_database_restorer "Path where the list .sql file to restore are located: $dump_list"

# Maximum .sql file creation time to restore (in minutes)
max_modification_time="30"
echo "max_modification_time="$max_modification_time
logger -p local0.debug -it tumlab_database_restorer "Maximum .sql file creation time to restore (in minutes): $max_modification_time"

# Server info
public_ip=$(curl ifconfig.me)
echo "$public_ip"
logger -p local0.debug -it tumlab_database_restorer "Server IP: $public_ip"
server_name=$(hostname)
echo "$server_name"
logger -p local0.debug -it tumlab_database_restorer "Server name: $server_name"
id_server=1
echo "$id_server"
logger -p local0.debug -it tumlab_database_restorer "Server ID: $id_server"

mysql_user="ramiro"
mysql_password="Ramiro"
postgres_user="postgres"
postgres_password="Ramiro"
# echo $postgres_password


# Search files in Syncting folder modified in 30 mins and type is .sql

find "$devices_path" -type f -mmin -"$max_modification_time" -and -type f -iname "*.sql" > "$dump_list"
logger -p local0.debug -it tumlab_database_restorer "looking for sql files modified $max_modification_time minutes ago in $devices_path and listing them in $dump_list"

checkExitsFile() {
    logger -p local0.debug -it tumlab_database_restorer "Using function check if exist file. File to check: $1"
    file="$1"
    retval=""
    if [[ -f "$file" ]]; then
        retval="true"
        logger -p local0.debug -it tumlab_database_restorer "File exists?: $retval"
    else
        retval="false"
        logger -p local0.debug -it tumlab_database_restorer "File exists?: $retval"
    fi
    echo $retval
}

exists_json_file=$(checkExitsFile "$json_restored_dbs")
if [[ $exists_json_file == 'false' ]]; then
  file_json_restored_dbs="{ \"id_server\":\"$id_server\", \"server_name\":\"$server_name\", \"ip\":\"$public_ip\", \"db_vendor\":{\"mysql\":[], \"postgresql\":[] } }"
  echo "$file_json_restored_dbs" | jq '.' >"$json_restored_dbs" 
  logger -p local0.debug -it tumlab_database_restorer "since the json does not exist, creating json: $json_restored_dbs"
fi

exists_pgpass_file=$(checkExitsFile ~/.pgpass)
if [[ $exists_pgpass_file == 'false' ]]; then
  logger -p local0.debug -it tumlab_database_restorer "Since the .pgpass file does not exist, creating .pgpass file"
  echo "*:5432:*:$postgres_user:$postgres_password" >> ~/.pgpass
  chmod 600 ~/.pgpass
fi

array_db_vendor=("mysql" "postgresql")

while IFS= read -r line
do
  logger -p local0.debug -it tumlab_database_restorer "Start of cycle to restore the dbs from archive $dump_list"
  
  # Viariables name
  tumlab_name=$(echo "$line" | awk -F '/' '{print $4}')
  logger -p local0.debug -it tumlab_database_restorer "Parameters to restore: tumlab_name=$tumlab_name"
  echo "tumlab_name=$tumlab_name"
  db_vendor=$(echo "$line" | awk -F '/' '{print $6}')
  logger -p local0.debug -it tumlab_database_restorer "Parameters to restore: db_vendor=$db_vendor"
  echo "db_vendor=$db_vendor"
  app_name=$(echo "$line" | awk -F '/' '{print $7}')
  logger -p local0.debug -it tumlab_database_restorer "Parameters to restore: app_name=$app_name"
  echo "app_name=$app_name"
  file_name=$(echo "$line" | awk -F '/' '{print $8}')
  logger -p local0.debug -it tumlab_database_restorer "Parameters to restore: file_name=$file_name"
  echo "file_name=$file_name"
  date=$(echo "$file_name" | awk -F '_' '{print $4,$5}'| awk -F '.' '{print $1}')
  logger -p local0.debug -it tumlab_database_restorer "Parameters to restore: date=$date"
  echo "date=$date"
  db_name=$(echo "$line" | awk -F '/' '{print $8}'| awk -F '.' '{print $1}'| tr '-' '_' | tr '[:upper:]' '[:lower:]')
  logger -p local0.debug -it tumlab_database_restorer "Parameters to restore: db_name=$db_name"
  echo "db_name=$db_name"

  short_db_name=$(echo "$line" | awk -F '/' '{print $8}' |awk -F '-' '{print $1}' | tr '[:upper:]' '[:lower:]')
  echo "$short_db_name"

  old_db_record=$( cat $json_restored_dbs | grep "$short_db_name" | awk -F '"' '{print $4}')
  echo "test print: $old_db_record"
  logger -p local0.debug -it tumlab_database_restorer "Old db name=$old_db_record"   

  id_batch="${file_name:2:1}"
  logger -p local0.debug -it tumlab_database_restorer "Tumlab database to restore info id_batch=$id_batch"
  echo "id_batch:$id_batch"

  id_project="${file_name:4:1}"
  logger -p local0.debug -it tumlab_database_restorer "Tumlab database to restore info id_project=$id_project"
  echo "id_project:$id_project"

  id_deparment="${file_name:6:1}"   
  logger -p local0.debug -it tumlab_database_restorer "Tumlab database to restore info id_deparment=$id_deparment"
  echo "id_deparment:$id_deparment"

  id_town="${file_name:8:1}"
  logger -p local0.debug -it tumlab_database_restorer "Tumlab database to restore info id_town=$id_town"
  echo "id_town:$id_town"

  id_institution="${file_name:10:1}"
  logger -p local0.debug -it tumlab_database_restorer "Tumlab database to restore info id_institution=$id_institution"
  echo "id_institution:$id_institution"

  id_branch="${file_name:12:1}"
  logger -p local0.debug -it tumlab_database_restorer "Tumlab database to restore info id_branch=$id_branch"
  echo "id_branch:$id_branch"
  
  mac_address="${file_name:14:12}"
  logger -p local0.debug -it tumlab_database_restorer "Tumlab database to restore info mac_address:$mac_address"
  echo "mac_address:$mac_address"

  check_db_vendor_support="false"
    for item in "${array_db_vendor[@]}"; do
      logger -p local0.debug -it tumlab_database_restorer "Start loop to check if db_vendor is supported"
        if [ "$item" == "$db_vendor" ]; then
            check_db_vendor_support="true"
            echo "db_vendor is supported?:$check_db_vendor_support"
            logger -p local0.debug -it tumlab_database_restorer "db_vendor is supported?:$check_db_vendor_support"
        fi
      logger -p local0.debug -it tumlab_database_restorer "End loop to check if db_vendor is supported"  
    done

  case "${db_vendor}" in
  "postgresql")
    logger -p local0.debug -it tumlab_database_restorer "Case $db_vendor in cycle to restore the dbs"
    if [ "$db_name" == "$old_db_record" ]; then
      logger -p local0.debug -it tumlab_database_restorer "Db to restore is equal to old db restored"
      echo "database $db_name not restored, already exists"
      logger -p local0.debug -it tumlab_database_restorer "Database $db_name not restored, already exists"
    else
      nohup psql -h localhost -U $postgres_user -c "CREATE DATABASE $db_name"
      logger -p local0.debug -it tumlab_database_restorer "Create database $db_name in $db_vendor"
      nohup psql -h localhost -U $postgres_user -d "$db_name" -f "$line"
      logger -p local0.debug -it tumlab_database_restorer "Restore database $db_name in $db_vendor"
      check_error="$?"
      if [[ check_error -eq 0 ]]; then
        echo "Successful restore of $db_name database"
        logger -p local0.debug -it tumlab_database_restorer "Successful restore of $db_name database"
        nohup psql -h localhost -U $postgres_user -c "DROP DATABASE $old_db_record"
        logger -p local0.debug -it tumlab_database_restorer "Deleting old db: $old_db_record"
        jq '.db_vendor.'"$db_vendor"' += [{"db_name":"'"$db_name"'","id_batch":"'"$id_batch"'","id_project":"'"$id_project"'","id_deparment":"'"$id_deparment"'","id_town":"'"$id_town"'","id_institution":"'"$id_institution"'","id_branch":"'"$id_branch"'","mac_address":"'"$mac_address"'"}]' $json_restored_dbs > tmp.json && rm $json_restored_dbs && jq '.' tmp.json > $json_restored_dbs && rm tmp.json
        logger -p local0.debug -it tumlab_database_restorer "Adding new database record in json file"
        jq 'del(.db_vendor.'"$db_vendor"'[] | select(.db_name == "'"$old_db_record"'"))' $json_restored_dbs > tmp.json && rm $json_restored_dbs && jq '.' tmp.json > $json_restored_dbs && rm tmp.json
        logger -p local0.debug -it tumlab_database_restorer "Deleting old database record in json file"
      else
        echo "Failed restore $db_name database"
        logger -p local0.debug -it tumlab_database_restorer "Failed restore $db_name database" 
      fi
    fi
    ;;

  "mysql")
    if [ "$db_name" == "$old_db_record" ]; then
      logger -p local0.debug -it tumlab_database_restorer "Db to restore is equal to old db restored"
      echo "database $db_name not restored, already exists"
      logger -p local0.debug -it tumlab_database_restorer "Database $db_name not restored, already exists"
    else
      logger -p local0.debug -it tumlab_database_restorer "Create database $db_name in $db_vendor"
      mysql -u $mysql_user -p$mysql_password --execute="CREATE DATABASE $db_name"
      mysql -u $mysql_user -p$mysql_password "$db_name" < "$line"
      logger -p local0.debug -it tumlab_database_restorer "Restore database $db_name in $db_vendor"
      check_error="$?"
      if [[ check_error -eq 0 ]]; then
        echo "Successful restore of $db_name database"
        logger -p local0.debug -it tumlab_database_restorer "Successful restore of $db_name database"
        mysql -u $mysql_user -p$mysql_password --execute="DROP DATABASE $old_db_record"
        logger -p local0.debug -it tumlab_database_restorer "Deleting old db: $old_db_record"
        logger -p local0.debug -it tumlab_database_restorer "Adding new database record in json file"
        jq '.db_vendor.'"$db_vendor"' += [{"db_name":"'"$db_name"'","id_batch":"'"$id_batch"'","id_project":"'"$id_project"'","id_deparment":"'"$id_deparment"'","id_town":"'"$id_town"'","id_institution":"'"$id_institution"'","id_branch":"'"$id_branch"'","mac_address":"'"$mac_address"'"}]' $json_restored_dbs > tmp.json && rm $json_restored_dbs && jq '.' tmp.json > $json_restored_dbs && rm tmp.json
        jq 'del(.db_vendor.'"$db_vendor"'[] | select(.db_name == "'"$old_db_record"'"))' $json_restored_dbs > tmp.json && rm $json_restored_dbs && jq '.' tmp.json > $json_restored_dbs && rm tmp.json
        logger -p local0.debug -it tumlab_database_restorer "Deleting old database record in json file"
      else
        echo "Failed restore $db_name database"
        logger -p local0.debug -it tumlab_database_restorer "Failed restore $db_name database"
      fi
    fi
      ;;
  *)
      echo "db_vendor no supported"
      logger -p local0.debug -it tumlab_database_restorer "db_vendor $db_vendor no supported"
      ;;
  esac
logger -p local0.debug -it tumlab_database_restorer "End cycle to restore the dbs from archive $dump_list"
done < "$dump_list"
rm nohup.out
