#!/bin/bash
echo $HOSTNAME
apt-get update && apt-get install -y wget gpg apt-transport-https gzip unzip
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
wget -q https://packages.microsoft.com/config/debian/10/prod.list
mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
chown root:root /etc/apt/sources.list.d/microsoft-prod.list
apt-get update && apt-get install dotnet-sdk-3.1 -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
./aws/install
dotnet tool install --global dotnet-dump

pathToDump=/tmp/dumps/
mkdir $pathToDump
file_name=${HOSTNAME}_core_$(date '+%Y%m%d-%H%M%S')
fullPath=$pathToDump$file_name

/root/.dotnet/tools/dotnet-dump collect -p 1 --output $fullPath
gzip $fullPath
aws s3 cp  $fullPath.gz  s3://smartcat-web-dumps/ --no-progress
#--acl public-read
rm $fullPath.gz
