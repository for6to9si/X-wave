# X-wave
X-wave — это легковесная надстройка, которая автоматизирует установку и настройку Xray на роутерах семейства Keenetic.


```bash
# Обновление списка пакетов
opkg update

# Обновление установленных пакетов
opkg upgrade

# Установка wget с поддержкой SSL
opkg install wget-ssl
opkg install ca-certificates

# Загрузка Xray пакета с GitHub
opkg install https://github.com/for6to9si/X-wave/releases/download/v25.10.15/xray_25.10.15_mips32le.ipk

# Обновление базы данных Xray
/opt/etc/init.d/S98xray database_up

# Запуск службы Xray
/opt/etc/init.d/S98xray start

# Остановка службы Xray
/opt/etc/init.d/S98xray stop