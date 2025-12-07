#!/bin/bash
# Installer KING•VPN

TOTAL_STEPS=9
CURRENT_STEP=0

show_progress() {
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo "Progreso: [${PERCENT}%] - $1"
}

error_exit() {
    echo -e "\nError: $1"
    exit 0
}

increment_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
}

if [ "$EUID" -ne 0 ]; then
    error_exit "EJECUTE COMO ROOT"
else
    clear
    show_progress "Actualizando repositorio..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null 2>&1 || error_exit "Falla al actualizar el repositorio"
    increment_step

    # ---->>>> Verificación del sistema
    show_progress "Verificando el sistema..."
    if ! command -v lsb_release &> /dev/null; then
        apt install lsb-release -y >/dev/null 2>&1 || error_exit "Falla al instalar lsb-release"
    fi
    increment_step

    # ---->>>> Verificación del sistema
    OS_NAME=$(lsb_release -is)
    VERSION=$(lsb_release -rs)

    case $OS_NAME in
        Ubuntu)
            case $VERSION in
                24.*|22.*|20.*)
                    show_progress "Sistema Ubuntu soportado, continuando..."
                    ;;
                *)
                    error_exit "Version de Ubuntu no soportado. Use 20, 22 ou 24."
                    ;;
            esac
            ;;
        Debian)
            case $VERSION in
                12*|11*)
                    show_progress "Sistema Debian soportado, continuando..."
                    ;;
                *)
                    error_exit "Version de Debian no soportado. 11 o 12."
                    ;;
            esac
            ;;
        *)
            error_exit "Sistema no soportado. use Ubuntu o Debian."
            ;;
    esac
    increment_step

    # ---->>>> Instalacion de paquetes requisito y actualización del sistema
    show_progress "Actualizando el sistema..."
    apt upgrade -y >/dev/null 2>&1 || error_exit "Falla al actualizar el sistema"
    apt-get install wget git -y >/dev/null 2>&1 || error_exit "Falla al instalar paquetes"
    increment_step

    # ---->>>> Creando el directorio del script
    show_progress "Creando directorio /opt/kingvpn..."
    mkdir -p /opt/kingvpn >/dev/null 2>&1 || error_exit "Falla al crear el directorio"
    increment_step

    # ---->>>> Instalar Node.js
    show_progress "Instalando Node.js 18..."
    bash <(wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh) >/dev/null 2>&1 || error_exit "Falla al instalar NVM"
    [ -s "/root/.nvm/nvm.sh" ] && \. "/root/.nvm/nvm.sh" || error_exit "Falla al cargar NVM"
    nvm install 18 >/dev/null 2>&1 || error_exit "Falla al instalar Node.js"

    increment_step

    # ---->>>> Instalar el KINGVPN Painel
    show_progress "Instalando KING•VPN, la demora dependera de la capacidad de tu vps..."
    git clone --branch "main" https://github.com/interking000/kingvpn.git /root/KINGVPN >/dev/null 2>&1 || error_exit "Falla al clonar el panel KING•VPN"
    mv /root/KINGVPN/menu /opt/kingvpn/menu || error_exit "Falla al mover el menu"
    cd /root/KINGVPN/KINGVPN/ || error_exit "Falla al entrar al directorio king"
    npm install -g typescript >/dev/null 2>&1 || error_exit "Falla al instalar TypeScript"
    npm install --force >/dev/null 2>&1 || error_exit "Falla al instalar paquetes de KING•VPN"
    
    mv /root/KINGVPN/KINGVPN/* /opt/kingvpn/ || error_exit "Falla al mover archivos de KINGVPN"
    increment_step

    # ---->>>> Configuración de permisos
    show_progress "Configurando Permisos..."
    chmod +x /opt/kingvpn/menu || error_exit "Falla al configurar permisos"
    ln -sf /opt/kingvpn/menu /usr/local/bin/menu || error_exit "Falla al crear link simbólico"
    increment_step

    # ---->>>> Limpieza
    show_progress "Limpiando directorios temporario..."
    rm -rf /root/KINGVPN/ || error_exit "Falla al limpiar directorio temporario"
    increment_step

    # ---->>>> Instalacion finalizada :)
    echo "Instalacion completada con exito. Digite 'menu' para acceder al menu."
fi
