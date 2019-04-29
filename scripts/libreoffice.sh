#!/bin/bash
# full system upgrade and newest libreoffice
add-apt-repository -y ppa:libreoffice/ppa && apt update && apt full-upgrade -y && apt -y install libreoffice libreoffice-help-et libreoffice-l10n-et libreoffice-pdfimport libreoffice-nlpsolver libreoffice-ogltrans libreoffice-report-builder libreoffice-style-galaxy libreoffice-templates libreoffice-systray && apt -y remove libreoffice-style-tango libreoffice-style-breeze && ldconfig && dpkg --configure -a && apt clean