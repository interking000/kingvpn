#!/bin/bash
# Installer KING•VPN - actualizado para HTTPS

TOTAL_STEPS=9
CURRENT_STEP=0

show_progress() {
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo "Progreso: [${PERCENT}%] - $1"
}

error_exit() {
    echo -e "\nError: $1"
    exit 1
}

increment_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
}

if [ "$EUID" -ne 0 ]; then
    error_exit "EJECUTE COMO ROOT"
else
    clear
    show_progress "Actualizando repositorio de paquetes..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null 2>&1 || error_exit "Falla al actualizar el repositorio"
    increment_step

    # Verificación del sistema
    show_progress "Verificando sistema y dependencias..."
    if ! command -v lsb_release &> /dev/null; then
        apt install lsb-release -y >/dev/null 2>&1 || error_exit "Falla al instalar lsb-release"
    fi
    increment_step

    OS_NAME=$(lsb_release -is)
    VERSION=$(lsb_release -rs)

    case $OS_NAME in
        Ubuntu)
            case $VERSION in
                20.*|22.*|24.*)
                    show_progress "Sistema soportado, continuando..."
                    ;;
                *)
                    error_exit "Version de Ubuntu no soportado"
                    ;;
            esac
            ;;
        Debian)
            case $VERSION in
                11*|12*)
                    show_progress "Sistema soportado, continuando..."
                    ;;
                *)
                    error_exit "Version de Debian no soportado"
                    ;;
            esac
            ;;
        *)
            error_exit "Sistema no soportado. Use Ubuntu o Debian."
            ;;
    esac
    increment_step

    # Instalación de paquetes y actualización
    show_progress "Actualizando sistema e instalando dependencias..."
    apt upgrade -y >/dev/null 2>&1 || error_exit "Falla al actualizar sistema"
    apt install wget git -y >/dev/null 2>&1 || error_exit "Falla al instalar paquetes"
    increment_step

    # Crear directorio
    show_progress "Creando directorio /opt/kingvpn..."
    mkdir -p /opt/kingvpn >/dev/null 2>&1 || error_exit "Falla al crear directorio"
    increment_step

    # Instalar Node.js con NVM
    show_progress "Instalando Node.js 18 con NVM..."
    bash <(wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh) >/dev/null 2>&1 || error_exit "Falla al instalar NVM"
    [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh" || error_exit "Falla al cargar NVM"
    nvm install 18 >/dev/null 2>&1 || error_exit "Falla al instalar Node.js"
    increment_step

    # Clonar KINGVPN usando HTTPS
    show_progress "Clonando KING•VPN..."
    [ -d "/root/KINGVPN" ] && rm -rf /root/KINGVPN
    git clone --branch main https://github.com/interking000/kingvpn.git /root/KINGVPN >/dev/null 2>&1 || error_exit "Falla al clonar KINGVPN"

    # Mover menú
    mv /root/KINGVPN/menu /opt/kingvpn/menu || error_exit "Falla al mover menu"

    # Entrar al repositorio
    cd /root/KINGVPN || error_exit "Falla al entrar al directorio KINGVPN"

    # Instalar TypeScript y dependencias Node
    npm install -g typescript >/dev/null 2>&1 || error_exit "Falla al instalar TypeScript"
    npm install --force >/dev/null 2>&1 || error_exit "Falla al instalar dependencias KINGVPN"

    # Mover todos los archivos al directorio final
    mv /root/KINGVPN/* /opt/kingvpn/ || error_exit "Falla al mover archivos al directorio final"
    increment_step

    # Configurar permisos
    show_progress "Configurando permisos..."
    chmod +x /opt/kingvpn/menu || error_exit "Falla al configurar permisos"
    ln -sf /opt/kingvpn/menu /usr/local/bin/menu || error_exit "Falla al crear link simbólico"
    increment_step

    # Limpieza
    show_progress "Limpiando archivos temporales..."
    rm -rf /root/KINGVPN >/dev/null 2>&1 || error_exit "Falla al limpiar directorio temporal"
    increment_step

    echo "Instalación completada con éxito. Digite 'menu' para acceder al panel."
fi
