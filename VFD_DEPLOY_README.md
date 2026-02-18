# Развёртывание VFD скриптов без пересборки

## Проблема

EmuELEC использует squashfs — **readonly filesystem**. Обычно нельзя просто заменить файл в `/usr/lib/emuelec/`.

## Решение: bind mount через /storage

`/storage/` — единственная RW область. Скрипт `DEPLOY_VFD_SCRIPTS.sh` делает следующее:

1. Копирует обновлённые скрипты в `/storage/.vfd-scripts/`
2. Делает `mount --bind` поверх readonly файлов в `/usr/lib/emuelec/`
3. Перезапускает VFD сервис

## Использование

### 1. Подключиться к приставке по SSH

Узнай IP приставки (в настройках сети ES или `ip addr` на приставке).

Логин по умолчанию: `root` (без пароля, либо `emuelec`).

```bash
ssh root@192.168.1.XXX
```

### 2. Запустить deploy скрипт

На хосте (MacBook):

```bash
cd ~/Prog/EmuELEC-RK3566
./DEPLOY_VFD_SCRIPTS.sh root@192.168.1.XXX
```

Скрипт автоматически:

- Скопирует все `vfd-*.sh` в `/storage/.vfd-scripts/`
- Сделает bind mount поверх readonly файлов
- Перезапустит `vfd-x96x6.service`

### 3. Проверить статус

На приставке:

```bash
systemctl status vfd-x96x6.service
journalctl -u vfd-x96x6 -f
```

Посмотреть что на экране VFD:

- Должны быть часы HH:MM с двоеточием
- WiFi иконка горит при подключении
- USB/Card иконки обновляются автоматически

### 4. Отменить изменения (вернуть оригинал)

```bash
ssh root@192.168.1.XXX 'systemctl stop vfd-x96x6; reboot'
```

После ребута bind mounts исчезнут, вернутся оригинальные скрипты из образа.

## Архитектура v2 (FIFO-based)

### Принцип работы

Все операции с дисплеем идут через именованный канал (FIFO) `/tmp/vfd.fifo`.
**НИ ОДНА** операция с дисплеем не блокирует другие процессы.

```
  vfd-clock-updater.sh ──┐
  vfd-state-monitor.sh ──┼──> /tmp/vfd.fifo ──> vfd-service.sh ──> GPIO ──> FD628
  vfd-send (CLI) ────────┘
```

### Компоненты

| Файл | Роль |
|------|------|
| `vfd-service.sh` | Главный сервис — читает FIFO, единственный владелец GPIO |
| `vfd-clock-updater.sh` | Независимый процесс часов — обновление точно при смене минуты |
| `vfd-state-monitor.sh` | Мониторинг ES/игр (каждые 2с), авто-иконки (каждые 30с) |
| `vfd-send` | CLI утилита для отправки команд (мгновенный возврат) |
| `vfd-fd628.sh` | Библиотека GPIO управления FD628 |
| `vfd-boot-anim.sh` | Анимация загрузки (циклическая) |
| `vfd-bye.sh` | Отображение BYE при выключении с затуханием |
| `vfd-timezone-setup.sh` | Одноразовая настройка часового пояса по IP |

### Команды FIFO

```bash
vfd-send clock 12 30        # Показать время
vfd-send text GAME           # Показать текст (4 символа)
vfd-send icon wifi on        # Включить иконку
vfd-send icon usb off        # Выключить иконку
vfd-send anim start          # Запустить анимацию загрузки
vfd-send anim stop           # Остановить анимацию, показать часы
vfd-send brightness 5        # Яркость (0-7)
vfd-send clear               # Очистить дисплей
vfd-send bye                 # Последовательность выключения
```

### Ключевые решения

- **FIFO буфер 64KB** — запись ~30 байт мгновенна, никогда не блокирует отправителя
- **exec 3<>/tmp/vfd.fifo** — предотвращает EOF при отключении отправителей
- **KillMode=process** — только главный процесс получает SIGTERM, cleanup handler останавливает дочерние
- **Часы с привязкой к минуте** — `sleep $((60 - секунда))`, обновление точно при смене минуты
- **Иконки обновляются ВСЕГДА** — даже во время анимации (состояние сохраняется, применяется при следующем отображении)
- **GPIO эксклюзивность** — только vfd-service.sh + его дочерний vfd-boot-anim.sh пишут в GPIO, никогда одновременно

## Альтернативный способ (ручной)

```bash
ssh root@192.168.1.XXX
mkdir -p /storage/.vfd-scripts

# Скопировать скрипт и mount
mount --bind /storage/.vfd-scripts/vfd-service.sh /usr/lib/emuelec/vfd-service.sh
systemctl restart vfd-x96x6.service
```

## Debug

```bash
# Логи в реальном времени
journalctl -u vfd-x96x6 -f

# Проверить что процессы запущены
ps aux | grep vfd

# Проверить FIFO
ls -la /tmp/vfd.fifo

# Отправить тестовую команду
vfd-send text TEST

# Проверить bind mounts
mount | grep vfd

# CPU загрузка
top -b -n 1 | head -20
```
