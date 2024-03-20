#!/bin/bash

# Copyright © 2021-2024 Devin (Devin ApS)
# DEVIN INSTALLER
# INSTALLER VERSION 1.0.2
installer_version="1.0.2"
# Colors :)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_file="devin_installer_$(date +%Y%m%d_%H%M%S).log"
devin_engine_download_location="https://download.devin.fm/downloads/server/latest/devin-engine.fmp12"
devin_handler_download_location="https://download.devin.fm/downloads/server/latest/handler.zip"
devin_server_utils_location="https://download.devin.fm/downloads/server/latest/sudo_utils.zip"


color_echo() {
    local color=$1
    local msg=$2
    local color_value=""
    local info_box=""

    case $color in
        "ERROR")
            color_value=$RED
            info_box="[-]"
            ;;
        "SUCCESS")
            color_value=$GREEN
            info_box="[+]"
            ;;
        "INFO")
            color_value=$YELLOW
            info_box="[*]"
            ;;
        "QUESTION")
            color_value=$BLUE
            info_box="[?]"
            ;;
        *)
            echo "Invalid color"
            return 1
    esac

    echo -e "${color_value}${info_box} ${msg}${NC}" | tee -a $log_file
}

# Uninstall function
uninstall() {
    color_echo "INFO" "Uninstalling Devin."
    # Stop the handler first lol
    service_name="devin-handler"
    
    if systemctl list-unit-files | grep -Fqw "$service_name"; then
        color_echo "INFO" "Stopping and disabling the handler service."
        sudo systemctl disable "$service_name"  
        sudo systemctl stop "$service_name" 
        service_file_path=$(systemctl show -p FragmentPath "$service_name" | cut -d= -f2)
        if [ -f "$service_file_path" ]; then
            rm "$service_file_path" 
            systemctl daemon-reload 
            systemctl reset-failed 
        fi
    fi
    color_echo "INFO" "Closing devin-engine.fmp12 and removing it."
    fmsadmin close devin-engine.fmp12 -u "$username" -p "$password" -f -y 
    rm -rf /opt/FileMaker/FileMaker\ Server/Data/Databases/devin-engine.fmp12 
    # remove the sudo entries in /etc/sudoers
    color_echo "INFO" "Removing sudo entries for devin."
    sed -i '/devin/d' /etc/sudoers 

    # remove devin from nginx
    if [ -f /opt/FileMaker/FileMaker\ Server/NginxServer/conf/devin.conf ]; then
        color_echo "INFO" "Removing devin from nginx."
        sed -i '/devin/d' /opt/FileMaker/FileMaker\ Server/NginxServer/conf/fms_nginx.conf 
        rm /opt/FileMaker/FileMaker\ Server/NginxServer/conf/devin.conf 
        fmsadmin restart httpserver -u "$username" -p "$password"  -f -y 
    fi
    color_echo "INFO" "Terminating all processes owned by devin."
    pkill -9 -u devin
    # remove the devin user
    color_echo "INFO" "Removing devin user."
    userdel -r devin 
    groupdel devin 
    rm -rf /opt/Devin 
    color_echo "SUCCESS" "Devin has been uninstalled."
    exit 1
}


# Lets install :-)
color_echo "INFO" "Devin installer starting. Please consult the '$log_file' file if you encounter errors."

# Check if script is ran as root
if [[ $EUID -ne 0 ]]; then
   color_echo "ERROR" "This script must be run as root." 
   exit 1
fi

# Check if is linux
if [[ $(uname) != "Linux" ]]; then
    color_echo "ERROR" "This script is only supported on Linux."
    exit 1
fi


# Check if systemctl exists
if ! which systemctl >/dev/null 2>&1; then
    color_echo "ERROR" "Systemctl (systemd) is not available on this system. You will need systemd to continue."
    read -p "Do you want to install systemd? (y/n): " install_systemd
    if [[ $install_systemd == "y" ]]; then
        color_echo "INFO" "Installing systemd."
        apt-get install -y systemd >> $log_file 2>&1
    else
        color_echo "ERROR" "Installation aborted. Please install systemd and run the script again."
        exit 1
    fi
fi




# Check if arguments are passed to the script
if [[ $# -gt 0 ]]; then
    # Check if all required arguments are set
    if [[ $# -ne 6 ]]; then
        color_echo "ERROR" "Invalid number of arguments. Please provide --username, --password, and --type."
        exit 1
    fi

    # Parse arguments and assign values to variables
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --username)
                shift
                username="$1"
                ;;
            --password)
                shift
                password="$1"
                ;;
            --type)
                shift
                type="$1"
                ;;
            *)
                color_echo "ERROR" "Invalid argument: $1"
                exit 1
                ;;
        esac
        shift
    done

    # Check if any of the arguments are empty
    if [[ -z "$username" || -z "$password" || -z "$type" ]]; then
        color_echo "ERROR" "One or more arguments are empty. Please provide values for --username, --password, and --type."
        exit 1
    fi

    # Check if type is valid
    if [[ "$type" != "dev" && "$type" != "prod" ]]; then
        color_echo "ERROR" "Invalid value for --type. Please provide either 'dev' or 'prod'."
        exit 1
    fi
fi

# Check if filemaker server is even installed
if ! which fmsadmin >/dev/null 2>&1; then
    color_echo "ERROR" "FileMaker Server is not installed, please install it first."
    exit 1
fi

# Log setup
os_type=$(lsb_release -d | awk -F ':\t' '{print $2}')
os_version=$(lsb_release -r | awk -F ':\t' '{print $2}')
uname=$(uname -a)
fmsadmin_version=$(fmsadmin -u a -p a -v < /dev/null | grep -oP 'fmsadmin: Version \K\S+')
echo "############## INSTALLING DEVIN - BEGIN INSTALLER LOG FILE ##############" >>  $log_file 2>&1
echo "############## INSTALLER VERSION: $installer_version ##############" >>  $log_file 2>&1
echo -e "## Time ## \n$(date)" >> $log_file 2>&1
echo -e "## lsb_release ## \n$os_type $os_version" >>  $log_file 2>&1
echo -e "## uname -a ##\n$uname" >>  $log_file 2>&1
echo -e "## fmsadmin version ##\n$fmsadmin_version" >>  $log_file 2>&1



# Run an apt-get update first
color_echo "INFO" "Running apt-get update."
apt-get update >> $log_file 2>&1

# Check if jq is installed, if not install
if ! which jq >/dev/null 2>&1; then
    color_echo "INFO" "Installing jq." 
    apt-get install -y jq >> $log_file 2>&1
fi

# Check if curl is installed, if not install
if ! which curl >/dev/null 2>&1; then
    color_echo "INFO" "Installing curl." 
    apt-get install -y curl >> $log_file 2>&1
fi

# Prompt for username if not set
if [[ -z "$username" ]]; then
    color_echo "QUESTION" "Please enter your username for FileMaker Admin Console:"
    read username
fi

# Prompt for password if not set
if [[ -z "$password" ]]; then
    color_echo "QUESTION" "Please enter your password for FileMaker Admin Console (will not be echoed):"
    read -s password
fi


# Check if its possible to run a random fmsadmin command, if statuscode == 0 then success and we can proceed.
fmsadmin LIST FILES -u "$username" -p "$password" > /dev/null
exit_status=$?
if [[ $exit_status -ne 0 ]]; then
   color_echo "ERROR" "It was not possible to validate your admin account credentials, please try again."
   exit 1
fi
color_echo "SUCCESS" "Credentials verified, continuing."

# Check if the versions are compatible with devin (need to be fmserver >=19.3.1 and ubuntu >=18.04)
fmsversion=$(fmsadmin -u a -p a -v < /dev/null | grep -oP 'fmsadmin: Version \K\S+')
ubuntuversion=$(lsb_release -d | cut -d ' ' -f2)

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

if ! version_gt $fmsversion 19.5.1; then
    color_echo "ERROR" "FileMaker Server version is not compatible with Devin, needs to be >=19.5.1"
    exit 1
fi



# Check if Python is installed, if not install
if ! which python3.12 >/dev/null 2>&1; then
    color_echo "INFO" "Installing python 3.12."
    apt-get install software-properties-common -y >> $log_file 2>&1
    add-apt-repository ppa:deadsnakes/ppa -y >> $log_file 2>&1
    apt-get update >> $log_file 2>&1
    apt-get install python3.12 python3.12-venv python3.12-distutils -y >> $log_file 2>&1
fi



# install zip and unzip
if ! which unzip >/dev/null 2>&1; then
    color_echo "INFO" "Installing unzip."
    apt-get install -y unzip >> $log_file 2>&1
fi

# install zip and unzip
if ! which zip >/dev/null 2>&1; then
    color_echo "INFO" "Installing zip."
    apt-get install -y zip >> $log_file 2>&1
fi

if [[ -z "$type" ]]; then
    color_echo "QUESTION" "Please type 0 if you are installing a Devin Development Server."
    color_echo "QUESTION" "Please type 1 if you are installing a Devin Production Server."
    read answer

    # Handle the user's input
    case $answer in
        [0]* ) 
            type=dev
            ;;
        [1]* ) 
            type=prod
            ;;
        * ) 
            color_echo "ERROR" "Please answer 0 (Development) or 1 (Production) - Exiting"
            exit 1;;
    esac
fi


#Create Devin folders
color_echo "INFO" "Making the Devin directory."
mkdir -p /opt/Devin/backups >> $log_file 2>&1
mkdir -p /opt/Devin/tmp >> $log_file 2>&1
mkdir -p /opt/Devin/updates >> $log_file 2>&1
mkdir -p /opt/Devin/logs >> $log_file 2>&1
mkdir -p /opt/Devin/migrations >> $log_file 2>&1
mkdir -p /opt/Devin/commits >> $log_file 2>&1



# Check if Devin user exists
if ! id -u devin >/dev/null 2>&1; then
    color_echo "INFO" "Creating Devin user"
    useradd -u 9988 -s /bin/bash -m devin >> $log_file 2>&1 # We request devin to be a specific and high value user id, so that it is unlikely to conflict with any other user id. 
else
    color_echo "INFO" "Devin user already exists"
fi

# Check if Devin user is part of the fmsadmin group
if ! groups devin | grep -q '\bfmsadmin\b'; then
    color_echo "INFO" "Adding Devin user to the fmsadmin group"
    usermod -aG fmsadmin devin >> $log_file 2>&1
else
    color_echo "INFO" "Devin user is already part of the fmsadmin group"
fi

# Check if /opt/Devin/handler exists
if [ ! -d "/opt/Devin/handler" ]; then
    color_echo "INFO" "Pulling Devin Handler Service and unzipping."
    mkdir -p /opt/Devin/handler >> $log_file 2>&1
    curl -s -o /opt/Devin/handler/handler.zip $devin_handler_download_location >> $log_file 2>&1
    unzip /opt/Devin/handler/handler.zip -d /opt/Devin/handler/ >> $log_file 2>&1
    rm /opt/Devin/handler/handler.zip >> $log_file 2>&1
    chmod +x /opt/Devin/handler/start_handler_service.sh >> $log_file 2>&1
else
    color_echo "INFO" "/opt/Devin/handler already exists"
fi


# Check if /opt/Devin/sudo_utils folder exists
if [ ! -d "/opt/Devin/sudo_utils" ]; then
    color_echo "INFO" "Pulling utilities and unzipping."
    curl -s -o /opt/Devin/sudo_utils.zip $devin_server_utils_location >> $log_file 2>&1
    unzip /opt/Devin/sudo_utils.zip -d /opt/Devin/sudo_utils/ >> $log_file 2>&1
    rm /opt/Devin/sudo_utils.zip >> $log_file 2>&1
    chmod 755 /opt/Devin/sudo_utils/* >> $log_file 2>&1
    /opt/Devin/sudo_utils/update_sudo_utils_json.sh $username $password >> $log_file 2>&1
else
    color_echo "INFO" "/opt/Devin/sudo_utils folder already exists, updating them"
    /opt/Devin/sudo_utils/update_sudo_utils.sh >> $log_file 2>&1
    /opt/Devin/sudo_utils/update_sudo_utils_json.sh $username $password >> $log_file 2>&1
fi

# Check if sudoers file exists
if [ -f "/etc/sudoers" ]; then
    # Check if "devin" is already in sudoers file
    if grep -q "devin" "/etc/sudoers"; then
        color_echo "INFO" "Devin is already in the sudoers list."
    else
        # Setting proper sudoers permissions
        color_echo "INFO" "Setting proper sudoers permissions"
        echo -e "devin ALL=(ALL) NOPASSWD: /opt/Devin/sudo_utils/*" | sudo tee -a /etc/sudoers >> $log_file 2>&1
    fi
else
    color_echo "INFO" "Sudoers file not found. Installing sudo."
    apt-get install -y sudo >> $log_file 2>&1
    # Setting proper sudoers permissions
    color_echo "INFO" "Setting proper sudoers permissions"
    echo -e "devin ALL=(ALL) NOPASSWD: /opt/Devin/sudo_utils/*" | sudo tee -a /etc/sudoers >> $log_file 2>&1
fi


# Check if /opt/Devin/info.json exists
if [ ! -f "/opt/Devin/info.json" ]; then
    # Set info.json
    info_version=$(cat /opt/Devin/handler/version.txt)
    # Changing information in info.json
    color_echo "INFO" "Adding information to info.json"
    cat << EOF > /opt/Devin/info.json
{
    "os": {
        "type": "linux",
        "name": "$os_type",
        "version": "$os_version"
    },
    "fms": {
        "version": "$fmsversion",
        "location":"/opt/FileMaker/FileMaker Server"
    },
    "devin": {
        "handler": {
            "type": "$type",
            "version": "$info_version"
        },
        "server": {
            "version": "$info_version"
        }
    }
}
EOF
    rm /opt/Devin/handler/version.txt >> $log_file 2>&1
    rm /opt/Devin/handler/info.json >> $log_file 2>&1
else
    color_echo "INFO" "/opt/Devin/info.json already exists"
fi


# Check if /opt/Devin/venv folder exists
if [ ! -d "/opt/Devin/venv" ]; then
    # Install dependencies
    color_echo "INFO" "Installing virtual environment and dependencies."
    # Ensure pip is installed
    python3.12 -m ensurepip --upgrade >> $log_file 2>&1
    python3.12 -m venv /opt/Devin/venv >> $log_file 2>&1
    source /opt/Devin/venv/bin/activate >> $log_file 2>&1
    pip install --upgrade pip >> $log_file 2>&1
    pip install -r /opt/Devin/handler/requirements.txt >> $log_file 2>&1
    deactivate >> $log_file 2>&1
    chown -R devin:fmsadmin /opt/Devin/venv >> $log_file 2>&1
else
    color_echo "INFO" "/opt/Devin/venv folder already exists"
fi

#Install Devin developer server engine

if [[ "$type" == "dev" ]]; then
    if [ ! -f "/opt/FileMaker/FileMaker Server/Data/Databases/devin-engine.fmp12" ]; then
        # Install Devin engine
        color_echo "INFO" "Installing Devin Engine"
        curl -s -o "/opt/FileMaker/FileMaker Server/Data/Databases/devin-engine.fmp12" $devin_engine_download_location >> $log_file 2>&1
        chown fmserver:fmsadmin "/opt/FileMaker/FileMaker Server/Data/Databases/devin-engine.fmp12" >> $log_file 2>&1
        chmod 755 "/opt/FileMaker/FileMaker Server/Data/Databases/devin-engine.fmp12"  >> $log_file 2>&1
        # Open the devin engine in fms
    else 
        color_echo "INFO" "Devin Engine already exists"
    fi
    color_echo "INFO" "Validating that Devin Engine is open"
    fmsadmin -u "$username" -p "$password" LIST FILES | grep -q 'devin-engine.fmp12'
    if [[ $? -ne 0 ]]; then
        color_echo "ERROR" "The Devin Engine was not open."
        color_echo "INFO" "Attempting to open the Devin Engine."
        fmsadmin -u "$username" -p "$password" OPEN "devin-engine.fmp12" >> $log_file 2>&1
        if [[ $? -ne 0 ]]; then
            color_echo "ERROR" "It was not possible to open the Devin Engine in fmsadmin, please check the logs. - Uninstalling"
            uninstall
            exit 1
        else
            color_echo "SUCCESS" "The Devin Engine was opened succesfully."
        fi
    fi

    # find out if the data migration tool is installed
    color_echo "INFO" "Checking for FileMaker Data Migration Tool."
    dmtlocation="/opt/FileMaker/FileMaker Server/Database Server/bin/FMDataMigration"
    if [ ! -e "$dmtlocation" ]
    then
        color_echo "ERROR" "Data Migration Tool was not found in the default location."
        color_echo "INFO" "Attempting to download the right Data Migration Tool."
        curl -o $dmtlocation "https://devin.fm/downloads/migrationtools/FMDataMigration_U${ubuntuversion:0:2}_$fmsversion" >> $log_file 2>&1
        exit_status=$?
        if [[ $exit_status -ne 0 ]]; then
            color_echo "ERROR" "It was not possible to install the FileMaker Data Migration Tool for your version of FileMaker Server ($fmsversion), please install it manually and make sure it is present at '/opt/FileMaker/FileMaker Server/Database Server/bin/FMDataMigration' with proper permissions."
            uninstall
            exit 1
        fi
        chown devin:fmsadmin $dmtlocation
        chmod 755 $dmtlocation
        chmod +x $dmtlocation
    fi
    
fi



if [[ "$type" == "prod" ]]; then
    if ! jq -e '.devin.handler.api_key' /opt/Devin/info.json > /dev/null 2>&1; then
        color_echo "INFO" "Creating Production Server secret api key"
        api_key=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 15 | head -n 1)
        jq --arg api_key "$api_key" '.devin.handler += {"api_key": $api_key}' /opt/Devin/info.json > /tmp/temp.json && mv -f /tmp/temp.json /opt/Devin/info.json
    fi
fi


## Create systemctl service for the Handler service with gunicorn
color_echo "INFO" "Installing Devin Handler as a service."
# Check if devin-handler service is already installed
if systemctl list-unit-files | grep -Fqw "devin-handler"; then
    color_echo "INFO" "Devin Handler service is already installed."
else
    read -r -d '' SERVICE_CONTENT << EOM
[Unit]
Description=Devin handler service
After=network.target

[Service]
User=devin
WorkingDirectory=/opt/Devin/handler
ExecStart=/opt/Devin/handler/start_handler_service.sh
StandardOutput=append:/opt/Devin/logs/handler_out.log
StandardError=append:/opt/Devin/logs/handler_err.log
Restart=always
KillMode=process

[Install]
WantedBy=multi-user.target
EOM

    # Define service file location
    SERVICE_FILE="/etc/systemd/system/devin-handler.service"

    # Create service file and write service content to it
    echo "${SERVICE_CONTENT}" > "${SERVICE_FILE}" 

    # Set appropriate permissions for service file
    chmod 644 "${SERVICE_FILE}" >> $log_file 2>&1

    # Reload the systemd daemon to recognize the service
    systemctl daemon-reload >> $log_file 2>&1
    systemctl daemon-reexec >> $log_file 2>&1

    #Gotta make /opt/Devin/logs owned by devin otherwise we start with an error
    chown -R devin:fmsadmin /opt/Devin/logs >> $log_file 2>&1

    # Enable the service to start on boot
    systemctl enable devin-handler >> $log_file 2>&1

    # Start it
    systemctl start devin-handler >> $log_file 2>&1
fi


attempt=1
while [[ $attempt -le 5 ]]; do
    color_echo "INFO" "Checking if the Devin Handler Service is running (Attempt $attempt)."
    response_body=$(curl -s http://localhost:45712/devin/api/v1/$type/ping)
    if echo "$response_body" | grep -q "pong"; then
        color_echo "SUCCESS" "Handler Service is running successfully."
        break
    else
        if [[ $attempt -eq 5 ]]; then
            color_echo "ERROR" "Handler service did not start correctly after multiple attempts! Removing Devin and cleaning up."
            uninstall
        else
            color_echo "INFO" "Handler service not running. Retrying in 5 seconds..."
            sleep 5
        fi
    fi
    ((attempt++))
done

# Check if prod
if [[ "$type" == "prod" ]]; then
    # Put the handler behind nginx
    if [ ! -f "/opt/FileMaker/FileMaker Server/NginxServer/conf/devin.conf" ]; then
            color_echo "INFO" "Putting the Devin APIs behind nginx."
            cat > /opt/FileMaker/FileMaker\ Server/NginxServer/conf/devin.conf << EOF
location ^~ /devin/ {
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-Host \$host:\$server_port;
    proxy_set_header X-Forwarded-Server \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:45712;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
}
EOF
    fi
    chmod 755 /opt/FileMaker/FileMaker\ Server/NginxServer/conf/devin.conf >> $log_file 2>&1
    chown fmserver:fmsadmin /opt/FileMaker/FileMaker\ Server/NginxServer/conf/devin.conf >> $log_file 2>&1

    # Check if devin entry already exists in the config file
    if ! grep -q "devin.conf" /opt/FileMaker/FileMaker\ Server/NginxServer/conf/fms_nginx.conf; then
        # Add it to main nginx config
        sed -i '/include "\/opt\/FileMaker\/FileMaker Server\/NginxServer\/conf\/fms_fac.conf";/a \
            ## devin nginx configuration\n    include "/opt/FileMaker/FileMaker Server/NginxServer/conf/devin.conf";' /opt/FileMaker/FileMaker\ Server/NginxServer/conf/fms_nginx.conf >> $log_file 2>&1
    fi

    fmsadmin restart httpserver -u "$username" -p "$password"  -f -y>>  $log_file 2>&1

    response_body=$(curl -k https://localhost/devin/api/v1/prod/ping 2>/dev/null)
    if echo "$response_body" | grep -q "pong"; then
        color_echo "SUCCESS" "The Devin Handler Service were reachable through nginx with SSL."
    else
        color_echo "ERROR" "It was not possible to reach the Devin handler through nginx, attempting to restart the HTTP server."
        fmsadmin stop httpserver -u "$username" -p "$password" -y 
        sleep 2
        fmsadmin start httpserver -u "$username" -p "$password" -y 
        sleep 2
        # Retry after restart
        response_body=$(curl -k https://localhost/devin/api/v1/prod/ping 2>/dev/null)
        if echo "$response_body" | grep -q "pong"; then
            color_echo "SUCCESS" "The Devin handler was reachable through nginx after restart."
        else
            color_echo "ERROR" "It was still not possible to reach the Devin handler through nginx after restarting, please check that you have logged in to the admin console at least once, and chosen a certificate."
            uninstall
        fi
    fi
fi

# Enabling the fms data api if we are on dev
if [[ "$type" == "dev" ]]; then
    color_echo "INFO" "Enabling the Filemaker Data API."
    fmsadmin enable FMDAPI -u "$username" -p "$password" >> $log_file 2>&1
    fmsadmin start FMDAPI -u "$username" -p "$password" >> $log_file 2>&1
fi



#Getting Ip address of me
myip=$(curl -sS ifconfig.me) >> $log_file 2>&1

#Check if prod, that the handler is available from the internet
if [[ "$type" == "prod" ]]; then
    color_echo "INFO" "Checking if the Devin Production Server APIs can be reached from the internet. ($myip on port 443)"
    res=$(curl -sS -X 'POST' 'https://portchecker.io/api/v1/query' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"host": "'$myip'","ports": ["443"]}')  >> $log_file 2>&1
    status=$(echo $res | jq -r '.check[0].status')

    if [[ "$status" != "true" ]]; then
        color_echo "ERROR" "It was not possible to ensure that port 443 is reachable from the internet. If you need Devin to reach the production server over the internet, then this is a problem that you will need to investigate."
    else
        color_echo "SUCCESS" "It was possible to reach the Devin Production Server APIs from the internet."
    fi
fi

#Check if dev, that the engine is available from the internet
if [[ "$type" == "dev" ]]; then
    color_echo "INFO" "Checking if the Devin Engine can be reached from the internet. ($myip on port 5003)"
    res=$(curl -sS -X 'POST' 'https://portchecker.io/api/v1/query' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"host": "'$myip'","ports": [5003]}')  >> $log_file 2>&1
    status=$(echo $res | jq -r '.check[0].status')

    if [[ "$status" != "true" ]]; then
        color_echo "ERROR" "It was not possible to ensure that port 5003 is reachable from the internet. If you need Devin to be accessible over internet, then you will need to investigate this."
    else
        color_echo "SUCCESS" "It was possible to reach the Devin Engine from the internet."
    fi
fi


#Check if dev, then enable script schedule in fmi admin api
if [[ "$type" == "dev" ]]; then
    success=false
    color_echo "INFO" "Enabling the Filemaker Script Schedule."
    # Make the request and extract the token in one line
    token=$(curl -s -k -X POST "https://localhost/fmi/admin/api/v2/user/auth" -H "Content-Type: application/json" -H "Authorization: Basic $(echo -n "$username:$password" | base64)" | jq -r '.response.token')

    # Check and print the token
    if [ "$token" != "null" ] || [ -z "$token" ]; then
        # Check if the schedule somehow is there:
        existingSchedules=$(curl -s -k -X GET "https://localhost/fmi/admin/api/v2/schedules" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token")
        scheduleId=$(echo "$existingSchedules" | jq -r '.response.schedules[] | select(.filemakerScriptType.fmScriptAccount == "DevinEngineScheduleRunner").id')
        if [ -n "$scheduleId" ]; then
            color_echo "INFO" "The script schedule already exists, removing it."
            curl -s -k -X DELETE "https://localhost/fmi/admin/api/v2/schedules/$scheduleId" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" >> $log_file 2>&1
        fi

        jsonPayload='{
        "name": "Devin Engine Assistant",
        "filemakerScriptType": {
            "resource": "devin-engine.fmp12",
            "fmScriptName": "DevinEngine1MinRefresh",
            "fmScriptPassword": "12345678",
            "timeout": 1,
            "autoAbort": true,
            "fmScriptAccount": "DevinEngineScheduleRunner"
        },
        "enabled": true,
        "everyndaysType": {
            "dailyDays": 1,
            "repeatTask": {
            "endTime": "23:59:00",
            "repeatFrequency": 1,
            "repeatInterval": "MINUTES"
            },
            "startTimeStamp": "2022-01-01T00:00:00"
        }
        }'

        # Send the POST request and save the output to a variable
        response=$(curl -s -k -X POST "https://localhost/fmi/admin/api/v2/schedules/filemakerscript" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "$jsonPayload")
        echo $response >> $log_file 2>&1
        messageCode=$(echo "$response" | jq -r '.messages[0].code')
        # Check if the message code is not "0"
        if [ "$messageCode" != "0" ]; then
            color_echo "ERROR" "Something went wrong when starting the script schedule. Code: $messageCode"
        else
            color_echo "SUCCESS" "Successfully authenticated to the admin api and created the script schedule"
            success=true
        fi
    else
        color_echo "ERROR" "Failed to authenticate to the admin api and start the script schedule, reverting installation"
    fi
    curl -s -k -X DELETE "https://localhost/fmi/admin/api/v2/user/auth/$token" >> $log_file 2>&1
    if [[ "$success" == "false" ]]; then
        uninstall
    fi
fi


color_echo "INFO" "Setting permissions on Devin folder."
find /opt/Devin \( -type d -or -type f \) -not -path "/opt/Devin/sudo_utils" -not -path "/opt/Devin/sudo_utils/*" -exec chown devin:fmsadmin {} \; >> $log_file 2>&1
find /opt/Devin \( -type d -or -type f \) -not -path "/opt/Devin/sudo_utils" -not -path "/opt/Devin/sudo_utils/*" -exec chmod 755 {} \; >> $log_file 2>&1

#Echo prod api key
if [[ "$type" == "prod" ]]; then
color_echo "SUCCESS" "####################################################################################"
color_echo "SUCCESS" "###       Your api key for this Production Server is:     $api_key       ####"
color_echo "SUCCESS" "####################################################################################"
color_echo "SUCCESS" "Please save the key, as you will need it when adding this server to your Devin App."
color_echo "SUCCESS" "If you forget it, you can find it in /opt/Devin/info.json"
fi

echo
color_echo "SUCCESS" "Devin has been installed and should be running :-)"

#Move log file to log folder
mv $log_file /opt/Devin/logs    