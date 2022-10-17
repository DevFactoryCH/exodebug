#!/bin/sh

role=${CONTAINER_ROLE:-app}

if [ "$role" = "app" ]; then
    echo " [-] Container running as app"
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
elif [ "$role" = "queue" ]; then
    echo " [-] Container running as queue worker"
    php /var/www/html/artisan horizon
elif [ "$role" = "scheduler" ]; then
    echo " [-] Migrate DB"
    php artisan app:install
    echo " [-] Container running as scheduler"
    while [ true ]
    do
      php /var/www/html/artisan schedule:run --verbose --no-interaction &
      sleep 60
    done
else
    echo " [X] Could not match the container role \"$role\""
    exit 1
fi
