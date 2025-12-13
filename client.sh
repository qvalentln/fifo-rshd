
CLIENT_PID=$$
#config_file="$HOME/server_config.cfg"
#FIFO_NAME=$(cat "$config_file")

CLIENT_HOME=$HOME

IP_MASTER="192.168.122.240"
PASS_MASTER="123"
USER_MASTER="proiectitbi"

cleanup() {

    clear
    rm "$HOME/tmp/server_reply-$CLIENT_PID"
    echo "Program has stopped..."
    exit 0

}

trap cleanup SIGINT

#echo $CLIENT_PID
clear

#Login master
expect -c "
    # 1. Set a timeout
    set timeout 1


    # 2. Start the connection
    # (Bash expands these variables before Expect starts)
    spawn rlogin $IP_MASTER -l $USER_MASTER

    # 3. Handle the password prompt
    # Note: We must escape quotes (\") inside the -c block
    expect \"*assword:\" 
    send \"$PASS_MASTER\r\"

    # 4. Wait for prompt
    # We use \\\$ to handle the dollar sign safely through Bash and Expect
    expect -re \"(\\\$|#|>) \"

	#Run the remote client script located inside master

	send \"./remote_client.sh && exit\r\"

	interact
    
"

