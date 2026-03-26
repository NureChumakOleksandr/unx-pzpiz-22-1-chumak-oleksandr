#!/bin/bash

ERROR_LOG="$HOME/log/task2-errors.log"

init_messages() {
  if [[ "$LANG" == uk_UA* ]] || [[ "$LC_MESSAGES" == uk_UA* ]]; then
    MSG_HELP="Використання: $(basename "$0") [-h|--help] [-n число] [файл]
Скрипт фіксує дату та час запуску і записує їх у файл журналу.
Параметри:
  -h, --help    Вивести цю довідку та завершити роботу
  -n число      Кількість збережених архівних файлів (ціле число > 0)
  файл          Шлях до файлу для запису результату
                (за замовчуванням: ~/log/task2.out)
Приклади:
  $(basename "$0")                         Запис у файл за замовчуванням
  $(basename "$0") -n 5 ./logs/info.txt    Зберегти 5 архівних файлів
  $(basename "$0") --help                  Показати довідку"
    MSG_NOT_INT="Аргумент для опції -n повинен бути цілим числом"
    MSG_GREATER="Аргумент для опції -n повинен бути більше 0"
    MSG_RENAMED="Файл %s перейменовано на %s"
    MSG_NOT_DIR="Перший аргумент повинен бути шляхом до файлу, а не до директорії"
    MSG_INVALID="Перший аргумент повинен бути дійсним шляхом до файлу"
    MSG_CREATED="Новий файл створено в %s"
    MSG_PARSE_ERR="Помилка розбору параметрів"
  else
    MSG_HELP="Usage: $(basename "$0") [-h|--help] [-n num] [file]
Logs the current date and time into a log file.
Options:
  -h, --help    Show this help message and exit
  -n num        Number of archived log files to keep (integer > 0)
  file          Path to the output file
                (default: ~/log/task2.out)
Examples:
  $(basename "$0")                         Write to default file
  $(basename "$0") -n 5 ./logs/info.txt    Keep 5 archived files
  $(basename "$0") --help                  Show this help"
    MSG_NOT_INT="Argument supplied for -n option must be an integer"
    MSG_GREATER="Argument supplied for -n option must be greater than 0"
    MSG_RENAMED="File %s was renamed to %s"
    MSG_NOT_DIR="First argument must be a filepath not a directory path"
    MSG_INVALID="First argument must be a valid filepath"
    MSG_CREATED="New file created in %s"
    MSG_PARSE_ERR="Error parsing options"
  fi
}

log_error() {
  local msg="$1"
  mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null
  echo "[$(LC_ALL=C date '+%Y-%m-%d %H:%M:%S')] $msg" >> "$ERROR_LOG" 2>/dev/null
  echo "$msg" >&2
}

parse_args() {
  KEEP_NUM=""

  OPTS=$(getopt -o hn: -l help -- "$@")
  if [ $? -ne 0 ]; then
    log_error "$MSG_PARSE_ERR"
    exit 1
  fi

  eval set -- "$OPTS"

  while true; do
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
        if [[ "$2" -lt 1 ]]; then
          log_error "$MSG_GREATER"
          exit 1
        fi
        KEEP_NUM="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
    esac
  done

  FILEPATH="$HOME/log/task2.out"
  if [ -n "$1" ]; then
    FILEPATH="$1"
  fi
}

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

  LC_ALL=C date "+Date: %a, %d %b %Y %H:%M:%S %z" > "$filepath"
}

main() {
  init_messages
  parse_args "$@"

  local base_name
  base_name="$(basename "$FILEPATH")"
  local dir_name
  dir_name="$(dirname "$FILEPATH")"

  if [ -d "$FILEPATH" ]; then
    log_error "$MSG_NOT_DIR"
    exit 1
  fi

  if [ -e "$FILEPATH" ]; then
    rename_existing "$FILEPATH"
    printf "$MSG_RENAMED\n" "$base_name" "$NEW_ARCHIVE_NAME"

    cleanup_archives "$dir_name" "$base_name" "$KEEP_NUM"

    create_and_write "$FILEPATH"
  else
    create_and_write "$FILEPATH"
    printf "$MSG_CREATED\n" "$FILEPATH"
  fi
}

main "$@"
