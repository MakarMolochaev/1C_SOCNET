# Используем базовый образ Ubuntu (или другой подходящий дистрибутив)
FROM ubuntu:20.04

# Установка зависимостей
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
    wget \
    gnupg2 \
    libgsf-1-114 \
    libenchant1c2a \
    libwebkitgtk-3.0-0 \
    libgtk2.0-0 \
    unixodbc \
    ttf-mscorefonts-installer \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    && rm -rf /var/lib/apt/lists/*

# Добавляем репозиторий 1С (если у вас есть доступ)
# RUN wget -qO - http://deb.1c.ru/1C_public.key | apt-key add - \
#     && echo "deb http://deb.1c.ru/ubuntu/20.04 stable main" > /etc/apt/sources.list.d/1c.list \
#     && apt-get update

# Вместо установки из репозитория копируем локальные пакеты 1С
COPY ./1c-enterprise*.deb /tmp/
RUN dpkg -i /tmp/1c-enterprise*.deb || apt-get install -f -y

# Настройка сервера 1С
RUN mkdir -p /var/1C/db /var/1C/logs && \
    chmod -R 777 /var/1C

# Копируем конфигурацию кластера и информационную базу
COPY ./cluster.cfg /opt/1C/v8.3/x86_64/conf/
COPY ./ib /var/1C/db/

# Устанавливаем переменные окружения
ENV CLUSTER_ADMIN=admin
ENV CLUSTER_PWD=password
ENV CLUSTER_IB=MyIB
ENV CLUSTER_DB_USER=db_user
ENV CLUSTER_DB_PWD=db_password
ENV CLUSTER_DB_SERVER=db_server

# Создаем скрипт для запуска сервера 1С
RUN echo '#!/bin/bash\n\
/opt/1C/v8.3/x86_64/ras --daemon cluster\n\
/opt/1C/v8.3/x86_64/ragent --daemon\n\
/opt/1C/v8.3/x86_64/1cv8s -d /var/1C/db -p 8080\n\
tail -f /dev/null' > /usr/local/bin/start-1c.sh && \
    chmod +x /usr/local/bin/start-1c.sh

# Открываем порты
EXPOSE 1540-1541 1560-1591 8080

# Запускаем сервер 1С
CMD ["/usr/local/bin/start-1c.sh"]