
IP_MASTER="192.168.122.240"
PASS_MASTER="123"
USER_MASTER="proiectitbi"
#echo $CLIENT_PID
clear

expect -c "
    # 1. Set a timeout
    set timeout 3

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

    # 5. Hand control to the user
    interact
"

