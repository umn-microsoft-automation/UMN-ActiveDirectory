ARG TAG=ltsc2019
FROM mcr.microsoft.com/windows/servercore:$TAG

WORKDIR /pester

ADD . /pester

CMD powershell.exe .\Build\build.ps1