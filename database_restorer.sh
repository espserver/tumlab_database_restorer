#!/bin/bash

# Path where the tumlab folders are located
devices_path="/tumlab/syncthing/"
echo "devices_path="$devices_path

# Txt file location to list .sql files to restore
dump_list="/tumlab/syncthing/dump.txt"
echo "dump_list="$dump_list

# Maximum .sql file creation time to restore (in minutes)
max_modification_time="30"
echo "max_modification_time="$max_modification_time

mysql_user="ramiro"
mysql_password="Ramiro"
postgres_user="postgres"
postgres_password="Ramiro"
echo $postgres_password

# Search files in Syncting folder modified in 30 mins and type is .sql
find "$devices_path" -type f -mmin -"$max_modification_time" -and -type f -iname "*.sql" > "$dump_list"

# se debe crear un archivo que contenga la contraseña del usuario de la base de datos
# echo "192.168.0.1:5432:mibase:miusuario:micontraseña" >> ~/.pgpass todos los campos se pueden remplazar por el comodin * excepto la contrase

# Ciclo encargado de ejecutar la restauracion de cada archivo dump enlistado en el txt de arriba
while IFS= read -r line
do
  if [[ "$line" == *"postgres"* ]]; then
    tumlab_name=$(echo "$line" | awk -F '/' '{print $4}')
    echo "tumlab_name=$tumlab_name"
    db_vendor=$(echo "$line" | awk -F '/' '{print $6}')
    echo "db_vendor=$db_vendor"
    db_name=$(echo "$line" | awk -F '/' '{print $7}')
    echo "db_name=$db_name"
    file_name=$(echo "$line" | awk -F '/' '{print $8}')
    echo "file_name=$file_name"
    date=$(echo "$file_name" | awk -F '_' '{print $4,$5}'| awk -F '.' '{print $1}')
    echo "date=$date"
    echo "$line"
    psql -h localhost -U $postgres_user -c "DROP DATABASE $db_name"
    psql -h localhost -U $postgres_user -c "CREATE DATABASE $db_name"
    psql -h localhost -U $postgres_user -d "$db_name" -f "$line"
    check_error="$?"
    if [[ check_error -eq 0 ]]; then
      echo "Successful restore of $db_name database"
    else
      echo "Failed restore $db_name database"
    fi
    # Consultar como implementar esta funcion
    #if [[ check_error -eq 0 ]]; then
    #  restorer_db="restorer_db_${tumlab_name}_${db_vendor}_${db_name}"
    #  echo "$restorer_db"
    #  restorer_db=1
    #  echo "$restorer_db"
    #fi
  else
    tumlab_name=$(echo "$line" | awk -F '/' '{print $4}')
    echo "tumlab_name=$tumlab_name"
    db_vendor=$(echo "$line" | awk -F '/' '{print $6}')
    echo "db_vendor=$db_vendor"
    db_name=$(echo "$line" | awk -F '/' '{print $7}')
    echo "db_name=$db_name"
    db_vendor=$(echo "$line" | awk -F '/' '{print $6}')
    echo "db_vendor=$db_vendor"
    file_name=$(echo "$line" | awk -F '/' '{print $8}')
    echo "file_name=$file_name"
    date=$(echo "$file_name" | awk -F '_' '{print $4,$5}'| awk -F '.' '{print $1}')
    echo "date=$date"
    echo "$line"
    mysql -u $mysql_user -p$mysql_password --execute="DROP DATABASE $db_name;CREATE DATABASE $db_name"
    mysql -u $mysql_user -p$mysql_password "$db_name" < "$line"
    check_error="$?"
    if [[ check_error -eq 0 ]]; then
      echo "Successful restore of $db_name database"
    else
      echo "Failed restore $db_name database"
    fi

  fi
done < "$dump_list"
