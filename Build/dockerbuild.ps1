docker build -t umn-activedirectory .

docker run -v C:\DockerMount:C:\BuildOutput -it --name umn-activedirectory -w C:\pester umn-activedirectory:latest powershell.exe -file .\build\build.ps1

docker container stop umn-activedirectory

docker rm -f umn-activedirectory
