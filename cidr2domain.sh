#!/bin/bash
# Crated by @vijay922 - https://hackerconnected.wordpress.com

curl -s  -X POST --data "url=$@&Submit1=Submit" https://suip.biz/?act=amass | grep $@ | cut -d ">" -f 2 | awk 'NF' | tee -a suip-amass-$@.txt 2> /dev/null

curl -s  -X POST --data "url=$@&Submit1=Submit" https://suip.biz/?act=subfinder | grep $@ | cut -d ">" -f 2 | awk 'NF' | tee -a suip-subfinder-$@.txt 2> /dev/null

curl -s  -X POST --data "url=$@&Submit1=Submit" https://suip.biz/?act=findomain | grep $@ | cut -d ">" -f 2 | awk 'NF' | tee -a suip-findomain-$@.txt 2> /dev/null

cat suip-amass-$@.txt suip-subfinder-$@.txt suip-findomain-$@.txt | sort -u > Subdomains-of-$@.txt
rm -rf suip-amass-$@.txt suip-subfinder-$@.txt suip-findomain-$@.txt

bash converter.sh Subdomains-of-$@.txt Subdomains-IPs.txt

cat Subdomains-IPs.txt | while read line; do
    oc1=`echo "$line" | cut -d '.' -f 1`
    oc2=`echo "$line" | cut -d '.' -f 2`
    oc3=`echo "$line" | cut -d '.' -f 3`
    oc4=`echo "$line" | cut -d '.' -f 4`
    echo "$oc1.$oc2.$oc3.1/24" >> IPs1.srt
done

sort -u IPs1.srt > CIDR-IPs.txt
rm -rf IPs1.srt
ori=`cat Subdomains-IPs.txt | wc -l`
new=`cat CIDR-IPs.txt | wc -l`
echo "$ori"
echo "$new"


echo "[+] mass-reverse-dns [+]"
cat CIDR-IPs.txt | while read ip; do python reverse_dns.py -is $ip >> Reverse_dns.txt 2> /dev/null
done;

cat /var/www/html/ASN/Reverse_dns.txt | sed  s/.$// | cut -d " " -f 3 | grep $@ | sort -u > CIDR-urls.txt 


chmod -R 777 *
