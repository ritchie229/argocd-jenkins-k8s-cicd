#!/bin/bash

iptables -t nat -L PREROUTING -n --line-numbers

read -p "Pls specify the External Port: " EXT_PORT
read -p "Pls specify the Cluster IP: " CLUSTER_IP
read -p "Pls specify the NodePort: " NODE_PORT


echo "===========REMOVING IP FORWARDING MAIN RULES==============="
iptables -t nat -D PREROUTING -p tcp --dport $EXT_PORT -j DNAT --to-destination $CLUSTER_IP:$NODE_PORT

echo "==============$CLUSTER_IP:$PORT CLOSED!!!=================="
echo "See the results: "
echo
iptables -t nat -L PREROUTING -n --line-numbers

