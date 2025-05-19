# Скрипт для автоматической установки PostgreSQL на Debian

# Настройки
LOG_FILE="/tmp/postgresql_install.log"
DB_NAME="mydatabase"
DB_USER="myuser"
DB_PASSWORD="mypassword"

# Функция логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Проверка, что скрипт запущен с правами root
if [ "$(id -u)" != "0" ]; then
    log "Ошибка: Скрипт должен быть запущен с правами root (sudo)."
    exit 1
fi

# Обновление списка пакетов
log "Обновление списка пакетов..."
apt-get update >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "Ошибка: Не удалось обновить список пакетов."
    exit 1
fi

# Проверка и установка PostgreSQL
if ! dpkg -l | grep -q postgresql; then
    log "Установка postgresql и postgresql-contrib..."
    apt-get install -y postgresql postgresql-contrib >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "Ошибка: Не удалось установить PostgreSQL."
        exit 1
    fi
else
    log "PostgreSQL уже установлен."
fi

# Включение и запуск службы PostgreSQL
log "Включение и запуск службы PostgreSQL..."
systemctl enable postgresql >> "$LOG_FILE" 2>&1
systemctl start postgresql >> "$LOG_FILE" 2>&1
if ! systemctl is-active --quiet postgresql; then
    log "Ошибка: PostgreSQL не запустился."
    exit 1
fi

# Проверка версии PostgreSQL
PG_VERSION=$(psql --version | head -n 1)
log "Установлена версия: $PG_VERSION"

# Создание базы данных (если не существует)
log "Создание базы данных $DB_NAME..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" >> "$LOG_FILE" 2>&1 || log "База данных $DB_NAME уже существует."

# Создание пользователя (если не существует)
log "Создание пользователя $DB_USER..."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';" >> "$LOG_FILE" 2>&1 || log "Пользователь $DB_USER уже существует."

# Назначение прав
log "Назначение прав для $DB_USER на $DB_NAME..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" >> "$LOG_FILE" 2>&1

log "Установка и настройка PostgreSQL завершены успешно!"
exit 0