#!/bin/bash

# File names
properties_file="properties.conf"
proxies_file="proxies.txt"
vpns_file="vpns.txt"
containers_file="containers.txt"
container_names_file="containernames.txt"
networks_file="networks.txt"
browser_file="browsers.txt"
chrome_containers_file="chromecontainers.txt"
chrome_data_folder="chromedata"
chrome_profile_data="chromeprofiledata"
chrome_profile_zipfile="chrome_profile_data.zip"
required_files=($properties_file)
files_to_be_removed=($containers_file $container_names_file $networks_file $browser_file $chrome_containers_file)
folders_to_be_removed=($chrome_data_folder $chrome_profile_data)

container_pulled=false

# Browser first port
browser_first_port=3000

#Unique Id
RANDOM=$(date +%s)
UNIQUE_ID="$(echo -n "$RANDOM" | md5sum | cut -c1-32)"

# Function to check for open ports
check_open_ports() {
  local first_port=$1
  local num_ports=$2
  port_range=$(seq $first_port $((first_port+num_ports-1)))
  open_ports=0

  for port in $port_range; do
    nc -z localhost $port > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      open_ports=$((open_ports+1))
    fi
  done

  while [ $open_ports -gt 0 ]; do
    first_port=$((first_port+num_ports))
    port_range=$(seq $first_port $((first_port+num_ports-1)))
    open_ports=0
    for port in $port_range; do
      nc -z localhost $port > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        open_ports=$((open_ports+1))
      fi
    done
  done

  echo $first_port
}

# Execute docker command
execute_docker_command() {
  container_parameters=("$@")  # Store parameters as an array
  app_name=${container_parameters[0]}
  container_name=${container_parameters[1]}
  echo -e "${GREEN}Starting $app_name container..${NOCOLOUR}"
  echo "$container_name" | tee -a $container_names_file
  if CONTAINER_ID=$(sudo docker run -d --name $container_name --restart=always "${container_parameters[@]:2}"); then
    echo "$CONTAINER_ID" | tee -a $containers_file
  else
    echo -e "${RED}Failed to start container for $app_name..Exiting..${NOCOLOUR}"
    exit 1
  fi
}

# Start all containers
start_containers() {

  i=$1
  proxy=$2
  vpn_enabled=$3

  if [[ "$ENABLE_LOGS" = false ]]; then
    LOGS_PARAM="--log-driver none"
    TUN_LOG_PARAM="silent"
  else
    TUN_LOG_PARAM="info"
  fi

  if [[ $MAX_MEMORY ]]; then
    MAX_MEMORY_PARAM="-m $MAX_MEMORY"
  fi

  if [[ $MEMORY_RESERVATION ]]; then
    MEMORY_RESERVATION_PARAM="--memory-reservation=$MEMORY_RESERVATION"
  fi

  if [[ $CPU ]]; then
    CPU_PARAM="--cpus=$CPU"
  fi

  if [[ $i && $proxy ]]; then
    NETWORK_TUN="--network=container:tun$UNIQUE_ID$i"

    if [[ $INSTANT_FAUCET ]]; then
      browser_first_port=$(check_open_ports $browser_first_port 1)
      if ! expr "$browser_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $browser_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Browser. Resolve or disable Browser to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      browser_port="-p $browser_first_port:3000 "
    fi

    combined_ports=$browser_port
    # Starting tun containers
    if [ "$container_pulled" = false ]; then
      sudo docker pull xjasonlyu/tun2socks:v2.5.0
    fi

    if [ "$vpn_enabled" ];then
      NETWORK_TUN="--network=container:gluetun$UNIQUE_ID$i"
      docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM  $proxy -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports ghcr.io/qdm12/gluetun)
      execute_docker_command "VPN" "gluetun$UNIQUE_ID$i" "${docker_parameters[@]}"
    else
      docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports xjasonlyu/tun2socks:v2.5.0)
      execute_docker_command "Proxy" "tun$UNIQUE_ID$i" "${docker_parameters[@]}"
      sudo docker exec tun$UNIQUE_ID$i sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf;echo "nameserver 1.1.1.1" >> /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;'
      sudo docker exec tun$UNIQUE_ID$i sh -c "sed -i \"\|exec tun2socks|s#.*#echo 'nameserver 8.8.8.8' > /etc/resolv.conf;echo 'nameserver 1.1.1.1' >> /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;exec tun2socks \\\\\#\" entrypoint.sh"
    fi
    sleep 1
  fi

  # Starting Browser container
  if [[ $CAP_GURU_API_KEY ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull ghcr.io/videoearn/docker-chromium:master

      # Download the chrome profile if not present
      if [ ! -f "$PWD/$chrome_profile_zipfile" ];then
        wget  https://github.com/faucetbrowser/faucetbrowser/releases/download/release/chrome_profile_data.zip
      fi

      # Exit, if chrome profile zip file is missing
      if [ ! -f "$PWD/$chrome_profile_zipfile" ];then
        echo -e "${RED}Chrome profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

      # Unzip the file
      unzip $chrome_profile_zipfile

      # Exit, if chrome profile data is missing
      if [ ! -d "$PWD/$chrome_profile_data" ];then
        echo -e "${RED}Chrome Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

    fi

    # Create folder and copy files
    mkdir -p $PWD/$chrome_data_folder/data$i
    sudo chown -R 911:911 $PWD/$chrome_profile_data
    sudo cp -r $PWD/$chrome_profile_data $PWD/$chrome_data_folder/data$i
    sudo chown -R 911:911 $PWD/$chrome_data_folder/data$i
    sudo  echo "var apiKey=\"$CAP_GURU_API_KEY\";" > $PWD/$chrome_data_folder/data$i/$chrome_profile_data/Downloads/videoEarn/apiKey.js
    sudo chmod -R 777 $PWD/$chrome_data_folder/data$i/$chrome_profile_data/Downloads/videoEarn/apiKey.js
    if [[  ! $proxy ]]; then
      browser_first_port=$(check_open_ports $browser_first_port 1)
      if ! expr "$browser_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $browser_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Browser. Resolve or disable Browser to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      br_port="-p $browser_first_port:3000"
    fi

    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC -e CHROME_CLI='https://payup.video' -v $PWD/$chrome_data_folder/data$i/$chrome_profile_data:/config --shm-size="1gb" $br_port ghcr.io/videoearn/docker-chromium:master)

    execute_docker_command "Browser" "browser$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $browser_file in the same folder${NOCOLOUR}"
    #sleep 3
    #sudo docker stop browser$UNIQUE_ID$i
    #sleep 2
    #sudo docker start browser$UNIQUE_ID$i
    echo "http://127.0.0.1:$browser_first_port" |tee -a $browser_file
    echo "browser$UNIQUE_ID$i" | tee -a $chrome_containers_file
    browser_first_port=`expr $browser_first_port + 1`
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Browser settings are not configured. Ignoring Browser..${NOCOLOUR}"
    fi
  fi

  container_pulled=true

  # Exiting the script since one IP is required for one account
  exit 1
}

if [[ "$1" == "--start" ]]; then
  echo -e "\n\nStarting.."

  # Check if the required files are present
  for required_file in "${required_files[@]}"
  do
  if [ ! -f "$required_file" ]; then
    echo -e "${RED}Required file $required_file does not exist, exiting..${NOCOLOUR}"
    exit 1
  fi
  done

  for file in "${files_to_be_removed[@]}"
  do
  if [ -f "$file" ]; then
    echo -e "${RED}File $file still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
    echo -e "To stop and delete containers run the following command\n"
    echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
    exit 1
  fi
  done

  for folder in "${folders_to_be_removed[@]}"
  do
  if [ -d "$folder" ]; then
    echo -e "${RED}Folder $folder still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
    echo -e "To stop and delete containers run the following command\n"
    echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
    exit 1
  fi
  done

  # Remove special characters ^M from properties file
  sed -i 's/\r//g' $properties_file

  # Read the properties file and export variables to the current shell
  while IFS= read -r line; do
    # Ignore lines that start with #
    if [[ $line != '#'* ]]; then
        # Split the line at the first occurrence of =
        key="${line%%=*}"
        value="${line#*=}"
        # Trim leading and trailing whitespace from key and value
        key="${key%"${key##*[![:space:]]}"}"
        value="${value%"${value##*[![:space:]]}"}"
        # Ignore lines without a value after =
        if [[ -n $value ]]; then
            # Replace variables with their values
            value=$(eval "echo $value")
            # Export the key-value pairs as variables
            export "$key"="$value"
        fi
    fi
  done < $properties_file

  # Use direct Connection
  if [ "$USE_DIRECT_CONNECTION" = true ]; then
     echo -e "${GREEN}USE_DIRECT_CONNECTION is enabled, using direct internet connection..${NOCOLOUR}"
     start_containers
  fi

  # Use Vpns
  if [ "$USE_VPNS" = true ]; then
    echo -e "${GREEN}USE_VPNS is enabled, using vpns..${NOCOLOUR}"
    if [ ! -f "$vpns_file" ]; then
      echo -e "${RED}Vpns file $vpns_file does not exist, exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special character ^M from vpn file
    sed -i 's/\r//g' $vpns_file

    i=0;
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line" "true"
      fi
    done < $vpns_file
  fi

  # Use Proxies
  if [ "$USE_PROXIES" = true ]; then
    echo -e "${GREEN}USE_PROXIES is enabled, using proxies..${NOCOLOUR}"
    if [ ! -f "$proxies_file" ]; then
      echo -e "${RED}Proxies file $proxies_file does not exist, exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special character ^M from proxies file
    sed -i 's/\r//g' $proxies_file

    i=0;
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line"
      fi
    done < $proxies_file
  fi

fi

if [[ "$1" == "--delete" ]]; then
  echo -e "\n\nDeleting Containers and networks.."

  # Delete containers by container names
  if [ -f "$container_names_file" ]; then
    for i in `cat $container_names_file`
    do
      # Check if container exists
      if sudo docker inspect $i >/dev/null 2>&1; then
        # Stop and Remove container
        sudo docker rm -f $i
      else
        echo "Container $i does not exist"
      fi
    done
    # Delete the container file
    rm $container_names_file
  fi

  # Delete networks
  if [ -f "$networks_file" ]; then
    for i in `cat $networks_file`
    do
      # Check if network exists and delete
      if sudo docker network inspect $i > /dev/null 2>&1; then
        sudo docker network rm $i
      else
        echo "Network $i does not exist"
      fi
    done
    # Delete network file
    rm $networks_file
  fi

  for file in "${files_to_be_removed[@]}"
  do
  if [ -f "$file" ]; then
    rm $file
  fi
  done

  for folder in "${folders_to_be_removed[@]}"
  do
  if [ -d "$folder" ]; then
    rm -Rf $folder;
  fi
  done

fi

if [[ "$1" == "--deleteBackup" ]]; then
  echo -e "\n\nDeleting backup folders and files.."

  for file in "${files_to_be_removed[@]}"
  do
  if [ -f "$file" ]; then
    echo -e "${RED}File $file still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
    echo -e "To stop and delete containers run the following command\n"
    echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
    exit 1
  fi
  done

  for folder in "${folders_to_be_removed[@]}"
  do
  if [ -d "$folder" ]; then
    echo -e "${RED}Folder $folder still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
    echo -e "To stop and delete containers run the following command\n"
    echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
    exit 1
  fi
  done

  for file in "${back_up_files[@]}"
  do
  if [ -f "$file" ]; then
    rm $file
  fi
  done

  for folder in "${back_up_folders[@]}"
  do
  if [ -d "$folder" ]; then
    rm -Rf $folder;
  fi
  done
fi

if [[ ! "$1" ]]; then
  echo "No option provided. Use --start or --delete to execute"
fi
