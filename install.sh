#!/bin/bash

# kill
wineserver -k 
killall -9 wine wineserver 

#set up files
mkdir -p tmp
curl -LO https://github.com/relativemodder/aegnux/releases/download/vcrbin/msxml3.dll
curl -LO https://github.com/relativemodder/aegnux/releases/download/vcrbin/msxml3r.dll
curl -LO https://github.com/relativemodder/aegnux/releases/download/vcrbin/gdiplus.dll
mv msxml3.dll msxml3r.dll gdiplus.dll "./tmp"


#set up wine tkg
curl -LO https://github.com/Kron4ek/Wine-Builds/releases/download/11.8/wine-11.8-staging-tkg-amd64-wow64.tar.xz
tar x -f wine-11.8-staging-tkg-amd64-wow64.tar.xz
mkdir -p "$HOME/.local/share/wine-tkg/"
mv wine-11.8-staging-tkg-amd64-wow64/* "$HOME/.local/share/wine-tkg/"
rm wine-11.8-staging-tkg-amd64-wow64.tar.xz
WINE="$HOME/.local/share/wine-tkg/bin/wine"
WINESERVER="$HOME/.local/share/wine-tkg/bin/wineserver"

#set up nv libs
curl -LO https://github.com/SveSop/nvidia-libs/releases/download/v0.8.5/nvidia-libs-v0.8.5.tar.xz
tar x -f nvidia-libs-v0.8.5.tar.xz
mv nvidia-libs-v0.8.5/ ./tmp/nv-libs/
rm nvidia-libs-v0.8.5.tar.xz
chmod +x ./tmp/nv-libs/setup_nvlibs.sh

#get prefix
echo "Enter Directory to install AE"
echo "Press Enter to choose Default (~/.local/share/Adobe/) :"
read WINEPREFIX
if [[ -z "$WINEPREFIX" ]]; then
    WINEPREFIX="$HOME/.local/share/Adobe/"
fi


#get zip folder location
echo "Enter of AE installation (drag Support Files in here): "
read AEF
if [[ -z "$AEF" ]]; then 
    echo "empty !!!"
    exit 1
fi

#set up prefix
export WINEPREFIX="$WINEPREFIX"
export WINE="$HOME/.local/share/wine-tkg/bin/wine"

set -x

WINEARCH=win64 $WINE wineboot -u
$WINESERVER -w

mkdir -p "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe After Effects 2024/Support Files"
mkdir -p "$WINEPREFIX/drive_c/Program Files (x86)/Common Files/Adobe/CEP"

cp -r "$AEF/." "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe After Effects 2024/Support Files"

winetricks -q corefonts dxvk vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2022
$WINESERVER -w
./tmp/nv-libs/setup_nvlibs.sh install

cat << 'EOF' > fontsmooth.reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Control Panel\Desktop]
"FontSmoothing"="2"
"FontSmoothingGamma"=dword:00000578
"FontSmoothingOrientation"=dword:00000001
"FontSmoothingType"=dword:00000002
EOF

cat << 'EOF' > darkmode.reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Control Panel\Colors]
"ActiveBorder"="49 54 58"
"ActiveTitle"="49 54 58"
"AppWorkSpace"="60 64 72"
"Background"="49 54 58"
"ButtonAlternativeFace"="200 0 0"
"ButtonDkShadow"="154 154 154"
"ButtonFace"="49 54 58"
"ButtonHilight"="119 126 140"
"ButtonLight"="60 64 72"
"ButtonShadow"="60 64 72"
"ButtonText"="219 220 222"
"GradientActiveTitle"="49 54 58"
"GradientInactiveTitle"="49 54 58"
"GrayText"="155 155 155"
"Hilight"="119 126 140"
"HilightText"="255 255 255"
"InactiveBorder"="49 54 58"
"InactiveTitle"="49 54 58"
"InactiveTitleText"="219 220 222"
"InfoText"="159 167 180"
"InfoWindow"="49 54 58"
"Menu"="49 54 58"
"MenuBar"="49 54 58"
"MenuHilight"="119 126 140"
"MenuText"="219 220 222"
"Scrollbar"="73 78 88"
"TitleText"="219 220 222"
"Window"="35 38 41"
"WindowFrame"="49 54 58"
"WindowText"="219 220 222"

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ThemeManager]
"ThemeActive"=0
EOF

#install dlls
$WINESERVER -k
mkdir -p "$WINEPREFIX/drive_c/windows/system32/"
mv ./tmp/msxml3.dll ./tmp/msxml3r.dll ./tmp/gdiplus.dll "$WINEPREFIX/drive_c/windows/system32/"
$WINE reg add 'HKCU\Software\Wine\DllOverrides' /v msxml3 /d native,builtin /f
$WINE reg add 'HKCU\Software\Wine\DllOverrides' /v gdiplus /d native,builtin /f
$WINESERVER -w

$WINESERVER -w
$WINE regedit fontsmooth.reg
$WINE regedit darkmode.reg
$WINESERVER -w

#fix new windows version required
$WINE winecfg -v win10
$WINESERVER -w
sleep 5

cat << 'EOF' > ADOBE-AE.desktop
[Desktop Entry]
Name=After Effect
Exec=WINEPREFIX="$WINEPREFIX" "$WINE" "$AEF/drive_c/Program Files/Adobe/Adobe After Effects 2024/Support Files/AfterFX.exe" %u
Terminal=false
Type=Application
Categories=Utility;Application;
EOF
