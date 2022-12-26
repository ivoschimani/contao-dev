#!/bin/sh
sed -i -e 's,##NGINX_HOST##,'"$NGINX_HOST"',g' "/etc/nginx/nginx.conf"

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
