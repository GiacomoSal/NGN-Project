#!/bin/bash
# Wireshark configuration for VLAN + VXLAN Multi-Tenant

PROJECT_NAME=${1:-$(basename $(pwd))}
CONTAINER_NAME="wireshark-vlan-vxlan"

echo "=== Setup Wireshark Monitoring VLAN + VXLAN per progetto: $PROJECT_NAME ==="

#Verifica che il lab sia avviato
echo "-> Verifico che il lab Kathara sia avviato..."
if ! docker network ls | grep -q "kathara_"; then
    echo "Lab Kathara non trovato. Avvio il lab..."
    kathara lstart
    sleep 45
    echo "Lab avviato!"
else
    echo "Lab Kathara già avviato."
fi

# Rileva automaticamente il nome del progetto
ACTUAL_PROJECT=$(docker network ls --format "{{.Name}}" | grep "kathara_" | head -1 | cut -d'_' -f2 | cut -d'.' -f1)
if [ -n "$ACTUAL_PROJECT" ]; then
    PROJECT_NAME="$ACTUAL_PROJECT"
    echo "Nome progetto rilevato: $PROJECT_NAME"
fi

# Trova tutte le reti di interesse
VLAN_TRUNK_NET=$(docker network ls --format "{{.Name}}" | grep "kathara_${PROJECT_NAME}.*VLAN_TRUNK")
TRANSPORT1_NET=$(docker network ls --format "{{.Name}}" | grep "kathara_${PROJECT_NAME}.*TRANSPORT1")
TRANSPORT2_NET=$(docker network ls --format "{{.Name}}" | grep "kathara_${PROJECT_NAME}.*TRANSPORT2")

if [ -z "$VLAN_TRUNK_NET" ] || [ -z "$TRANSPORT1_NET" ] || [ -z "$TRANSPORT2_NET" ]; then
    echo "ERRORE: Non tutte le reti sono state trovate"
    echo "Reti disponibili:"
    docker network ls | grep kathara_${PROJECT_NAME}
    exit 1
fi

echo "Reti trovate:"
echo "- VLAN_TRUNK (s1↔s3): $VLAN_TRUNK_NET"
echo "- TRANSPORT1 (s3↔r1): $TRANSPORT1_NET"
echo "- TRANSPORT2 (r1↔s2): $TRANSPORT2_NET"

# Rimuovi container esistente
if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "-> Rimuovo container Wireshark esistente..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    docker rm $CONTAINER_NAME > /dev/null 2>&1
fi

# Avvia container Wireshark
echo "-> Avvio container Wireshark..."
docker run -d \
  --name $CONTAINER_NAME \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Rome \
  -p 3000:3000 \
  linuxserver/wireshark

# Attendi che il container sia pronto
echo "Attendo che il container sia pronto..."
sleep 8

# Collega alle reti di interesse
echo "-> Collego container alle reti..."
docker network connect $VLAN_TRUNK_NET $CONTAINER_NAME
sleep 2
docker network connect $TRANSPORT1_NET $CONTAINER_NAME
sleep 2
docker network connect $TRANSPORT2_NET $CONTAINER_NAME

echo ""
echo "=== Setup VLAN + VXLAN completato ==="
echo "- Container Wireshark: $CONTAINER_NAME"
echo "- Interfaccia web: http://localhost:3000"
echo "- Reti monitorate: VLAN_TRUNK, TRANSPORT1, TRANSPORT2"
echo ""
echo "=== INTERFACCE WIRESHARK ==="
echo "Una volta collegato a http://localhost:3000:"
echo "- eth1: VLAN_TRUNK (s1 ↔ s3) - traffico VLAN taggato"
echo "- eth2: TRANSPORT1 (s3 ↔ r1) - traffico VXLAN incapsulato"
echo "- eth3: TRANSPORT2 (r1 ↔ s2) - traffico VXLAN incapsulato"
echo ""
echo "=== CLEANUP ==="
echo "Per fermare il monitoraggio:"
echo "docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo "kathara lclean"
echo ""