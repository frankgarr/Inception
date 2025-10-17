#!/bin/sh 

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

required_env_vars="NGINX_PORT MARIADB_PORT WORDPRESS_PORT REDIS_PORT ADMINER_PORT VSFTPD_PORT"

check_env()
{
    missing=0
    for env in $required_env_vars; do 
        eval value=\$$env
        if [ -z "$value" ]; then
            echo "[ERROR] $env is missing aborting process"
            exit 1
        fi
    done
    echo "All env variables are set!"
}

check_service()
{
    name=$1
    host=$2
    port=$3
    
    if nc -z -w2 "$host" "$port" 2>/dev/null; then
        echo "${GREEN}✓ $name: OK${NC}"
        return 0
    else
        echo "${RED}✗ $name: DOWN${NC}"
        return 1
    fi
}

update_html_status()
{
    name=$1
    status=$2
    file=$3
    
    # Usar sed para actualizar solo la línea del servicio
    if [ "$status" = "up" ]; then
        sed -i "s|<h2> $name : .* </h2>|<h2> $name : ${GREEN}OK!${NC} </h2>|" "$file"
    else
        sed -i "s|<h2> $name : .* </h2>|<h2> $name : ${RED}DOWN!${NC} </h2>|" "$file"
    fi
}

generate_html()
{
    file=$1
    cat << EOF > $file
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .up { color: green; }
        .down { color: red; }
        .waiting { color: orange; }
    </style>
</head>
<body>
    <h1>Status of the services</h1>
    <h2>Nginx : <span class="waiting">Checking...</span></h2>
    <h2>MariaDb : <span class="waiting">Checking...</span></h2>
    <h2>Wordpress : <span class="waiting">Checking...</span></h2>
    <h2>Redis : <span class="waiting">Checking...</span></h2>
    <h2>Ftp Server : <span class="waiting">Checking...</span></h2>
    <h2>Adminer : <span class="waiting">Checking...</span></h2>
</body>
</html>
EOF
}

monitor_services()
{
    file="/var/www/html/health/index.html"
    check_env
    mkdir -p /var/www/html/health
    
    # Generar HTML inicial
    generate_html "$file"
    
    echo "Starting health monitoring service..."
    echo "Healthcheck available at: http://localhost:$HEALTH_PORT/health/"
    
    # Loop infinito de monitorización
    while true; do
        # Actualizar timestamp
        sed -i "s|<!-- Last update: .* -->|<!-- Last update: $(date) -->|" "$file"
        
        # Verificar cada servicio
        check_service "Nginx" "nginx" "$NGINX_PORT" && \
            sed -i "s|Nginx :.*|Nginx : <span class=\"up\">OK!</span>|" "$file" || \
            sed -i "s|Nginx :.*|Nginx : <span class=\"down\">DOWN!</span>|" "$file"
        
        check_service "MariaDb" "mariadb" "$MARIADB_PORT" && \
            sed -i "s|MariaDb :.*|MariaDb : <span class=\"up\">OK!</span>|" "$file" || \
            sed -i "s|MariaDb :.*|MariaDb : <span class=\"down\">DOWN!</span>|" "$file"
        
        check_service "Wordpress" "wordpress" "$WORDPRESS_PORT" && \
            sed -i "s|Wordpress :.*|Wordpress : <span class=\"up\">OK!</span>|" "$file" || \
            sed -i "s|Wordpress :.*|Wordpress : <span class=\"down\">DOWN!</span>|" "$file"
        
        check_service "Redis" "redis" "$REDIS_PORT" && \
            sed -i "s|Redis :.*|Redis : <span class=\"up\">OK!</span>|" "$file" || \
            sed -i "s|Redis :.*|Redis : <span class=\"down\">DOWN!</span>|" "$file"
        
        check_service "Ftp Server" "vsftpd" "$VSFTPD_PORT" && \
            sed -i "s|Ftp Server :.*|Ftp Server : <span class=\"up\">OK!</span>|" "$file" || \
            sed -i "s|Ftp Server :.*|Ftp Server : <span class=\"down\">DOWN!</span>|" "$file"
        
        check_service "Adminer" "adminer" "$ADMINER_PORT" && \
            sed -i "s|Adminer :.*|Adminer : <span class=\"up\">OK!</span>|" "$file" || \
            sed -i "s|Adminer :.*|Adminer : <span class=\"down\">DOWN!</span>|" "$file"
        
        # Esperar antes de la siguiente verificación
        sleep 5
    done
}

monitor_services
