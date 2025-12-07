#!/bin/bash
# Installer KING•VPN - Corregido

TOTAL_STEPS=8
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
fi

clear
show_progress "Actualizando repositorio de paquetes..."
export DEBIAN_FRONTEND=noninteractive
apt update -y >/dev/null 2>&1 || error_exit "Falla al actualizar repositorio"
increment_step

show_progress "Verificando sistema y dependencias..."
apt install -y lsb-release wget git curl >/dev/null 2>&1 || error_exit "Falla al instalar paquetes"
OS_NAME=$(lsb_release -is)
VERSION=$(lsb_release -rs)
increment_step

# Validar OS soportado
case $OS_NAME in
    Ubuntu)
        [[ "$VERSION" =~ ^(20|22|24) ]] || error_exit "Versión de Ubuntu no soportada (20,22,24)"
        ;;
    Debian)
        [[ "$VERSION" =~ ^(11|12) ]] || error_exit "Versión de Debian no soportada (11,12)"
        ;;
    *)
        error_exit "Sistema no soportado. Use Ubuntu o Debian"
        ;;
esac
show_progress "Sistema soportado, continuando..."
increment_step

show_progress "Creando directorio de instalación..."
mkdir -p /opt/kingvpn || error_exit "Falla al crear /opt/kingvpn"
increment_step

show_progress "Instalando Node.js 18 con NVM..."
bash <(wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh) >/dev/null 2>&1 || error_exit "Falla al instalar NVM"
[ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"
nvm install 18 >/dev/null 2>&1 || error_exit "Falla al instalar Node.js"
increment_step

show_progress "Clonando KING•VPN..."
# Usar SSH si tu VPS tiene key; si no, usa HTTPS
GIT_URL="git@github.com:interking000/kingvpn.git"
git clone --branch main "$GIT_URL" /root/KINGVPN || error_exit "Falla al clonar el panel KING•VPN"
increment_step

show_progress "Instalando dependencias y moviendo archivos..."
cd /root/KINGVPN || error_exit "Falla al entrar al directorio /root/KINGVPN"
npm install -g typescript >/dev/null 2>&1 || error_exit "Falla al instalar TypeScript"
npm install --force >/dev/null 2>&1 || error_exit "Falla al instalar paquetes de KING•VPN"
mv /root/KINGVPN/* /opt/kingvpn/ || error_exit "Falla al mover archivos de KINGVPN"
increment_step

show_progress "Configurando permisos y link al menú..."
chmod +x /opt/kingvpn/menu || error_exit "Falla al configurar permisos"
ln -sf /opt/kingvpn/menu /usr/local/bin/menu || error_exit "Falla al crear link simbólico"
increment_step

show_progress "Limpieza de directorios temporales..."
rm -rf /root/KINGVPN
increment_step

echo "Instalación completada con éxito. Ejecuta 'menu' para iniciar KING•VPN."
