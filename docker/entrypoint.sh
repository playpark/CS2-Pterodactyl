#!/bin/bash
cd /home/container
sleep 1
# Make internal Docker IP address available to processes.
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`

# Update Source Server
if [ ! -z ${SRCDS_APPID} ]; then
    if [ ${SRCDS_STOP_UPDATE} -eq 0 ]; then
        STEAMCMD=""
        echo "Starting SteamCMD for AppID: ${SRCDS_APPID}"
        if [ ! -z ${SRCDS_BETAID} ]; then
            if [ ! -z ${SRCDS_BETAPASS} ]; then
                if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                    echo "SteamCMD Validate Flag Enabled! Triggered install validation for AppID: ${SRCDS_APPID}"
                    echo "THIS MAY WIPE CUSTOM CONFIGURATIONS! Please stop the server if this was not intended."
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
                echo "SteamCMD Validate Flag Enabled! Triggered install validation for AppID: ${SRCDS_APPID}"
                echo "THIS MAY WIPE CUSTOM CONFIGURATIONS! Please stop the server if this was not intended."
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

        # echo "SteamCMD Launch: ${STEAMCMD}"
        eval ${STEAMCMD}

        # Issue #44 - We can't symlink this, causes "File not found" errors. As a mitigation, copy over the updated binary on start.
        cp -f ./steamcmd/linux32/steamclient.so ./.steam/sdk32/steamclient.so
        cp -f ./steamcmd/linux64/steamclient.so ./.steam/sdk64/steamclient.so
    fi
fi

temp_folder="/home/container/temp"
metamod_version_file="/home/container/game/METAMOD_VERSION.txt"

update_metamod() {
    echo "Checking for MetaMod updates"
    # Check if MetaMod is up to date
    latest_version_url=$(curl -sSL "https://www.metamodsource.net/downloads.php/?branch=master" | pup '.quick-download' | pup 'a attr{href}' | grep 'linux')
    if [ $? -ne 0 ]; then
        echo "Failed to download MetaMod. Please check your internet connection"
        return
    fi

    latest_version=$(echo "$latest_version_url" | grep -oP '2\.0/mmsource-\K[^-]+(-[^-]+)?(?=-linux)')
    if [ -z "$latest_version" ]; then
        echo "Failed to extract version number from URL"
        return
    fi

    echo "Latest MetaMod version: $latest_version"

    if [ -f ${metamod_version_file} ]; then
            current_version=$(cat ${metamod_version_file})
        else
            current_version="0.0.0"
        fi
    
    echo "Current MetaMod version: $current_version"

    # Compare version
    if [ "${latest_version}" != "${current_version}" ]; then
        echo "MetaMod update available. Updating..."
        # Download latest release
        echo "Starting MetaMod update..."
        mkdir -p ${temp_folder}
        cd ${temp_folder}
        # Extract files
        echo "Downloading MetaMod ${latest_version}"
        curl -sSLO ${latest_version_url}
        echo "Extracting MetaMod ${latest_version}"
        # Extract files
        tar -xzf mmsource*.tar.gz -C /home/container/game/csgo/
        echo "Cleaning up..."
        rm -rf ${temp_folder}
        echo "Metamod installed successfully"
        echo ${latest_version} > ${metamod_version_file}
        echo "MetaMod updated to ${latest_version}"
        cd /home/container
    fi
}

update_metamod

# Edit /home/container/game/csgo/gameinfo.gi to add MetaMod path
# Credit: https://github.com/ghostcap-gaming/ACMRS-cs2-metamod-update-fix/blob/main/acmrs.sh
GAMEINFO_FILE="/home/container/game/csgo/gameinfo.gi"
GAMEINFO_ENTRY="			Game	csgo/addons/metamod" 
if [ -f "${GAMEINFO_FILE}" ]; then
    if grep -q "Game[[:blank:]]*csgo\/addons\/metamod" "$GAMEINFO_FILE"; then # match any whitespace
        echo "File gameinfo.gi already configured. No changes were made."
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

        echo "The file ${GAMEINFO_FILE} has been configured for MetaMod successfully."
    fi
fi


version_file="/home/container/game/CSS_VERSION.txt"
dotnet_folder="/home/container/game/csgo/addons/counterstrikesharp/dotnet"
temp_folder="/home/container/temp"

update_css() {
    if [ ${CSS_UPDATE} -eq 1 ]; then
        echo "Checking for CounterStrikeSharp updates..."
        
        # Get latest release version from GitHub with proper User-Agent
        latest_version=$(curl -sSL -H "User-Agent: CSS-Update-Script" \
            "https://api.github.com/repos/roflmuffin/CounterStrikeSharp/releases/latest")
        
        # Check if curl command was successful and returned valid JSON
        if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
            echo "Error: Failed to fetch latest version from GitHub API. Please check your internet connection."
            return 1
        fi

        # Extract version tag
        version_tag=$(echo "$latest_version" | jq -r '.tag_name')
        if [ "$version_tag" = "null" ] || [ -z "$version_tag" ]; then
            echo "Error: Failed to extract version tag from GitHub response."
            return 1
        fi
        
        echo "Latest available version: $version_tag"

        # Get current version from file
        if [ -f ${version_file} ]; then
            current_version=$(cat ${version_file})
            echo "Current installed version: $current_version"
        else
            current_version="0.0.0"
            echo "No current version found, assuming fresh installation"
        fi

        # Check if version is different
        if [ "${version_tag}" != "${current_version}" ]; then
            echo "Update required: ${current_version} -> ${version_tag}"
            
            # Create temp directory
            mkdir -p ${temp_folder}
            cd ${temp_folder} || { echo "Failed to create/access temp directory"; return 1; }
            
            # Determine appropriate download URL based on runtime presence
            if [ -d "${dotnet_folder}" ]; then
                echo "Existing .NET runtime detected, downloading core package..."
                download_url=$(echo "$latest_version" | jq -r '.assets[] | select((.name | test("linux")) and (.name | test("runtime") | not)) | .browser_download_url' | head -n 1)
            else
                echo "No .NET runtime detected, downloading package with runtime..."
                download_url=$(echo "$latest_version" | jq -r '.assets[] | select((.name | test("with-runtime")) and (.name | test("linux"))) | .browser_download_url' | head -n 1)
            fi

            # Validate download URL
            if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
                echo "Error: Failed to determine download URL"
                cd /home/container
                rm -rf ${temp_folder}
                return 1
            fi

            echo "Downloading from: $download_url"
            
            # Download the package
            if curl -sSLO "$download_url"; then
                echo "Download completed successfully"
                
                # Extract files with error checking
                if unzip -o counterstrikesharp-* -d /home/container/game/csgo/; then
                    echo "Successfully extracted CounterStrikeSharp files"
                    echo "${version_tag}" > ${version_file}
                    echo "Updated version file to ${version_tag}"
                else
                    echo "Error: Failed to extract files"
                    cd /home/container
                    rm -rf ${temp_folder}
                    return 1
                fi
                
                # Cleanup
                cd /home/container
                rm -rf ${temp_folder}
                echo "CounterStrikeSharp successfully updated to ${version_tag}"
                return 0
            else
                echo "Error: Failed to download package"
                cd /home/container
                rm -rf ${temp_folder}
                return 1
            fi
        else
            echo "CounterStrikeSharp is already up to date (version ${current_version})"
            return 0
        fi
    else
        echo "CSS_UPDATE is not enabled, skipping update check"
        return 0
    fi
}

# Run the update function
update_css

# Replace Startup Variables
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
