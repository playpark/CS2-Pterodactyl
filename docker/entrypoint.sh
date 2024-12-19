#!/bin/bash

# Color definitions
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_PURPLE='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE='\033[1;37m'
COLOR_RESET='\033[0m'

# Prefix for all messages
PREFIX="${COLOR_CYAN}[Updater]${COLOR_RESET}"

# Helper function for consistent echo formatting
print_message() {
    echo -e "${PREFIX} $1"
}

cd /home/container
sleep 1
# Make internal Docker IP address available to processes.
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`

# Update Source Server
if [ ! -z ${SRCDS_APPID} ]; then
    if [ ${SRCDS_STOP_UPDATE} -eq 0 ]; then
        STEAMCMD=""
        print_message "${COLOR_BLUE}Starting SteamCMD for AppID: ${COLOR_WHITE}${SRCDS_APPID}${COLOR_RESET}"
        if [ ! -z ${SRCDS_BETAID} ]; then
            if [ ! -z ${SRCDS_BETAPASS} ]; then
                if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                    print_message "${COLOR_YELLOW}SteamCMD Validate Flag Enabled! Triggered install validation for AppID: ${COLOR_WHITE}${SRCDS_APPID}${COLOR_RESET}"
                    print_message "${COLOR_RED}THIS MAY WIPE CUSTOM CONFIGURATIONS! Please stop the server if this was not intended.${COLOR_RESET}"
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} validate +quit"
                    else
                        STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} validate +quit"
                    fi
                else
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                    else
                        STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                    fi
                fi
            else
                if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} validate +quit"
                    else
                        STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} validate +quit"
                    fi
                else
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                    else
                        STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                    fi
                fi
            fi
        else
            if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                print_message "${COLOR_YELLOW}SteamCMD Validate Flag Enabled! Triggered install validation for AppID: ${COLOR_WHITE}${SRCDS_APPID}${COLOR_RESET}"
                print_message "${COLOR_RED}THIS MAY WIPE CUSTOM CONFIGURATIONS! Please stop the server if this was not intended.${COLOR_RESET}"
                if [ ! -z ${SRCDS_LOGIN} ]; then
                    STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} validate +quit"
                else
                    STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} validate +quit"
                fi
            else
                if [ ! -z ${SRCDS_LOGIN} ]; then
                    STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} +quit"
                else
                    STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} +quit"
                fi
            fi
        fi

        eval ${STEAMCMD}

        cp -f ./steamcmd/linux32/steamclient.so ./.steam/sdk32/steamclient.so
        cp -f ./steamcmd/linux64/steamclient.so ./.steam/sdk64/steamclient.so
    fi
fi

temp_folder="/home/container/temp"
metamod_version_file="/home/container/game/METAMOD_VERSION.txt"

update_metamod() {
    print_message "${COLOR_BLUE}Checking for MetaMod updates${COLOR_RESET}"
    latest_version_url=$(curl -sSL "https://www.metamodsource.net/downloads.php/?branch=master" | pup '.quick-download' | pup 'a attr{href}' | grep 'linux')
    if [ $? -ne 0 ]; then
        print_message "${COLOR_RED}Failed to download MetaMod. Please check your internet connection${COLOR_RESET}"
        return
    fi

    latest_version=$(echo "$latest_version_url" | grep -oP '2\.0/mmsource-\K[^-]+(-[^-]+)?(?=-linux)')
    if [ -z "$latest_version" ]; then
        print_message "${COLOR_RED}Failed to extract version number from URL${COLOR_RESET}"
        return
    fi

    print_message "${COLOR_GREEN}Latest MetaMod version: ${COLOR_WHITE}$latest_version${COLOR_RESET}"

    if [ -f ${metamod_version_file} ]; then
        current_version=$(cat ${metamod_version_file})
    else
        current_version="0.0.0"
    fi
    
    print_message "${COLOR_BLUE}Current MetaMod version: ${COLOR_WHITE}$current_version${COLOR_RESET}"

    if [ "${latest_version}" != "${current_version}" ]; then
        print_message "${COLOR_YELLOW}MetaMod update available. Updating...${COLOR_RESET}"
        mkdir -p ${temp_folder}
        cd ${temp_folder}
        print_message "${COLOR_BLUE}Downloading MetaMod ${COLOR_WHITE}${latest_version}${COLOR_RESET}"
        curl -sSLO ${latest_version_url}
        print_message "${COLOR_BLUE}Extracting MetaMod ${COLOR_WHITE}${latest_version}${COLOR_RESET}"
        tar -xzf mmsource*.tar.gz -C /home/container/game/csgo/
        print_message "${COLOR_BLUE}Cleaning up...${COLOR_RESET}"
        rm -rf ${temp_folder}
        print_message "${COLOR_GREEN}Metamod installed successfully${COLOR_RESET}"
        echo ${latest_version} > ${metamod_version_file}
        print_message "${COLOR_GREEN}MetaMod updated to ${COLOR_WHITE}${latest_version}${COLOR_RESET}"
        cd /home/container
    fi
}

update_metamod

# Edit /home/container/game/csgo/gameinfo.gi to add MetaMod path
GAMEINFO_FILE="/home/container/game/csgo/gameinfo.gi"
GAMEINFO_ENTRY="			Game	csgo/addons/metamod" 
if [ -f "${GAMEINFO_FILE}" ]; then
    if grep -q "Game[[:blank:]]*csgo\/addons\/metamod" "$GAMEINFO_FILE"; then
        print_message "${COLOR_GREEN}File gameinfo.gi already configured. No changes were made.${COLOR_RESET}"
    else
        awk -v new_entry="$GAMEINFO_ENTRY" '
            BEGIN { found=0; }
            // {
                if (found) {
                    print new_entry;
                    found=0;
                }
                print;
            }
            /Game_LowViolence/ { found=1; }
        ' "$GAMEINFO_FILE" > "$GAMEINFO_FILE.tmp" && mv "$GAMEINFO_FILE.tmp" "$GAMEINFO_FILE"

        print_message "${COLOR_GREEN}The file ${GAMEINFO_FILE} has been configured for MetaMod successfully.${COLOR_RESET}"
    fi
fi

version_file="/home/container/game/CSS_VERSION.txt"
dotnet_folder="/home/container/game/csgo/addons/counterstrikesharp/dotnet"
temp_folder="/home/container/temp"

update_css() {
    if [ ${CSS_UPDATE} -eq 1 ]; then
        print_message "${COLOR_BLUE}Checking for CounterStrikeSharp updates...${COLOR_RESET}"
        
        latest_version=$(curl -sSL -H "User-Agent: CSS-Update-Script" \
            "https://api.github.com/repos/roflmuffin/CounterStrikeSharp/releases/latest")
        
        if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
            print_message "${COLOR_RED}Error: Failed to fetch latest version from GitHub API. Please check your internet connection.${COLOR_RESET}"
            return 1
        fi

        version_tag=$(echo "$latest_version" | jq -r '.tag_name')
        print_message "${COLOR_GREEN}Latest available version: ${COLOR_WHITE}$version_tag${COLOR_RESET}"
        
        if [ "$version_tag" = "null" ] || [ -z "$version_tag" ]; then
            print_message "${COLOR_RED}Error: Failed to extract version tag from GitHub response.${COLOR_RESET}"
            return 1
        fi
        
        if [ -f ${version_file} ]; then
            current_version=$(cat ${version_file})
            print_message "${COLOR_BLUE}Current installed version: ${COLOR_WHITE}$current_version${COLOR_RESET}"
        else
            current_version="0.0.0"
            print_message "${COLOR_YELLOW}No current version found, assuming fresh installation${COLOR_RESET}"
        fi

        if [ "${version_tag}" != "${current_version}" ]; then
            print_message "${COLOR_YELLOW}Update required: ${current_version} -> ${version_tag}${COLOR_RESET}"
            
            mkdir -p ${temp_folder}
            cd ${temp_folder} || { 
                print_message "${COLOR_RED}Failed to create/access temp directory${COLOR_RESET}"
                return 1
            }
            
            linux_pattern="counterstrikesharp-build-.*-linux"
            linux_runtime_pattern="counterstrikesharp-with-runtime.*-linux"
            
            if [ -d "${dotnet_folder}" ]; then
                print_message "${COLOR_BLUE}Existing .NET runtime detected, downloading core package...${COLOR_RESET}"
                download_url=$(echo "$latest_version" | jq -r --arg pattern "$linux_pattern" '.assets[] | select(.name | test($pattern)) | .browser_download_url' | head -n 1)
            else
                print_message "${COLOR_BLUE}No .NET runtime detected, downloading package with runtime...${COLOR_RESET}"
                download_url=$(echo "$latest_version" | jq -r --arg pattern "$linux_runtime_pattern" '.assets[] | select(.name | test($pattern)) | .browser_download_url' | head -n 1)
            fi

            if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
                print_message "${COLOR_RED}Error: Failed to determine download URL${COLOR_RESET}"
                cd /home/container
                rm -rf ${temp_folder}
                return 1
            fi

            print_message "${COLOR_BLUE}Downloading from: ${COLOR_WHITE}$download_url${COLOR_RESET}"
            
            if curl -sSLO "$download_url"; then
                print_message "${COLOR_GREEN}Download completed successfully${COLOR_RESET}"
                
                if unzip -o counterstrikesharp-* -d /home/container/game/csgo/; then
                    print_message "${COLOR_GREEN}Successfully extracted CounterStrikeSharp files${COLOR_RESET}"
                    echo "${version_tag}" > ${version_file}
                    print_message "${COLOR_GREEN}Updated version file to ${COLOR_WHITE}${version_tag}${COLOR_RESET}"
                else
                    print_message "${COLOR_RED}Error: Failed to extract files${COLOR_RESET}"
                    cd /home/container
                    rm -rf ${temp_folder}
                    return 1
                fi
                
                cd /home/container
                rm -rf ${temp_folder}
                print_message "${COLOR_GREEN}CounterStrikeSharp successfully updated to ${COLOR_WHITE}${version_tag}${COLOR_RESET}"
                return 0
            else
                print_message "${COLOR_RED}Error: Failed to download package${COLOR_RESET}"
                cd /home/container
                rm -rf ${temp_folder}
                return 1
            fi
        else
            print_message "${COLOR_GREEN}CounterStrikeSharp is already up to date (version ${COLOR_WHITE}${current_version}${COLOR_GREEN})${COLOR_RESET}"
            return 0
        fi
    else
        print_message "${COLOR_YELLOW}CSS_UPDATE is not enabled, skipping update check${COLOR_RESET}"
        return 0
    fi
}

update_css

# Replace Startup Variables
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
