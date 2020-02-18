#!/bin/bash

curl -s -L --data "ip=$1" https://2ip.me/en/services/information-service/provider-ip\?a\=act | grep -o -E '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}/[0-9]{1,2}' | tee -a CIDR.txt

cat CIDR.txt | while read ip; do ./scandns.pl $ip >> domains1.txt
done

cat domains1.txt | sort -u > domains.txt
rm -rf doamins1.txt

cat domains.txt | grep $1 > subdomains-of-$1.txt