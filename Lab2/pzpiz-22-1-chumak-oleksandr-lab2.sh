#!/bin/bash

if [[ "$LANG" == uk_UA* ]] || [[ "$LC_MESSAGES" == uk_UA* ]]; then
    MSG_HELP="Usage: $(basename "$0") [-h|--help] [-n NUM] [FILE]

Logs system specifications into a log file.

Options:
  -h, --help     Show this help message and exit
  -n NUM         Number of archived log files to keep (integer > 0)

Arguments:
  FILE           Path to the output file (optional)
                 If not provided, default is: ~/log/task2.out

Notes:
  - Only one FILE argument is allowed
  - Options must come before FILE

Examples:
  $(basename "$0")
      Write to default file

  $(basename "$0") -n 5
      Keep 5 archived files (default path)

  $(basename "$0") -n 5 ./logs/info.txt
      Keep 5 archived files and write to file

  $(basename "$0") ./output.txt
      Write to specified file"
    MSG_NOT_INT="Аргумент для опції -n повинен бути цілим числом"
    MSG_GREATER="Аргумент для опції -n повинен бути більше 0"
    MSG_RENAMED="Файл %s перейменовано на %s"
    MSG_NOT_DIR="Перший аргумент повинен бути шляхом до файлу, а не до директорії"
    MSG_INVALID="Перший аргумент повинен бути дійсним шляхом до файлу"
else
    MSG_HELP="Використання: $(basename "$0") [-h|--help] [-n ЧИСЛО] [ФАЙЛ]

Скрипт фіксує дані про систему у файл журналу.

Параметри:
  -h, --help     Вивести цю довідку та завершити роботу
  -n ЧИСЛО       Кількість архівних файлів для збереження (ціле число > 0)

Аргументи:
  ФАЙЛ           Шлях до файлу (необов’язковий)
                 За замовчуванням: ~/log/task2.out

Примітки:
  - Дозволено лише один аргумент ФАЙЛ
  - Параметри повинні йти перед ФАЙЛОМ
  - Використовуйте '--', щоб завершити обробку параметрів

Приклади:
  $(basename "$0")
      Запис у файл за замовчуванням

  $(basename "$0") -n 5
      Зберегти 5 архівних файлів (шлях за замовчуванням)

  $(basename "$0") -n 5 ./logs/info.txt
      Зберегти 5 архівів і записати у файл

  $(basename "$0") ./output.txt
      Запис у вказаний файл"
    MSG_NOT_INT="Argument supplied for -n option must be an integer"
    MSG_GREATER="Argument supplied for -n option must be greater than 0"
    MSG_RENAMED="File %s was renamed to %s"
    MSG_NOT_DIR="First argument must be a filepath not a directory path"
    MSG_INVALID="First argument must be a valid filepath"
fi

log_error() {
    echo "$1" >&2
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo "$MSG_HELP"
                exit 0
                ;;
            -n)
                if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                    log_error "$MSG_NOT_INT"
                    exit 1
                fi
                if [ "$2" -lt 1 ]; then
                    log_error "$MSG_GREATER"
                    exit 1
                fi

                KEEP_NUM=$2
                shift 2
                ;;
            --)
                echo "break"
                break
                ;;
            *)
                OUTPUT_FILE=$1
                break
                ;;
        esac
    done
}

cleanup_archives() {
    local dir="$1"
    local base="$2"
    local keep="$3"

    if [ -z "$keep" ]; then
        return
    fi

    local archives=()
    for f in "$dir/${base}-"[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]; do
        if [ -e "$f" ]; then
            archives+=("$f")
        fi
    done

    IFS=$'\n' sorted=($(printf '%s\n' "${archives[@]}" | sort)); unset IFS

    local total=${#sorted[@]}
    if [ "$total" -gt "$keep" ]; then
        local to_delete=$((total - keep))
        for ((i = 0; i < to_delete; i++)); do
            rm -f "${sorted[$i]}"
        done
    fi
}

rename_existing() {
    get_next_number() {
        local dir="$1"
        local base="$2"
        local today="$3"
        local max=-1

        for f in "$dir/${base}-${today}-"[0-9][0-9][0-9][0-9]; do
            if [ -e "$f" ]; then
                local num_part
                num_part=$(basename "$f" | grep -oP '\d{4}$')
                local num_val=$((10#$num_part))
                if [ "$num_val" -gt "$max" ]; then
                    max=$num_val
                fi
            fi
        done

        printf "%04d" $((max + 1))
    }

    local filepath="$1"
    local dir
    local base
    dir="$(dirname "$filepath")"
    base="$(basename "$filepath")"

    local today
    today="$(date '+%Y%m%d')"

    local next_num
    next_num="$(get_next_number "$dir" "$base" "$today")"

    NEW_ARCHIVE_NAME="${base}-${today}-${next_num}"
    local new_path="${dir}/${NEW_ARCHIVE_NAME}"

    mv "$filepath" "$new_path"
}

create_and_write() {
    get_sys_spec_overview() {
        get_cpu() {
            local cpu=$(lscpu 2>/dev/null | grep 'Model name' | awk -F: '{print $2}' | xargs)
            [[ -z "$cpu" ]] && cpu="Unknown"
            echo "$cpu"
        }

        get_ram() {
            local ram=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
            [[ -z "$ram" ]] && ram="Unknown"
            echo "$ram"
        }

        get_motherboard() {
            local board_man=$(sudo dmidecode -s baseboard-manufacturer 2>/dev/null | xargs || echo "Unknown")
            local board_prod=$(sudo dmidecode -s baseboard-product-name 2>/dev/null || echo "Unknown")
            echo "$board_man $board_prod"
        }

        get_os() {
            local os=$(grep 'PRETTY_NAME' /etc/os-release | awk -F\" '{print $2}')
            [[ -z "$os" ]] && os="Unknown"
            echo "$os"
        }

        get_install_date() {
            local date=$(stat / 2>/dev/null | grep 'Birth' | awk '{print $2, $3}')
            [[ -z "$date" ]] && date="Unknown"
            echo "$date"
        }

        # Date
        local NOW=$(date "+%s")
        local DATE_STR=$(LC_ALL=C date -d "@$NOW" "+Date: %a, %d %b %Y %H:%M:%S %z")
        local UNIX_TS="Unix Timestamp: $NOW"

        # Hardware
        local CPU=$(get_cpu)
        local RAM=$(get_ram)
        local MOTHERBOARD=$(get_motherboard)
        local SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null || echo "Unknown")

        # System
        local OS=$(get_os)
        local KERNEL=$(uname -r)
        local INSTALL_DATE=$(get_install_date)
        local HOST=$(hostname)
        local UPTIME=$(uptime -p)
        local PROCESSES=$(ps -A --no-headers | wc -l)
        local USERS=$(who | wc -l)
        local NETWORK=$(ip -o addr | awk '{iface=$2; ip=$4; if(ip=="") ip="-/-"; print iface": "ip}')

        echo "$DATE_STR"
        echo "$UNIX_TS"
        echo "---- Hardware ----"
        echo "CPU: \"$CPU\""
        echo "RAM: $RAM MB"
        echo "Motherboard: $MOTHERBOARD"
        echo "System Serial Number: $SERIAL"
        echo "---- System ----"
        echo "OS Distribution: \"$OS\""
        echo "Kernel version: $KERNEL"
        echo "Installation date: $INSTALL_DATE"
        echo "Hostname: $HOST"
        echo "Uptime: $UPTIME"
        echo "Processes running: $PROCESSES"
        echo "Users logged in: $USERS"
        echo "---- Network ----"
        echo "$NETWORK"
        echo '----"EOF"----'
    }

    local filepath="$1"
    local dir
    dir="$(dirname "$filepath")"

    if [ ! -e "$dir" ]; then
        if ! mkdir -p "$dir" 2>/dev/null; then
            log_error "$MSG_INVALID"
            exit 1
        fi
    fi

    if ! touch "$filepath" 2>/dev/null; then
        log_error "$MSG_INVALID"
        exit 1
    fi

    get_sys_spec_overview | tee "$OUTPUT_FILE"
}


main() {
    parse_args "$@"
    if [ -z "$OUTPUT_FILE" ]; then OUTPUT_FILE="$HOME/log/task2.out"; fi

    local base_name
    base_name="$(basename "$OUTPUT_FILE")"
    local dir_name
    dir_name="$(dirname "$OUTPUT_FILE")"

    if [ -d "$OUTPUT_FILE" ]; then
        log_error "$MSG_NOT_DIR"
        exit 1
    fi

    if [ -e "$OUTPUT_FILE" ]; then
        rename_existing "$OUTPUT_FILE"
        cleanup_archives "$dir_name" "$base_name" "$KEEP_NUM"
        create_and_write "$OUTPUT_FILE"
    else
        create_and_write "$OUTPUT_FILE"
    fi
}

main "$@"
