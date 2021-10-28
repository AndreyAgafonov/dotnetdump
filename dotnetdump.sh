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
unzip -f awscliv2.zip
./aws/install
dotnet tool install --global dotnet-dump
dotnet tool install --global dotnet-gcdump

pathToDump=/tmp/dumps/
mkdir $pathToDump
TS=$(date '+%Y%m%d-%H%M%S')
file_name_core=${HOSTNAME}_core_$TS
file_name_gc=${HOSTNAME}_gc_$TS
file_name_meta=${HOSTNAME}_meta_$TS
fullPathCore=$pathToDump$file_name_core
fullPathGc=$pathToDump$file_name_gc
fullPathMeta=$pathToDump$file_name_meta

START=$(date +%s%N)
/root/.dotnet/tools/dotnet-dump collect -p 1 --output $fullPathCore
ENDDUMP=$(date +%s%N)
gzip $fullPathCore
ENDARC=$(date +%s%N)
aws s3 cp  $fullPathCore.gz  s3://smartcat-web-dumps/ --no-progress
ENDUPLOAD=$(date +%s%N)
rm $fullPathCore.gz
DIFFDUMP=$(($($ENDDUMP - $START)/1000000))
DIFFARC=$(($($ENDARC - $ENDDUMP)/1000000))
DIFFUPLOAD=$(($($ENDUPLOAD - $ENDARC)/1000000))
echo "dotnet-dump: Time to dump $DIFFDUMP" >$fullPathMeta
echo "dotnet-dump: Time to dump $DIFFARC" >>$fullPathMeta
echo "dotnet-dump: Time to dump $DIFFUPLOAD" >>$fullPathMeta

START=$(date +%s%N)
/root/.dotnet/tools/dotnet-gcdump collect -p 1 --output $fullPathGc
ENDDUMP=$(date +%s%N)
gzip $fullPathGc
ENDARC=$(date +%s%N)
aws s3 cp  $fullPathGc.gz  s3://smartcat-web-dumps/ --no-progress
ENDUPLOAD=$(date +%s%N)
rm $fullPathGc.gz
DIFFDUMP=$(($($ENDDUMP - $START)/1000000))
DIFFARC=$(($($ENDARC - $ENDDUMP)/1000000))
DIFFUPLOAD=$(($($ENDUPLOAD - $ENDARC)/1000000))
echo "dotnet-gcdump: Time to dump $DIFFDUMP" >>$fullPathMeta
echo "dotnet-gcdump: Time to dump $DIFFARC" >>$fullPathMeta
echo "dotnet-gcdump: Time to dump $DIFFUPLOAD" >>$fullPathMeta

gzip $fullPathMeta
aws s3 cp  $fullPathMeta.gz  s3://smartcat-web-dumps/ --no-progress
rm $fullPathMeta.gz