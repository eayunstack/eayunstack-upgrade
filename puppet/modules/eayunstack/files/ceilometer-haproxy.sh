#!/bin/bash
#Name: ceilometer-haproxy.sh
#Topic: This Shell Use update haproxy, default haproxy 140-ceilometer.cfg don't add rise,fall.
#Author: Fabian
#Date: 2016-03-22

file='/etc/haproxy/conf.d/140-ceilometer.cfg'
sed -i 's/httplog/tcplog/' $file
sed -i '/roundrobin/a\  option tcpka' $file
sed -i '/tcpka/a\  option httpclose' $file
sed -i '/tcplog/a\  timeout client 5h' $file
sed -i '/client 5h/a\  timeout server 5h' $file
sed -i 's/check/check inter 2000 rise 2 fall 5/g' $file
