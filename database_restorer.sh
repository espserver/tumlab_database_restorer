#!/bin/bash

# Path where the tumlab folders are located
devices_path="/tumlab/syncthing/"
echo "devices_path="$devices_path

json_restored_dbs="/tumlab/syncthing/dbs_restored_list.json"
echo "$json_restored_dbs"

# Txt file location to list .sql files to restore
dump_list="/tumlab/syncthing/dump.txt"
echo "dump_list="$dump_list

# Maximum .sql file creation time to restore (in minutes)
max_modification_time="5000"
echo "max_modification_time="$max_modification_time
# Server info
public_ip=$(curl ifconfig.me)
echo "$public_ip"
server_name=$(hostname)
echo "$server_name"
id_server=1
echo "$id_server"

mysql_user="ramiro"
mysql_password="Ramiro"
postgres_user="postgres"
postgres_password="Ramiro"
echo $postgres_password


# Search files in Syncting folder modified in 30 mins and type is .sql
find "$devices_path" -type f -mmin -"$max_modification_time" -and -type f -iname "*.sql" > "$dump_list"

checkExitsFile() {
    file="$1"
    retval=""
    if [[ -f "$file" ]]; then
        retval="true"
    else
        retval="false"
    fi
    echo $retval
}

exists_json_file=$(checkExitsFile "$json_restored_dbs")
if [[ $exists_json_file == 'false' ]]; then
  file_json_restored_dbs="{ \"id_server\":\"$id_server\", \"server_name\":\"$server_name\", \"ip\":\"$public_ip\", \"db_vendor\":{\"mysql\":[], \"postgresql\":[] } }"
  echo "$file_json_restored_dbs" | jq '.' >"$json_restored_dbs"
fi

# se debe crear un archivo que contenga la contraseña del usuario de la base de datos
# echo "192.168.0.1:5432:mibase:miusuario:micontraseña" >> ~/.pgpass todos los campos se pueden remplazar por el comodin * excepto la contraseña

# Arreglo de bases de datos

array_db_vendor=("mysql" "postgresql")

# Ciclo encargado de ejecutar la restauracion de cada archivo dump enlistado en el txt de arriba
while IFS= read -r line
do
  # Viariables name

  tumlab_name=$(echo "$line" | awk -F '/' '{print $4}')
  echo "tumlab_name=$tumlab_name"
  db_vendor=$(echo "$line" | awk -F '/' '{print $6}')
  echo "db_vendor=$db_vendor"
  app_name=$(echo "$line" | awk -F '/' '{print $7}')
  echo "app_name=$app_name"
  file_name=$(echo "$line" | awk -F '/' '{print $8}')
  echo "file_name=$file_name"
  date=$(echo "$file_name" | awk -F '_' '{print $4,$5}'| awk -F '.' '{print $1}')
  echo "date=$date"
  db_name=$(echo "$line" | awk -F '/' '{print $8}'| awk -F '.' '{print $1}'| tr '-' '_' | tr '[:upper:]' '[:lower:]')
  echo "db_name=$db_name"

  short_db_name=$(echo "$line" | awk -F '/' '{print $8}' |awk -F '-' '{print $1}' | tr '[:upper:]' '[:lower:]')
  echo "$short_db_name"

  old_db_record=$( cat $json_restored_dbs | grep "$short_db_name" | awk -F '"' '{print $4}')
  echo "test print: $old_db_record" 

  id_batch="${file_name:2:1}"
  echo "id_batch:$id_batch"
  id_project="${file_name:4:1}"
  echo "id_project:$id_project"
  id_deparment="${file_name:6:1}"   
  echo "id_deparment:$id_deparment"
  id_town="${file_name:8:1}"
  echo "id_town:$id_town"
  id_institution="${file_name:10:1}"
  echo "id_institution:$id_institution"
  id_branch="${file_name:12:1}"
  echo "id_branch:$id_branch"
  mac_address="${file_name:14:12}"
  echo "mac_address:$mac_address"
  echo "$line"
  check_db_vendor_support="false"
    for item in "${array_db_vendor[@]}"; do
        if [ "$item" == "$db_vendor" ]; then
            check_db_vendor_support="true"
            echo "db_vendor is supported?:$check_db_vendor_support"
        fi
    done

  case "${db_vendor}" in
  "postgresql")
    if [ "$db_name" == "$old_db_record" ]; then
      echo "database $db_name not restored, already exists"
    else
      nohup psql -h localhost -U $postgres_user -c "CREATE DATABASE $db_name"
      nohup psql -h localhost -U $postgres_user -d "$db_name" -f "$line"
      check_error="$?"
      if [[ check_error -eq 0 ]]; then
        echo "Successful restore of $db_name database"
        nohup psql -h localhost -U $postgres_user -c "DROP DATABASE $old_db_record"
        jq '.db_vendor.'"$db_vendor"' += [{"db_name":"'"$db_name"'","id_batch":"'"$id_batch"'","id_project":"'"$id_project"'","id_deparment":"'"$id_deparment"'","id_town":"'"$id_town"'","id_institution":"'"$id_institution"'","id_branch":"'"$id_branch"'","mac_address":"'"$mac_address"'"}]' $json_restored_dbs > tmp.json && rm $json_restored_dbs && jq '.' tmp.json > $json_restored_dbs && rm tmp.json
        jq 'del(.db_vendor.'"$db_vendor"'[] | select(.db_name == "'"$old_db_record"'"))' $json_restored_dbs > tmp.json && rm $json_restored_dbs && jq '.' tmp.json > $json_restored_dbs && rm tmp.json
      else
        echo "Failed restore $db_name database" 
      fi
    fi
    ;;

  "mysql")
    if [ "$db_name" == "$old_db_record" ]; then
      echo "database $db_name not restored, already exists"
    else
      mysql -u $mysql_user -p$mysql_password --execute="CREATE DATABASE $db_name"
      mysql -u $mysql_user -p$mysql_password "$db_name" < "$line"
      check_error="$?"
      if [[ check_error -eq 0 ]]; then
        echo "Successful restore of $db_name database"
        mysql -u $mysql_user -p$mysql_password --execute="DROP DATABASE $old_db_record"
        jq '.db_vendor.'"$db_vendor"' += [{"db_name":"'"$db_name"'","id_batch":"'"$id_batch"'","id_project":"'"$id_project"'","id_deparment":"'"$id_deparment"'","id_town":"'"$id_town"'","id_institution":"'"$id_institution"'","id_branch":"'"$id_branch"'","mac_address":"'"$mac_address"'"}]' $json_restored_dbs > tmp.json && rm $json_restored_dbs && jq '.' tmp.json > $json_restored_dbs && rm tmp.json
        jq 'del(.db_vendor.'"$db_vendor"'[] | select(.db_name == "'"$old_db_record"'"))' $json_restored_dbs > tmp.json && rm $json_restored_dbs && jq '.' tmp.json > $json_restored_dbs && rm tmp.json
      else
        echo "Failed restore $db_name database"
      fi
    fi
      ;;
  *)
      echo "db_vendor no supported"
      ;;
  esac
done < "$dump_list"
rm nohup.out

# para eliminar el objeto del arreglo, se requiere la posicion
# cat /tumlab/syncthing/dbs_restored_list.json | jq 'del(.db_vendor.postgresql[0])'
# cat /tumlab/syncthing/dbs_restored_list.json | jq 'del(.db_vendor.'"$db_vendor"'[] | select(.db_name == "'"$db_name"'"))'
# cat /tumlab/syncthing/dbs_restored_list.json | ./jq-linux64 'del(.db_vendor.mysql[] | select(.db_name | startswith("bt1p2d3t4i5b6_aabbccdd0011ss_lms_")))'
