#!/bin/bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'


print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[PASO]${NC} $1"
}

# Verificar si el script se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
}

# Actualizar los paquetes del sistema
actualizar_sistema(){
    print_step "Actualizando sistema..."
    apt update -y
    apt upgrade -y
    print_message "Sistema actualizado correctamente"
}

setup_repository(){
    print_step "Agregando repositorio de Koha"

    if [ ! -f /etc/apt/sources.list.d/koha.list ]; then
        wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -

        echo "deb https://debian.koha-community.org/koha stable main" | tee /etc/apt/sources.list.d/koha.list

        print_message "repositorio de koha agregado"
    else
        print_message "repositorio de koha ya existe"
    
    fi

    apt update -y
}

# Instalacion de koha
instalacion_koha() {
    print_step "Instalando Koha y dependencias Perl..."
    
    # Instalar Koha
    apt install -y koha-common
    
    # Verificar si faltan módulos Perl críticos
    print_step "Verificando módulos Perl necesarios..."
    
    # Lista de módulos Perl críticos para Koha
    PERL_MODULES="DBI DBD::mysql XML::LibXML MARC::Record Template::Toolkit CGI::Session Date::Calc"
    
    for module in $PERL_MODULES; do
        if ! perl -M$module -e 1 2>/dev/null; then
            print_warning "Instalando módulo Perl faltante: $module"
            cpan -i $module &>/dev/null || true
        fi
    done

    koha-translate --install es-ES
    
    print_message "Koha instalado correctamente"
}

# configuracion de archivo de puertos de koha
configurar_puertos(){
    print_step "Configurando puertos para koha..."
    cat > /etc/koha/koha-sites.conf << 'EOF'
#configuracion de sitios de koha
DOMAIN=".myDNSname.org"
INTRAPORT="8080"
INTRAPREFIX=""
INTRASUFFIX="-intra"
OPACPORT="80"
OPACPREFIX=""
OPACSUFFIX=""
DEFAULTSQL=""
ZEBRA_MARC_FORMAT="marc21"
ZEBRA_LANGUAGE="en"
USE_MEMCACHED="yes"
MEMCACHED_SERVERS="127.0.0.1:11211"
MEMCACHED_PREFIX="koha_"
EOF
    print_message "Puertos configurados."
}


# configurar sitios en apache

configurar_apache(){
    print_step "configurando modulos de apache..."
    a2enmod rewrite
    a2enmod cgi
    a2enmod headers
    systemctl restart apache2
    print_message "modulos configurados"
}

# creando base de datos de koha
crear_db(){
    print_step "creando base de datos de koha..."

    koha-create --create-db biblioteca
    a2enmod deflate
    a2ensite biblioteca
    systemctl restart apache2

    print_message "base de datos creada exitosamente"
}

# Copiar las imagenes a las carpetas necesarias
copiar_imagenes(){
    print_step "Copiando imagenes personalizadas..."
    
    # Verificar que exista el directorio de imagenes
    if [ ! -d "./imagenes" ]; then
        print_error "El directorio './imagenes' no existe"
        return 1
    fi
    
    # Verificar que existan los archivos
    if [ ! -f "./imagenes/logo_farusac.jpeg" ]; then
        print_warning "Archivo logo_farusac.jpeg no encontrado"
    else
        cp ./imagenes/logo_farusac.jpeg /usr/share/koha/opac/htdocs/opac-tmpl/bootstrap/images/logo_farusac.png
        cp ./imagenes/logo_farusac.jpeg /usr/share/koha/intranet/htdocs/intranet-tmpl/prog/img/logo_farusac.jpeg
    fi
    
    if [ ! -f "./imagenes/farusac.png" ]; then
        print_warning "Archivo farusac.png no encontrado"
    else
        cp ./imagenes/farusac.png /usr/share/koha/opac/htdocs/opac-tmpl/bootstrap/images/escudo.ico
        cp ./imagenes/farusac.png /usr/share/koha/intranet/htdocs/intranet-tmpl/prog/img/escudo.ico
    fi
    
    print_message "Imagenes copiadas correctamente"
}


main(){
    print_message "Iniciando instalacion de koha..."
    check_root
    actualizar_sistema
    setup_repository
    instalacion_koha
    configurar_puertos
    configurar_apache
    crear_db
    copiar_imagenes

    print_message "Instalacion de koha completada"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi