#e irelevant asta, doar daca 
#pun serverul pe un vm (ceea ce nu cred ca trebuie...)


IP_MASTER="192.168.122.240"
PASS_MASTER="123"
USER_MASTER="proiectitbi"
#echo $CLIENT_PID
clear

expect -c "
    # 1. timeout
    set timeout 3

    # 2. connect
    
    spawn rlogin $IP_MASTER -l $USER_MASTER

    # 3. passwd prompt handling
    # trebuie sa folosesc escapeuri
    expect \"*assword:\" 
    send \"$PASS_MASTER\r\"

    # 4. wait prompt
    # \\\$ ptr prompt
    expect -re \"(\\\$|#|>) \"

    # 5. hand control to user
    interact
"

