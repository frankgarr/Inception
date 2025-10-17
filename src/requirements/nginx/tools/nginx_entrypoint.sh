#!/bin/sh

set -e

add_group()
{
    group=$1
    user=$2
    dir=$3

    if ! getent group "$group" > /dev/null 2>&1; then
        addgroup -S $group;
    fi
    if ! getent passwd "$user" > /dev/null 2>&1; then
        adduser -S -D -H -s /sbin/nologin -g $group $user;
    fi
    chown -R $user:$group $dir
}

generate_ssl_cert()
{
    echo "Generating SSL certification"
    mkdir -p ${SSL_PATH} > /dev/null
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout ${SSL_PATH}/${DOMAIN_NAME}.key \
        -out    ${SSL_PATH}/${DOMAIN_NAME}.crt \
        -subj "/C=ES/ST=Catalonia/L=Barcelona/O=42Barcelona/OU=42 School/CN=${DOMAIN_NAME}" \
        > /dev/null 2>&1
    echo "SSL Certification Generated!"
}

check_bonus_services()
{
    # Usar variable de entorno si está disponible
    if [ "$MODE" = "bonus" ]; then
        echo "Bonus mode detected via environment variable - using bonus configuration"
        TEMPLATE_FILE="/nginx_bonus.cnf.template"
    else
        if nc -z -w5 adminer 8080 2>/dev/null; then
            echo "Bonus services detected - using bonus configuration"
            TEMPLATE_FILE="/nginx_bonus.cnf.template"
        else
            echo "Mandatory mode - using basic configuration"
            TEMPLATE_FILE="/nginx.cnf.template"
        fi
    fi
}

start_templates()
{
    echo "Applying templates configuration"
    
    # Determinar qué configuración usar
    check_bonus_services
    
    # Aplicar la plantilla correcta
    envsubst '${NGINX_PORT} ${DOMAIN_NAME} ${SSL_PATH} ${NGINX_BDIR}' < "$TEMPLATE_FILE" > /etc/nginx/nginx.conf
    
    echo "Configuration Complete! Starting Nginx..."
}

init_nginx()
{
    add_group "nginx" "nginx" "/var/www/html"
    generate_ssl_cert
    start_templates
    echo "Entrypoint completed, executing: $@"
    exec "$@"
}

if [ "$1" = "nginx" ]; then
    init_nginx "$@"
else
    exec "$@"
fi
