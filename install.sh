#!/bin/bash
# Installer KING•VPN - HTTPS y logs visibles

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

# Comprobamos root
if [ "$EUID" -ne 0 ]; then
    error_exit "EJECUTE COMO ROOT"
fi

clear
show_progress "Actualizando repositorio..."
export DEBIAN_FRONTEND=noninteractive
apt update -y || error_exit "Falla al actualizar el repositorio"
increment_step

# Verificación de sistema
show_progress "Verificando el sistema..."
if ! command -v lsb_release &> /dev/null; then
    apt install lsb-release -y || error_exit "Falla al instalar lsb-release"
fi
increment_step

OS_NAME=$(lsb_release -is)
VERSION=$(lsb_release -rs)

case $OS_NAME in
    Ubuntu)
        case $VERSION in
            24.*|22.*|20.*)
                show_progress "Sistema Ubuntu soportado, continuando..."
                ;;
            *)
                error_exit "Version de Ubuntu no soportado. Use 20, 22 o 24."
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

# Actualizar sistema e instalar dependencias
show_progress "Actualizando sistema e instalando dependencias..."
apt upgrade -y || error_exit "Falla al actualizar el sistema"
apt install wget git -y || error_exit "Falla al instalar paquetes"
increment_step

# Crear directorio
show_progress "Creando directorio /opt/kingvpn..."
mkdir -p /opt/kingvpn || error_exit "Falla al crear el directorio"
increment_step

# Instalar Node.js vía NVM
show_progress "Instalando Node.js 18..."
bash <(wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh) || error_exit "Falla al instalar NVM"
[ -s "/root/.nvm/nvm.sh" ] && \. "/root/.nvm/nvm.sh" || error_exit "Falla al cargar NVM"
nvm install 18 || error_exit "Falla al instalar Node.js"
increment_step

# Clonar KINGVPN desde HTTPS
show_progress "Clonando KING•VPN desde HTTPS..."
if [ -d "/root/KINGVPN" ]; then
    echo "Directorio /root/KINGVPN ya existe, eliminando..."
    rm -rf /root/KINGVPN
fi

git clone --branch main https://github.com/interking000/kingvpn.git /root/KINGVPN || error_exit "Falla al clonar el panel KING•VPN"
increment_step

# Mover menú
mv /root/KINGVPN/menu /opt/kingvpn/menu || error_exit "Falla al mover el menu"

# Entrar al directorio y preparar Node.js
cd /root/KINGVPN || error_exit "Falla al entrar al directorio KINGVPN"
npm install -g typescript || error_exit "Falla al instalar TypeScript"
npm install --force || error_exit "Falla al instalar paquetes de KING•VPN"

# Mover archivos a /opt/kingvpn
mv /root/KINGVPN/* /opt/kingvpn/ || error_exit "Falla al mover archivos de KINGVPN"
increment_step

# Configurar permisos
show_progress "Configurando permisos..."
chmod +x /opt/kingvpn/menu || error_exit "Falla al configurar permisos"
ln -sf /opt/kingvpn/menu /usr/local/bin/menu || error_exit "Falla al crear link simbólico"
increment_step

# Limpieza
show_progress "Limpiando directorios temporarios..."
rm -rf /root/KINGVPN/ || error_exit "Falla al limpiar directorio temporario"
increment_step

echo "Instalación completada con éxito. Digite 'menu' para acceder al panel."
