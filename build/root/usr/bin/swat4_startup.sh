#!/command/with-contenv bash
## File: SWAT 4 Docker Script - swat4_startup.sh
## Author: Kevin Moore <admin@sbotnas.io>
## Created: 2023/07/11
## Modified: 2024/05/13
## License: MIT License
exec 2>&1
source /usr/bin/debug.sh

GAME_DIR=/container/swat4
NEW_SWAT4_ENGINEDLL=$(md5sum < /tmp/SWAT4/Engine.dll)
NEW_TSS_ENGINEDLL=$(md5sum < /tmp/TSS/Engine.dll)
OLD_SWAT4_ENGINEDLL=$(md5sum < "$GAME_DIR/Content/System/Engine.dll")
OLD_TSS_ENGINEDLL=$(md5sum < "$GAME_DIR/ContentExpansion/System/Engine.dll")

case "${CONTENT_VERSION}" in
	"SWAT4"|0)
    	CONTENT_PATH=Content
        CONTENT_VERSION="SWAT 4"
    	SERVER_BINARY=Swat4DedicatedServer
		;;
    	"TSS"|1)
	    CONTENT_PATH=ContentExpansion
        CONTENT_VERSION="SWAT 4: The Stetchkov Syndicate"
    	SERVER_BINARY=Swat4XDedicatedServer
		;;

	"$CONTENT_VERSION")
	CONTENT_PATH=$CONTENT_VERSION
    echo "Content Path is: $CONTENT_PATH"
	MOD_SYSTEM_FOLDER=$(find "$GAME_DIR/$CONTENT_PATH" -type d -name System) 2> /dev/null || { echo "Cannot find Mod folder $GAME_DIR/$CONTENT_PATH! Check that it exists, and that CONTENT_VERSION is set correctly!"; exit 1; }
	MOD_GAME_VERSION=$(find "$MOD_SYSTEM_FOLDER" -iregex '.*Swat4X?.ini' -type f -printf "%f")
	
	case $MOD_GAME_VERSION in	
			"Swat4.ini")
			CONTENT_PATH_MOD=Content/System/
			SERVER_BINARY=Swat4DedicatedServer
			;;
		
			"Swat4X.ini")
			CONTENT_PATH_MOD=ContentExpansion/System/
			SERVER_BINARY=Swat4XDedicatedServer
			;;
	
			"")
			echo "Cannot determine SWAT4 Protocol version! Check that Swat4.ini exists in $GAME_DIR/$CONTENT_VERSION/System!"
			exit 1;
			;;
	esac
		;;
esac

echo "Content Path is: $CONTENT_PATH"
echo "Content Version is: $CONTENT_VERSION"

SwatGUIState=$(find "$GAME_DIR/$CONTENT_PATH/System" -type f -iname SwatGUIState.ini -printf "%f" -quit | grep .) && SwatGUIState="$GAME_DIR/$CONTENT_PATH/System/$SwatGUIState" || { echo "Cannot find $GAME_DIR/$CONTENT_VERSION/System/SwatGUIState.ini"; exit 1; }

case "${GAME_TYPE^^}" in
    "BARRICADED SUSPECTS")
	    GAME_TYPE=MPM_BarricadedSuspects
        sed -i "s/^GameType=.*$/GameType=$GAME_TYPE/g" "$SwatGUIState"
        ;;
    "CO-OP"|2)
	    GAME_TYPE=MPM_COOP
        sed -i "s/^GameType=.*$/GameType=$GAME_TYPE/g" "$SwatGUIState"
        ;;
    "RAPID DEPLOYMENT"|3)
	    GAME_TYPE=MPM_RapidDeployment
        sed -i "s/^GameType=.*$/GameType=$GAME_TYPE/g" "$SwatGUIState"
        ;;
    "SMASH AND GRAB"|4)
	    GAME_TYPE=MPM_SmashAndGrab
        sed -i "s/^GameType=.*$/GameType=$GAME_TYPE/g" "$SwatGUIState"
        ;;
    "VIP ESCORT"|5)
	    GAME_TYPE=MPM_VIPEscort
        sed -i "s/^GameType=.*$/GameType=$GAME_TYPE/g" "$SwatGUIState"
        ;;
    *)
        echo "Could not find GameType: $GAME_TYPE, defaulting to CO-OP"
        GAME_TYPE=MPM_COOP
        sed -i "s/^GameType=.*$/GameType=$GAME_TYPE/g" "$SwatGUIState"
        ;;
esac

sed -i -e "s/^AdminPassword=.*$/AdminPassword=$ADMIN_PASSWORD/g;
	s/^ServerName=.*$/ServerName=${SERVER_NAME:-A SWAT 4 Docker Server}/g;
	s/^MaxPlayers=.*$/MaxPlayers=${MAX_PLAYERS:-10}/g;
	s/^Password=.*$/Password=$SERVER_PASSWORD/g;
	s/^bLAN=.*$/bLAN=${LAN_ONLY:-False}/g;
    s/^bUseStatTracking=.*$/bUseStatTracking=False/g;
	s/^NumRounds=.*$/NumRounds=${NUM_ROUNDS:-15}/g;
	s/^DeathLimit=.*$/DeathLimit=${DEATH_LIMIT:-50}/g;
	s/^RoundTimeLimit=.*$/RoundTimeLimit=${ROUND_TIME_LIMIT:-900}/g;
	s/^PostGameTimeLimit=.*$/PostGameTimeLimit=${POST_GAME_TIME_LIMIT:-15}/g;
    s/^bQuickRoundReset.*$/bQuickRoundReset=${QUICK_ROUND_RESET:-False}/g;
	s/^MPMissionReadyTime=.*$/MPMissionReadyTime=${MP_MISSION_READY_TIME:-15}/g" "$SwatGUIState"

if [ -n "$SERVER_PASSWORD" ]; then
        sed -i 's/^bPassworded=.*$/bPassworded=True/g' "$SwatGUIState"
else
        sed -i 's/^bPassworded=.*$/bPassworded=False/g' "$SwatGUIState"
fi

extract_mod_name() {
    local section=$1
    # Try to extract ModName within the specified section
    local mod_name=$(sed -n "/\[$section\]/,/\[.*\]/{
        /ModName=/{
            s/.*ModName=//;  # Remove everything before ModName=
            s/\"//g;         # Remove quotes
            s/\r//g;         # Remove carriage return characters
            p;               # Print the result for further processing
            q;               # Quit after the first match
        }
    }" "$MOD_SYSTEM_FOLDER/Version.ini" | sed 's/\[\(b\|\/b\)\]//g' | sed 's/\[\\b\]//g')
    echo "$mod_name"
}

if [[ -n "$MOD_SYSTEM_FOLDER" ]]; then
    # Try extracting from [SwatGui.ModInfo] first
    MOD_NAME=$(extract_mod_name "SwatGui.ModInfo")

    # If not found, fallback to the [Version] section
    if [[ -z "$MOD_NAME" ]]; then
        MOD_NAME=$(extract_mod_name "Version")
    fi

    # If mod name was found, set our $CONTENT_VERSION. Otherwise we fall back to $CONTENT_VERSION defined by user
    if [[ -n "$MOD_NAME" ]]; then
        CONTENT_VERSION="$MOD_NAME"
    fi
fi

SERVER_MAPLIST=${SERVER_MAPLIST:-$SERVER_MAP}

# Read maplist into array
IFS=',' read -ra MAPLIST <<< "$SERVER_MAPLIST"

if [ -n "$SERVER_MAP" ]; then
    MAPLIST=("$SERVER_MAP" "${MAPLIST[@]}")
    echo "\$SERVER_MAP has been deprecated and will be removed in a future release, please use \$SERVER_MAPLIST"
fi

# Generate the new Maps[i] and NumMaps entries
NEW_MAPS_CONTENT=""
for i in "${!MAPLIST[@]}"; do
    NEW_MAPS_CONTENT+="Maps[$i]=${MAPLIST[$i]}\n"
done
NEW_MAPS_CONTENT+="NumMaps=${#MAPLIST[@]}"

# Update SwatGame.ServerSettings section
sed -i "/^\[SwatGame.ServerSettings\]/,/^\[/ {
    /^Maps\[[0-9]*\]=/d;                    # Delete current Maps entries
    /^NumMaps=/d;                           # Delete current NumMaps entry
    /\[SwatGame.ServerSettings\]/a $NEW_MAPS_CONTENT
}" "$SwatGUIState"

# Update the GAME_TYPE section
sed -i "/^\[$GAME_TYPE\]/,/^\[/ {
    /^Maps\[[0-9]*\]=/d;                    # Delete current Maps entries
    /^NumMaps=/d;                           # Delete current NumMaps entry
    /\[$GAME_TYPE\]/a $NEW_MAPS_CONTENT
}" "$SwatGUIState"

# Check if GAME_TYPE section exists
if grep -q "^\[$GAME_TYPE\]" "$SwatGUIState"; then
    # Update existing GAME_TYPE section
    sed -i "/^\[$GAME_TYPE\]/,/^\[/ {
        /^Maps\[[0-9]*\]=/d;                # Delete current Maps entries
        /^NumMaps=/d;                       # Delete current NumMaps entry
        /\[$GAME_TYPE\]/a $NEW_MAPS_CONTENT
    }" "$SwatGUIState"
else
    # Append GAME_TYPE section if it doesn't exist
    echo -e "\n[$GAME_TYPE]\n$NEW_MAPS_CONTENT" >> "$SwatGUIState"
fi

# Parse ADDITIONAL_ARGS
IFS=',' read -ra ARGS <<< "$ADDITIONAL_ARGS"

for arg in "${ARGS[@]}"; do
    IFS='=' read -ra KV <<< "$arg"
    key="${KV[0]}"
    value="${KV[1]}"

    sed -i "s/^$key=.*$/$key=$value/" "$SwatGUIState"
done

# Check to make sure we're using the patched server browser DLL's
if [ ! "$NEW_SWAT4_ENGINEDLL" = "$OLD_SWAT4_ENGINEDLL" ]; then
	mv "$GAME_DIR/Content/System/Engine.dll" "$GAME_DIR/Content/System/Engine.dll.bak"
	cp /tmp/SWAT4/Engine.dll "$GAME_DIR/Content/System/Engine.dll"
fi

if [ ! "$NEW_TSS_ENGINEDLL" = "$OLD_TSS_ENGINEDLL" ]; then
       	mv "$GAME_DIR/ContentExpansion/System/Engine.dll" "$GAME_DIR/ContentExpansion/System/Engine.dll.bak"
        cp /tmp/TSS/Engine.dll "$GAME_DIR/ContentExpansion/System/Engine.dll"
fi

cd "$GAME_DIR/$CONTENT_PATH/System/" || { echo "Could not change directory to $GAME_DIR/$CONTENT_PATH/System"; exit 1; }

if [ -f "$SERVER_BINARY.log" ]; then 
	mv "$SERVER_BINARY.log" "$SERVER_BINARY.old.log"
fi

echo "Starting $CONTENT_VERSION Server, it may take up to 30 seconds before you see any logs"

xvfb-run wine "$GAME_DIR/${CONTENT_PATH_MOD:-$CONTENT_PATH/System/}$SERVER_BINARY.exe" "${MAPLIST[0]}" & tail -F "$SERVER_BINARY.log" 2> /dev/null
