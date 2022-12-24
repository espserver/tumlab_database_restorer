#!/bin/bash

# Search files in Syncting folder modified in 5200 mins and type is .sql
find /tumlab/syncthing/ -type f -mmin -5200 -and -type f -iname "*.sql" > /tumlab/syncthing/dump.txt
# Exit=
# /tumlab/syncthing/MAC-ADDRESS/databases/postgresql/mediacms/BT1P2D3T4I5B6_MACADD_MEDIACMS_2022-12-23_16-37-13.sql
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
    psql -h localhost -U postgres -c "DROP DATABASE $db_name"
    psql -h localhost -U postgres -c "CREATE DATABASE $db_name"
    psql -h localhost -U postgres -d "$db_name" -f "$line"
    check_error="$?"
    # Consultar como implementar esta funcion
    if [[ check_error -eq 0 ]]; then
      restorer_db="restorer_db_${tumlab_name}_${db_vendor}_${db_name}"
      echo "$restorer_db"
      restorer_db=1
      echo "$restorer_db"
    fi
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
    echo "$line"
    #mysql -u usuario -ppassword $db_name < "$line"
  fi
done < /tumlab/syncthing/dump.txt


