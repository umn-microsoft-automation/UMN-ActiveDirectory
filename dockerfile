FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019

RUN mkdir /pester
RUN mkdir /TestOutput

ADD . /pester
