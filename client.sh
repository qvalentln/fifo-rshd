#!/bin/bash

#variabilele de uz general ale programului
CLIENT_PID=$$
config_file="server_config.cfg"
FIFO_NAME=$(cat "$config_file")
FIFO_PATH="$FIFO_NAME"
fileName="tmp/server_reply-$CLIENT_PID"

#la terminarea programului se curata directorul curent
cleanup(){
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

	#cmd vid
	[[ -z "$cmd" ]] && continue
	
	if [[ "$cmd" == "exit" ]]; then
		cleanup
	fi
		

	if [[ "$cmd" == "clear" ]]; then
		clear
		continue
	fi
	
	if [[ "$cmd" == "help" ]]; then
		echo
		echo "help - comenzi suportate de program"
		echo "clear - curata ecranul"
		echo "[cmd] - scrie o comanda linux"
		echo "exit - oprire"
		echo
		continue
	fi

	#stergerea raspunsurilor anterioare
	rm -f "$fileName"

	#transmitereaa comenzii catre master
	#formatul comenzii este cel din cerint, respectiv "BEGIN-REQ[$CLIENT_PID:$cmd]END-REQ"
	echo "BEGIN-REQ[$CLIENT_PID:$cmd]END-REQ" > "$FIFO_PATH"
	
	#pentru exectuarea asincrona se adauga un cooldown
	timer=0
	while [[ ! -f "$fileName" ]]; do
		sleep 0.2
		((timer++))
		if [[ $timer -gt 25 ]]; then 
			echo "Eroare: timeout"
			break
		fi
	done

	#etapa de primire a raspunsurilor de la slave
	if [[ -f "$fileName" ]]; then
		cat "$fileName"
		rm -f "$fileName"
	fi
done
