#!/bin/bash
echo "==========DOCKER USER ACCEPT IF DROPPED============"
iptables -C DOCKER-USER -i ens160 -m conntrack --ctstate DNAT -j ACCEPT 2>/dev/null || \
iptables -I DOCKER-USER -i ens160 -m conntrack --ctstate DNAT -j ACCEPT


echo "=================ENABLE IP FORWARDING=============="
sysctl -w net.ipv4.ip_forward=1
#sysctl -w net.ipv4.conf.all.route_localnet=1

read -p "Pls specify the ServiceName: " SERVICENAME
read -p "Pls specify the NameSpace: " NAMESPACE
read -p "Pls specify the a Port for external access: " EXT_PORT
#NAMESPACE=$(kubectl get ns | grep -oE '\b(prod|dev)\b' | head -n1)

#PORT=$(kubectl describe svc -n $NAMESPACE | grep NodePort | awk '{print $3}' | awk -F'/' '{printf $1}')
PORT=$(kubectl get svc -n $NAMESPACE $SERVICENAME -o jsonpath='{.spec.ports[0].nodePort}')


MINI_PROFILE=$(minikube profile | awk '{print $2}')
CLUSTER_IP=$(minikube ip --profile $MINI_PROFILE)
echo "==========ADD EXTERNAL PORT RULE For Argo CD =============="
iptables -t nat -A PREROUTING -p tcp --dport $EXT_PORT -j DNAT --to-destination $CLUSTER_IP:$PORT

#iptables -t nat -A OUTPUT -p tcp --dport $EXT_PORT -j DNAT --to-destination $CLUSTER_IP:$PORT
#iptables -t nat -A POSTROUTING -d $CLUSTER_IP -p tcp --dport $PORT -j MASQUERADE
#iptables -t nat -A POSTROUTING -j MASQUERADE


echo "===========DOCKER UNLOCKED IP FORWARDING==========="
echo "+++++++++++++++++++++see+++++++++++++++++++++++++++"
iptables -L DOCKER-USER -nv --line-numbers
echo "===========$CLUSTER_IP:$PORT accessible============"
echo "+++++++++++++++++++++see+++++++++++++++++++++++++++"
iptables -t nat -L PREROUTING -n --line-numbers
#iptables -t nat -L OUTPUT -n --line-numbers
#iptables -t nat -L POSTROUTING -n --line-numbers
