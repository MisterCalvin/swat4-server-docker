#!/bin/bash
## File: Wine Wrapper - wine_wrapper.sh
## Author: Kevin Moore <admin@sbotnas.io>
## Created: 2024/04/17
## Modified: 2024/04/17
## License: MIT License

# A minor annoyance, this is to filter out unwanted messages on arm64 machines
# Included with x86_64 as well since it will not hurt anything and I don't want to duplicate swat4.sh
wine_wrapper.sh "$GAME_DIR/${CONTENT_PATH_MOD:-$CONTENT_PATH/System/}$SERVER_BINARY.exe" "${MAPLIST[0]}" &> /dev/null & tail -F "$SERVER_BINARY.log" 2> /dev/null
