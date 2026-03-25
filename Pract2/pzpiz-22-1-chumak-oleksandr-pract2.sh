#!/bin/bash

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
  $(basename "$0") --help                  Показати довідку
  "
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
  $(basename "$0") --help                  Show this help
  "
  MSG_NOT_INT="Argument supplied for -n option must be an integer"
  MSG_GREATER="Argument supplied for -n option must be greater than 0"
  MSG_RENAMED="File %s was renamed to %s"
  MSG_NOT_DIR="First argument must be a filepath not a directory path"
  MSG_INVALID="First argument must be a valid filepath"
  MSG_CREATED="New file created in %s"
  MSG_PARSE_ERR="Error parsing options"
fi

OPTS=$(getopt -o hn: -l help -- "$@")
if [ $? -ne 0 ]; then
  echo "$MSG_PARSE_ERR" >&2
  exit 1
fi

eval set -- "$OPTS"

while true; do
  case $1 in
    -h|--help)
      echo "$MSG_HELP"
      exit 0
      ;;
    -n)
      if ! [[ $2 =~ ^[0-9]+$ ]]; then
        echo "$MSG_NOT_INT" >&2
        exit 1
      fi
      if [[ $2 -lt 1 ]]; then
        echo "$MSG_GREATER" >&2
        exit 1
      fi
      shift 2
      ;;
    --)
      shift
      break
      ;;
  esac
done

filepath="$HOME/log/task2.out"
if ! [ -z "$1" ]; then
  filepath=$1
fi

if [ -e "$filepath" ]; then
  filename=$(basename "$filepath")
  filedate=$(date "+%Y%m%d")
  filenumber="0000"
  if [[ "$(basename "$filepath")" =~ ^(.*)-([0-9]{8})-([0-9]{4})$ ]]; then
    filename="${BASH_REMATCH[1]}"
    if ! [ -z "${BASH_REMATCH[2]}" ]; then filedate="${BASH_REMATCH[2]}"; fi
    if ! [ -z "${BASH_REMATCH[3]}" ]; then
      filenumber=$(printf "%04d" $(( 10#${BASH_REMATCH[3]} + 1)))
    fi
  fi
  newFilePath="$(dirname "$filepath")/$filename-$filedate-$filenumber"
  mv "$filepath" "$newFilePath"
  date "+Date: %a, %d %b %Y %H:%M:%S %z" > "$newFilePath"
  printf "$MSG_RENAMED\n" "$(basename "$filepath")" "$(basename "$newFilePath")"
else
  if [ -d "$filepath" ]; then
    echo "$MSG_NOT_DIR" >&2
    exit 1
  fi
  if ! [ -e "$(dirname "$filepath")" ]; then
    mkdir -p "$(dirname "$filepath")"
  fi

  if ! touch "$filepath" 2>/dev/null; then
    echo "$MSG_INVALID" >&2
    exit 1
  fi
  date "+Date: %a, %d %b %Y %H:%M:%S %z" > "$filepath"
  printf "$MSG_CREATED\n" "$filepath"
fi
