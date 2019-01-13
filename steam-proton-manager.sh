#!/bin/bash

STEAM_DIR=~/.steam/root
SYSTEM_PREFIX=/usr

SYSTEM_DEPLOY_DIR="${SYSTEM_PREFIX}"/share/steam-proton
LIBERATION_FONT_DIR="${SYSTEM_PREFIX}"/share/fonts/liberation-fonts
COMPAT_DIR="${STEAM_DIR}/compatibilitytools.d"

VERSION_LIST=$(ls -1 "${SYSTEM_DEPLOY_DIR}")
WINE_LIST=$(ls -1 "${SYSTEM_DEPLOY_DIR}/include/wine-*" | sed 's/wine-//')
VERSION=$("${VERSION_LIST}" | tail -n1)
WINE_VERSION="proton"

PROTON_DIR="${COMPAT_DIR}/${VERSION}"
PROTON_PREFIX="${PROTON_DIR}/share/default_pfx"

usage() {
	echo "usage: steam-proton-manager [options] [action] [version]"
	echo "  options:"
	echo "    -l  --list         List available versions of proton"
	echo "    -h  --help         Print this help message"
	echo "    -w  --wine         Specify the wine suffix to use"
	echo "  actions:"
	echo "    install            Install proton to the steam directory of the current user"
	echo "    remove             Remove proton from the steam directory of the current user"
	echo "  version:"
	echo "    Specify a version to operate on. If none specified, use the latest"
}

update_vars() {
	PROTON_DIR="${COMPAT_DIR}/${VERSION}"
	PROTON_PREFIX="${PROTON_DIR}/share/default_pfx"
}

check_system_install() {
	if [ ! -d "${SYSTEM_DEPLOY_DIR}" ]; then
		echo >&2 "!! ${SYSTEM_DEPLOY_DIR} does not exist, no versions available"
		return 1
	fi
}

list_versions() {
	check_system_install
	echo "Available versions:"
	echo "${VERSION_LIST}"
}

check_version() {
	echo "${VERSION_LIST}" | grep --quiet "${VERSION}"
}

check_wine() {
	echo "${WINE_LIST}" | grep --quiet "wine-${WINE_VERSION}"
}

patch_proton() {
	sed -i -e "s/WINE_REPLACE_STRING/${WINE_VERSION}/" "${PROTON_DIR}/Proton"
}

install() {
	if [ ! -d "${STEAM_DIR}" ]; then
		echo >&2 "!! ${STEAM_DIR} does not exist, cannot install"
		return 1
	fi
	mkdir -p "${PROTON_DIR}"
	cp -ar "${SYSTEM_DEPLOY_DIR}/${VERSION}/*" "${PROTON_DIR}"
	mkdir -p "${PROTON_PREFIX}"
	WINEPREFIX="${PROTON_PREFIX}" wineboot-"${WINE_VERSION}" && \
		WINEPREFIX="${PROTON_PREFIX}" wineserver="${WINE_VERSION}" -w && \
		ln -s "${LIBERATION_FONT_DIR}"/LiberationSans-Regular.ttf "${PROTON_PREFIX}"/drive_c/windows/Fonts/arial.ttf && \
		ln -s "${LIBERATION_FONT_DIR}"/LiberationSans-Bold.ttf "${PROTON_PREFIX}"/drive_c/windows/Fonts/arialbd.ttf && \
		ln -s "${LIBERATION_FONT_DIR}"/LiberationSerif-Regular.ttf "${PROTON_PREFIX}"/drive_c/windows/Fonts/times.ttf && \
		ln -s "${LIBERATION_FONT_DIR}"/LiberationMono-Regular.ttf "${PROTON_PREFIX}"/drive_c/windows/Fonts/cour.ttf && \
		WINEPREFIX="${PROTON_PREFIX}" /usr/lib32/dxvk/bin/setup_dxvk.sh && \
		WINEPREFIX="${PROTON_PREFIX}" /usr/lib64/dxvk/bin/setup_dxvk.sh
	echo "Installed Proton to ${PROTON_DIR} using wine-${WINE_VERSION}"
	echo "You may need to restart Steam to select this tool"
}

remove() {
	if [ ! -d "${PROTON_DIR}" ]; then
		echo >&2 "!! No existing install found at ${PROTON_DIR}"
		return 1
	fi
	rm -rf "${PROTON_DIR}"
	echo "Removed proton install at ${PROTON_DIR}"
	echo "You may need to restart Steam update the available tools"
}

for opt in "$@"; do
	if ! [ -z "${WINE_CHECK}" ]; then
		WINE_VERSION="${opt}"
		check_wine || echo >&2 "!! Wine version wine-${WINE_VERSION} not found"; exit 1
		WINE_CHECK=""
	elif [ "${opt}" = "-h" ] || [ "${opt}" = "--help" ]; then
		usage
		exit 0
	elif [ "${opt}" = "-l" ] || [ "${opt}" = "--list" ]; then
		list_versions
		exit 0
	elif [ "${opt}" = "-w" ] || [ "${opt}" = "--wine" ]; then
		WINE_CHECK=1
	fi
done

for opt in "$@"; do
	if [ "${opt}" = "install" ]; then
		ACTION=1
	elif [ "${opt}" = "remove" ]; then
		ACTION=2
	elif ! [ -z "${ACTION}" ] && [ -z "${opt}" ]; then
		VERSION="${opt}"
		check_version || echo >&2 "!! Version ${VERSION} not found"; exit 1
		update_vars
	fi
done

if [ "${ACTION}" = 1 ]; then
	install
	exit 0
elif [ "${ACTION}" = 2 ]; then
	remove
	exit 0
else
	echo >&2 "error: Please specify an action"
	exit 1
fi

