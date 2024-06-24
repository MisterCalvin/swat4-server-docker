# SWAT 4 Dedicated Server in Docker
A Docker container running a SWAT 4 Dedicated Server under Wine, built on Alpine. This container supports mods, see the docker compose or docker cli commands below for information on how to enable them. Your game directory (mounted in the container as `/container/swat4`) should be structured as follows:

    .
    ├── ...
    ├── Content
    ├── ContentExpansion
    ├── YourMod1
    └── YourMod2

The container is built with the Master Server Patches necessary for listing your game on the community server list, it will check your `Content/` and `ContentExpansion/` folder for their existence at each startup and automatically replace them if are they are not the correct files. You can find the the patches <a href="https://github.com/sergeii/swat-patches/tree/master/swat4stats-masterserver/" target="_blank">here</a>.

### docker compose

```
services: 
  swat4-server-docker: 
    image: ghcr.io/mistercalvin/swat4-server-docker:latest
    container_name: swat4-server-docker
    environment: 
      TZ: America/New_York
      PUID: 1000 # Optional: Set the UID for the user inside the container; Default: 1000
      PGID: 1000 # Optional: Set the GID for the user inside the container; Default: 1000
      CONTENT_VERSION: SWAT4 # Required: Choose SWAT4, TSS, or enter the name of your mod folder (case-sensitive); Default: SWAT4
      SERVER_NAME: A SWAT 4 Docker Server # Required: Name of the Server; Default: A SWAT4 Docker Server
      SERVER_PASSWORD: # Optional: Password for the Server (alphanumeric characters only); Default: unset
      GAME_TYPE: 2 # Required: Choose Barricaded Suspects (1), CO-OP (2), Rapid Deployment (3), Smash and Grab (4), or VIP Escort (5); Default: CO-OP
      LAN_ONLY: False # Optional: If True, the server is hosted only over the LAN (not internet); Default: False
      SERVER_MAPLIST: "SP-FairfaxResidence,SP-Foodwall,SP-Hospital" # Required: Comma-separated list of map names, without extension; Default: SP-FairfaxResidence,SP-Foodwall,SP-Hospital
      MAX_PLAYERS: 10 # Optional: Maximum amount of players for the server; Default: 10
      ADMIN_PASSWORD: # Optional: Admin password for in-game administration (alphanumeric characters only); Default: unset
      NUM_ROUNDS: 15 # Optional: Number of rounds for each match; Default: 15
      ROUND_TIME_LIMIT: 900 # Optional: Time limit (in seconds) for each round (0 - No Time Limit); Default: 900
      DEATH_LIMIT: 50 # Optional:  How many deaths are required to lose a round (0 - No Death Limit); Default: 50
      MP_MISSION_READY_TIME: 90 # Optional: Time (in seconds) for players to ready themselves in between rounds in a MP game; Default: 90
      POST_GAME_TIME_LIMIT: 15 # Optional: Time (in seconds) between the end of the round and server loading the next level; Default: 15
      QUICK_ROUND_RESET: False # Optional: If true, the server will perform a quick reset in between rounds on the same map, if false, the server will do a full SwitchLevel between rounds; Default: False
      ADDITIONAL_ARGS: # Optional: Comma-separated list of additional arguments to modify; Default: unset
    volumes: 
      - /path/to/your/gamefile:/container/swat4
      - swat4-wine:/container/.wine
    ports: 
      - 10480-10483:10480-10483/udp
    restart: unless-stopped

volumes:
  swat4-wine:
    name: swat4-wine
```

### docker cli
Create a named volume before executing the command below: `docker volume create swat4-wine` (this will persist your .wine directory, allowing for quicker server startup times)

```
docker run -d \
  --name=swat4-server-docker \
  -e PUID="1000" \
  -e PGID="1000" \
  -e TZ="America/New_York" \
  -e CONTENT_VERSION="SWAT4" \
  -e SERVER_NAME="A SWAT 4 Docker Server" \
  -e SERVER_PASSWORD="" \
  -e GAME_TYPE="CO-OP" \
  -e SERVER_MAPLIST="SP-FairfaxResidence,SP-Foodwall,SP-Hospital" \
  -e LAN_ONLY="False" \
  -e MAX_PLAYERS="10" \
  -e ADMIN_PASSWORD="" \
  -e NUM_ROUNDS="15" \
  -e ROUND_TIME_LIMIT="900" \
  -e DEATH_LIMIT="50" \
  -e MP_MISSION_READY_TIME="90" \
  -e POST_GAME_TIME_LIMIT="15" \
  -e QUICK_ROUND_RESET="False" \
  -e ADDITIONAL_ARGS="" \
  -p 10480-10483:10480-10483/udp \
  -v /path/to/gamefiles/:/container/swat4 \
  -v swat4-wine:/container/.wine \
  --restart unless-stopped \
  ghcr.io/mistercalvin/swat4-server-docker:latest
```
  
## Server Ports
SWAT 4 requires Join Port + 3 (Default port is 10480, so 10480-10483/udp)

| Port      | Default  |
|-----------|----------|
| Join 		| 10480/udp|
| Query     | 10481/udp|
|        	| 10482/udp|
|       	| 10483/udp|

## Useful Information
#### <sup>1</sup> Changing Server Text Color in Server Browser
> You use the hexidecimal color number. For example in Swatguistate.ini under [SwatGame.ServerSettings] in the line for ServerName=, add the [c=00ff00] in front of your server name to make your server name appear green in the ingame Browser. Yellow would be ffff00, blue is 0000ff, and red is ff0000. You can use different shades by finding the corresponding hex color number you want from just about any graphics program that supports hexidecimal color numbers such as photoshop or paintshop pro. Likewise for underline you would add a [u] infront of the section you want to underline.
<br><br>
The downside of this is that ingame when you hit esc to see the scores or mission status, your server name will not show the color but will show the brackets and color code infront of your server name. Like this: "[c=00ff00][u]Fatality Inc. Coop 1". If that doesn't bother you then run with the colors.

To customize your server name color you can add the blocks to your `SERVER_NAME` variable:

```
SERVER_NAME="[c=0000ff][u][b]A SWAT 4 Docker Server[\u][\b]"
```

#### <sup>2</sup> Quick Round Reset
> Quick Round Reset: If number of rounds is set to more than one, this setting will start the new round on the same map without reloading. This saves on loading time but all interactive elements of a level, such as open doors and broken windows, will remain in the same state as the previous round.

#### Using ADDITIONAL_ARGS
Most common options such as Server name, password, admin password, etc., have been exposed as environment variables for convenience. If you would like to modify an option not exposed, you can use ADDITIONAL_ARGS. For example, if you wanted to disable showing teammate names and disable respawns, you would add the following to your docker-compose.yml or docker run command:

> ADDITIONAL_ARGS="bShowTeammateNames=False,bNoRespawn=True"

For a list other options, take a look at your `SwatGUIState.ini`, located in `GAME_DIR/System/`.  

<sup>1</sup> <a href="https://sasclan.org/forum-topic/swat-4-server-administration-3550" target="_blank">SWAT 4 Server administration</a>  
<sup>2</sup> <a href="https://sierrachest.com/index.php?a=games&id=74&title=swat-4&fld=walkthrough&pid=13#:~:text=Quick%20Round%20Reset%3A%20If%20number,state%20as%20the%20previous%20round." target="_blank">The Sierra Chest</a>  
## User / Group Identifiers
You can specify the UID & GID for the user (app) inside the container, see <a href="https://github.com/jlesage/docker-baseimage-gui#usergroup-ids" target="_blank">this page</a> for more information.

Please note this does not change file permissions on the mounted volume (`/container/swat4`), it only changes the default container users (`wine`) UID/GID to the specified value. Make sure proper permissions are applied to the game files directory on the host (SWAT 4 in particular requires write permissions to create a log file and a blank Running.ini to the `/System` folder at runtime).

## Notes / Bugs
- I tested this to the best of my abilities, however SWAT 4 is a buggy game and I am sure there are some things I missed. If you have any problems feel free to [open a new issue](../../issues).

- Mods are supported, however they will not respect the `ADMIN_PASSWORD` env variable. For setting up in-game administration on a server running a mod you will need to consult with the developers documentation.

- Mods may also have additional features or options you can configure, you will need to manually edit the SwatGUIState.ini file found within your mods `System/` folder if you wish to modify anything. The startup script is designed to only overwrite the env variables listed in the Dockerfile, everything else will be untouched.

- I have tested the container with the following mods:

| Mod       			| Version  																							|
|-----------------------|---------------------------------------------------------------------------------------------------|
| SWAT: Elite Force     | <a href="https://www.moddb.com/mods/swat-elite-force/downloads/swat-elite-force-v7" target="_blank">7</a>					|
| SEF First Responders 		| <a href="https://www.moddb.com/mods/sef-first-responders/downloads/sef-first-responders-v067-stable" target="_blank">0.67 Stable</a>	|
| SWAT: Back to LA 		| <a href="https://www.moddb.com/mods/swat-back-to-los-angeles/downloads/sef-back-to-los-angeles-v16" target="_blank">1.6</a>	|
| Canadian Forces: Direct Action | <a href="https://www.moddb.com/downloads/canadian-forces-direct-action-41" target="_blank">4.1</a>					|
| 11-99 Enhancement 	| <a href="https://www.moddb.com/mods/11-99-enhancement-mod/downloads/11-99-enhancement-mod-v13" target="_blank">1.3</a>		|

## Building
If you intend to build the Dockerfile yourself, I have not pinned the packages as Alpine does not keep old packages. At the time of writing (2024/06/24) I have built and tested the container with the following package versions:

| Package   			               | Version      |
| ------------------------------ | ------------ |
| alpine                         | 3.20.1       |
| wine (**i386 only**)           | 9.9-r0       |
| hangover-wine (**arm64 only**) | 9.5-r0       |
| bash                           | 5.2.26-r0    |
| tzdata                         | 2024a-r1     |
| shadow                         | 4.15.1-r0    |
| wget                           | 1.36.1       |
| figlet                         | 2.2.5-r3     |
| xvfb-run                       | 1.20.10.3-r2 |
| findutils                      | 4.9.0-r5     |
| s6-overlay                     | 3.1.6.2      |

## ARM64 Support
This container has been adapted for use on ARM64 processors by utilizing the project <a href="https://github.com/AndreRH/hangover" target="_blank">AndreRH/hangover</a>. ARM64 support is experimental and was only tested on a Raspberry Pi 4, you may experience additional bugs.
