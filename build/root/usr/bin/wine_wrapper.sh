#!/command/with-contenv bash
## File: Wine Wrapper - wine_wrapper.sh
## Author: Kevin Moore <admin@sbotnas.io>
## Created: 2024/04/17
## Modified: 2024/04/17
## License: MIT License

# A minor annoyance, this is to filter out unwanted messages on arm64 machines
# Included with x86_64 as well since it will not hurt anything and I don't want to duplicate swat4.sh
xvfb-run wine "$@" 2>&1 | grep -v -e "starting Box64 based box64cpu.dll" -e "Hangover currently has issues with some ACM modules, disabling" 
