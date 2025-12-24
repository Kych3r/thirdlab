#!/bin/bash
# backup_script.sh

DB_SERVICE="db"
DB_USER="kirillLABS"
DB_PASSWORD="kirillLABS"
DB_NAME="kirillLABS"
BACKUP_DIR="./backups"

if [ ! -f "docker-compose.yml" ]; then
  echo "Файл docker-compose.yml не найден в текущей директории!"
  exit 1
fi

if [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
  echo "Ошибка: не заданы обязательные переменные окружения:"
  echo "  DB_USER - имя пользователя БД"
  echo "  DB_PASSWORD - пароль пользователя БД"
  echo "  DB_NAME - имя базы данных"
  echo "  DB_SERVICE - имя сервиса в docker-compose.yml (опционально)"
  exit 1
fi

mkdir -p "$BACKUP_DIR" || { echo "Ошибка создания директории $BACKUP_DIR"; exit 1; }

DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${DATE}.sql.gz"

docker-compose exec -T "$DB_SERVICE" \
  env PGPASSWORD="$DB_PASSWORD" \
  pg_dump -U "$DB_USER" -d "$DB_NAME" --no-owner | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ] && [ -s "$BACKUP_FILE" ]; then
  echo "Успешно создан бэкап: $(basename "$BACKUP_FILE") ($(du -h "$BACKUP_FILE" | cut -f1))"
  
  find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +7 -type f -delete
else

  [ -f "$BACKUP_FILE" ] && rm -f "$BACKUP_FILE"
  echo "Ошибка при создании бэкапа! Файл удален."
  exit 1
fi
