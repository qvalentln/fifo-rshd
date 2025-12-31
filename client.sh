	#!/bin/bash

	CLIENT_PID=$$
	config_file="$HOME/server_config.cfg"
	FIFO_NAME=$(cat "$config_file")
	FIFO_PATH="$HOME/$FIFO_NAME"
	fileName="$HOME/tmp/server_reply-$CLIENT_PID"

	cleanup() {
	    rm -f "$fileName"
	    echo -e "\nclient oprit."
	    exit 0
	}
	trap cleanup SIGINT

	clear
	echo "client activ (PID: $CLIENT_PID). scrie 'help' pentru ajutor"

	while true; do
	    echo -n "comanda: "
	    read -r cmd


		#trebuie sa rescriu comenzile help si clear...
	    [[ -z "$cmd" ]] && continue
	    [[ "$cmd" == "exit" ]] && cleanup

	    #1. sterg reply-ul vechi
	    rm -f "$fileName"

	    #2. scriere sincrona 
	    echo "$CLIENT_PID:$cmd" > "$FIFO_PATH"
	    
	    #adaug timeout 5s
	    timer=0
	    while [[ ! -f "$fileName" ]]; do
	        sleep 0.2
	        ((timer++))
	        if [[ $timer -gt 25 ]]; then 
	            echo "Eroare: timeout"
	            break
	        fi
	    done

	    # 3. citire
	    if [[ -f "$fileName" ]]; then
	        #afisez rezultatul
	        cat "$fileName"
	        
	        # sterg imediat dupa citire(just to be safe?)
	        rm -f "$fileName"
	    fi
	done
