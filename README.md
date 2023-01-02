# TUMLAB DATABASE RESTORER

## Content
* [Prerequisites](#Prerequisites)
* [Description](#Description)
* [How to use](#How-to-use)

## Prerequisites
-   jq v1.6
-   mysql v8
-   postgresql v13


## Description
This script is developed to restore database backups located in any linux directory and save the log of the last restored database to a JSON file.

## How to use
-   Clone this repository
    ```
    git clone https://github.com/espserver/tumlab_database_restorer.git
    ```
-   Enter the project folder
    ```
    cd tumlab_database_restorer/
    ```
-   Change executable file permissions
    ```
    chmod +x database_restorer.sh
    ```
-   Modify the sh file with the necessary variables.
    Open sh file and change variables whit your server info
    *   devices_path = path where the folders containing the backups are located
    *   mysql_user=mysql user root
    *   mysql_password=mysql password root
    *   postgres_user="postgres user root
    *   postgres_password=postgres password root
-   Run sh file
    ```
    ./database_restorer.sh
    ```