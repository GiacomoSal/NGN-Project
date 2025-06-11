#!/bin/bash
# Script per configurare monitoraggio Wireshark su lab Kathara VXLAN
# Uso: ./setup_wireshark_monitoring.sh [nome_progetto]

PROJECT_NAME=${1:-$(basename $(pwd))}
CONTAINER_NAME="wireshark"

echo "=== Setup Wireshark Monitoring per progetto: $PROJECT_NAME ==="

# 1. Verifica che il lab sia avviato, altrimenti lo avvia
echo "Verifico che il lab Kathara sia avviato..."
if ! docker network ls | grep -q "kathara_"; then
    echo "Lab Kathara non trovato. Avvio il lab..."
    kathara lstart
    echo "Attendo 30 secondi per il completamento dell'avvio..."
    sleep 30
    echo "Lab avviato!"
else
    echo "Lab Kathara già avviato ✓"
fi

# Rileva automaticamente il nome del progetto dalle reti Docker
ACTUAL_PROJECT=$(docker network ls --format "{{.Name}}" | grep "kathara_" | head -1 | cut -d'_' -f2 | cut -d'.' -f1)
if [ -n "$ACTUAL_PROJECT" ]; then
    PROJECT_NAME="$ACTUAL_PROJECT"
    echo "Nome progetto rilevato: $PROJECT_NAME"
fi

# 2. Trova le reti di trasporto
TRANSPORT1_NET=$(docker network ls --format "{{.Name}}" | grep "kathara_${PROJECT_NAME}.*TRANSPORT1")
TRANSPORT2_NET=$(docker network ls --format "{{.Name}}" | grep "kathara_${PROJECT_NAME}.*TRANSPORT2")

if [ -z "$TRANSPORT1_NET" ] || [ -z "$TRANSPORT2_NET" ]; then
    echo "ERRORE: Reti di trasporto non trovate"
    echo "Reti disponibili:"
    docker network ls | grep kathara_${PROJECT_NAME}
    exit 1
fi

echo "Reti trovate:"
echo "- TRANSPORT1: $TRANSPORT1_NET"
echo "- TRANSPORT2: $TRANSPORT2_NET"

# 3. Rimuovi container esistente se presente
if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Rimuovo container Wireshark esistente..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    docker rm $CONTAINER_NAME > /dev/null 2>&1
fi

# 4. Avvia container Wireshark
echo "Avvio container Wireshark..."
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
sleep 5

# 5. Collega alle reti di trasporto
echo "Collego container alle reti di trasporto..."
docker network connect $TRANSPORT1_NET $CONTAINER_NAME
sleep 1
docker network connect $TRANSPORT2_NET $CONTAINER_NAME

echo ""
echo "=== Setup completato! ==="
echo "- Container Wireshark: $CONTAINER_NAME"
echo "- Interfaccia web: http://localhost:3000"
echo "- Reti monitorate: TRANSPORT1 e TRANSPORT2"
echo ""
echo "Per catturare traffico VXLAN in Wireshark:"
echo "1. Vai su http://localhost:3000"
echo "2. Avvia cattura su ENTRAMBE le interfacce eth1 e eth2:"
echo "   - eth1: collegata a TRANSPORT1"
echo "   - eth2: collegata a TRANSPORT2"
echo "3. Usa filtro: 'port 4789' o 'vxlan'"
echo "4. Genera traffico bidirezionale:"
echo "   - Da h1 a h2: ping 192.168.100.2"
echo "   - Da h2 a h1: ping 192.168.100.1"
echo ""
echo "Per fermare il monitoraggio e pulire il lab:"
echo "docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo "kathara lclean"
