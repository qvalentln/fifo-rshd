#!/bin/bash

K=$1
CONFIG_FILE="server_config.cfg"
REPLY_DIR="tmp"
FIFO_NAME=$(cat "$CONFIG_FILE" 2>/dev/null)
[[ -z "$FIFO_NAME" ]] && FIFO_NAME="main_fifo"
FIFO_PATH="$FIFO_NAME"

#rutina de curatare
notdef(){
	echo -e "\nUtilizare: ./server.sh [numarul de slave-uri]"
	cleanup
}


cleanup() {
    echo -e "\n\ninchid..."

    	#1. trimit un semnal de exit custom catre fiecare slave prin pipe-uri
        for ((i=1; i<=K; i++)); do
            pipe_path="slave_$i"
            if [ -p "$pipe_path" ]; then
                echo "EXIT_SIG" > "$pipe_path" &
            fi
        done
    
        # 2. kill clasic(safe)
        if [ ${#slid[@]} -gt 0 ]; then
            kill "${slid[@]}" 2>/dev/null
        fi
    
        # 3. inchid descriptorul 3
        exec 3>&- 2>/dev/null
    
        # 4. sterg pipe-urile
        rm -f "$FIFO_PATH"
        rm -f slave_*
    
        echo "exit&cleanup finalizat"
        exit 0
}

trap cleanup SIGINT

#verific daca parametrul a fost primit corect (este un numar nenul)
[[ -z "$K" ]] && notdef 

if ! [ "$K" -eq "$K" ] 2>/dev/null; then
    notdef
fi



mkdir -p "$REPLY_DIR"
[ -p "$FIFO_PATH" ] || mkfifo "$FIFO_PATH"

# tin FIFO-ul deschis permanent, inchid la CTRL+C
exec 3<> "$FIFO_PATH"

#vector de PID-uri (slave)
slid=()
for ((i=1; i<=K; i++))
do
    pipe_name="slave_$i"
    pipe_path="$pipe_name"
    [ -p "$pipe_path" ] || mkfifo "$pipe_path"

    # pornesc slave
    gnome-terminal -- bash -c "
        echo 'terminal slave $i';
        echo 'ascult pe $pipe_path';
        echo '---';
        while true; do
            if read -r instructiune < \"$pipe_path\"; then
				#daca primesc semnalul, opresc terminalul
				if [[ \"\$instructiune\" == \"EXIT_SIG\" ]]; then
                    #echo 'byebye';
                    exit 0;
                fi
                            
                # afisare cmd
                echo \"[\$(date +%T)] execut \$instructiune\";
                # exec + redirect spre reply
                eval \"\$instructiune\"
                echo \"[\$(date +%T)] urmatoarea comanda...\";
            fi
        done" &
        
    #retin PID
    slid+=($!)
done
icmd=0
echo "master activ pe $FIFO_PATH"
echo "CTRL+C pentru exit"

while true; do
	    if read -r linie <&3; then
        #cu ajutorul comenzii sed se parseaza cererea catre slave
        continut=$(echo "$linie" | sed -n 's/.*BEGIN-REQ\[\(.*\)\]END-REQ.*/\1/p')
 
        #in urma parsarii se verifica corectitudinea formatului rezultatului
        if [[ -z "$continut" ]]; then
            echo "Eroare: Format mesaj invalid: $linie"
            continue
        fi
 
        #din textul ramas "pid:cmd" se extrag cei doi parametri 
        c_pid=$(echo "$continut" | cut -d':' -f1)
        c_cmd=$(echo "$continut" | cut -d':' -f2-)
 
        #se alege in sistem round-robin circular slaveul
        target=$(( (icmd % K) + 1 ))
        ((icmd++))
 
        #se efectueaza comunicarea cu slaveul
        echo "($c_cmd) > $REPLY_DIR/server_reply-$c_pid 2>&1" > "slave_$target"
        #echo "Master: Am trimis '$c_cmd' de la clientul $c_pid la sclavul $target"
    fi
done
