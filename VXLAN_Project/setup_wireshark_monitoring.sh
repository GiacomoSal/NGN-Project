#!/bin/bash
# Script per configurare monitoraggio Wireshark su lab Kathara VXLAN Multi-Tenant
# Uso: ./setup_wireshark_monitoring_multitenant.sh [nome_progetto]

PROJECT_NAME=${1:-$(basename $(pwd))}
CONTAINER_NAME="wireshark-multitenant"

echo "=== Setup Wireshark Monitoring Multi-Tenant per progetto: $PROJECT_NAME ==="

# 1. Verifica che il lab sia avviato, altrimenti lo avvia
echo "Verifico che il lab Kathara sia avviato..."
if ! docker network ls | grep -q "kathara_"; then
    echo "Lab Kathara non trovato. Avvio il lab..."
    kathara lstart
    echo "Attendo 45 secondi per il completamento dell'avvio (più host = più tempo)..."
    sleep 45
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
sleep 8

# 5. Collega alle reti di trasporto
echo "Collego container alle reti di trasporto..."
docker network connect $TRANSPORT1_NET $CONTAINER_NAME
sleep 2
docker network connect $TRANSPORT2_NET $CONTAINER_NAME

echo ""
echo "=== Setup Multi-Tenant completato! ==="
echo "- Container Wireshark: $CONTAINER_NAME"
echo "- Interfaccia web: http://localhost:3000"
echo "- Reti monitorate: TRANSPORT1 e TRANSPORT2"
echo ""
echo "=== ANALISI TRAFFICO MULTI-TENANT ==="
echo "Per catturare traffico VXLAN in Wireshark:"
echo "1. Vai su http://localhost:3000"
echo "2. Avvia cattura su ENTRAMBE le interfacce:"
echo "   - eth1: collegata a TRANSPORT1 (s1 ↔ r1)"
echo "   - eth2: collegata a TRANSPORT2 (s2 ↔ r1)"
echo ""
echo "3. FILTRI UTILI PER MULTI-TENANT:"
echo "   - 'vxlan' : Tutto il traffico VXLAN"
echo "   - 'vxlan.vni == 100' : Solo Tenant A"
echo "   - 'vxlan.vni == 200' : Solo Tenant B"
echo "   - 'vxlan.vni == 300' : Solo Tenant C"
echo "   - 'port 4789' : Porta VXLAN standard"
echo ""
echo "4. GENERA TRAFFICO DI TEST:"
echo "   Tenant A: docker exec ${PROJECT_NAME}_h1a ping 192.168.10.2"
echo "   Tenant B: docker exec ${PROJECT_NAME}_h1b ping 192.168.20.2"
echo "   Tenant C: docker exec ${PROJECT_NAME}_h1c ping 192.168.30.2"
echo ""
echo "5. TEST ISOLAMENTO (dovrebbe fallire):"
echo "   docker exec ${PROJECT_NAME}_h1a ping 192.168.20.1"
echo "   docker exec ${PROJECT_NAME}_h1a ping 192.168.30.1"
echo ""
echo "6. SCRIPT AUTOMATICO:"
echo "   ./test_multitenant.sh"
echo ""
echo "=== CLEANUP ==="
echo "Per fermare il monitoraggio:"
echo "docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo "kathara lclean"
echo ""
echo "=== COSA OSSERVARE IN WIRESHARK ==="
echo "- Pacchetti VXLAN con VNI diversi (100, 200, 300)"
echo "- Isolamento: solo traffico intra-tenant visibile"
echo "- Encapsulation: Ethernet → IP → UDP → VXLAN → Ethernet → IP"
echo "- FDB learning: primi pacchetti vs successivi"