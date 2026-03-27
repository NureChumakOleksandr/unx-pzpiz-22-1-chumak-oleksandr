#!/bin/bash

child_pid=-1

if [[ "$LANG" == uk* ]]; then
    MSG_HELP="Допомога: використайте команди ping, hup, exit"
    MSG_UNKNOWN_OPT="Невідомий параметр: "
    MSG_UNKNOWN_CMD="Невідома команда"
    MSG_CHILD_CREATED="Дочірній процес створено. PID: "
    MSG_SEND_HUP="Надіслати HUP до PID: "
    MSG_PING="Ping PID: "
    MSG_CHILD_TERMINATED="Дочірній процес успішно завершено"
else
    MSG_HELP="Help: use commands ping, hup, exit"
    MSG_UNKNOWN_OPT="Unknown option: "
    MSG_UNKNOWN_CMD="Unknown command"
    MSG_CHILD_CREATED="Child process created. PID: "
    MSG_SEND_HUP="Send HUP to PID: "
    MSG_PING="Ping PID: "
    MSG_CHILD_TERMINATED="Child process was succesfully terminated"
fi

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                echo "$MSG_HELP"
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "$MSG_UNKNOWN_OPT$1" >&2
                exit 1
                ;;
        esac
        shift
    done
}

log_event() {
    if ! [ -d "log" ]; then mkdir "log"; fi
    if ! [ -e "log/log.txt" ]; then
        touch "log/log.txt"
        echo "<date>; <timestamp>; <PID>; <signal_number>; <signal_name>; <description>" > "log/log.txt"
    fi

    local signal_number=$1
    local signal_name=$2
    local description=$3

    echo "$(date -u +"%a, %d %b %Y %H:%M:%S +0000"); $(date +%s); $$; $signal_number; $signal_name; $description" >> "log/log.txt"

    logger "$signal_name: $description (PID $$)"
}

read_user_input() {
    while true; do
        read -p "> " cmd
        case "$cmd" in
            ping)
                echo "$MSG_PING$child_pid"
                kill -USR1 $child_pid
                ;;
            hup)
                echo "$MSG_SEND_HUP$child_pid"
                kill -HUP $child_pid
                ;;
            exit)
                kill -TERM $child_pid
                wait $child_pid
                echo "$MSG_CHILD_TERMINATED"
                exit 0
                ;;
            *)
                echo "$MSG_UNKNOWN_CMD"
                ;;
        esac
    done
}

create_child_process() {
    child() {
        [[ $(id -u) -ne 0 ]] && trap '' HUP TERM USR1 USR2

        trap 'log_event 10 "USR1" "Received USR1"' USR1
        trap 'log_event 1 "HUP" "Received HUP"' HUP
        trap 'log_event 15 "TERM" "Received TERM"; exit 0' TERM

        while true; do sleep 0.1; done
    }

    child &
    child_pid=$!
    echo "$MSG_CHILD_CREATED$child_pid"
}

main() {
    parse_args "$@"
    create_child_process
    read_user_input
}

main "$@"
