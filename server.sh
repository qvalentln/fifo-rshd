#!/bin/bash
#aceeasi treaba cu fisierele ca la client
K=3
CONFIG_FILE="server_config.cfg"
REPLY_DIR="tmp"
#daca cfg-ul este gol, numele default va fi main_fifo
FIFO_NAME=$(cat "$CONFIG_FILE" 2>/dev/null || echo "main_fifo")
FIFO_PATH="$FIFO_NAME"

#rutina de curatare
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
        
    #retin PID, va fi util cand inchidem terminalele la 
	#oprirea serverului
    slid+=($!)
done
icmd=0
echo "master activ pe $FIFO_PATH"
echo "CTRL+C pentru exit"


#varianta mea cu round-robin (facuta pe branci, sa vedem daca e buna)
while true; do
	if read -r data <&3; then
        [[ -z "$data" ]] && continue
        
        IFS=":" read -r CLIENT_PID COMMAND <<< "$data"
        cmd=$(echo "$cmd" | xargs)

		#reply_dir lowkey e doar tmp
        fileName="$REPLY_DIR/server_reply-$CLIENT_PID"
        
        final_instruction="$cmd > \"$fileName\" 2>&1"

        slave_idx=$(( (icmd % K) + 1 ))
        target_pipe="slave_$slave_idx"

        echo "Comanda de la $CLIENT_PID trimisa la slave-ul $slave_idx"
        echo "$final_instruction" > "$target_pipe" &
        ((icmd++))
    fi
done
