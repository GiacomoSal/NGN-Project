#!/bin/bash
# Script per testare isolamento Multi-Tenant VXLAN (VERSIONE CORRETTA)
# Uso: ./test_multitenant.sh

echo "=========================================="
echo "       TEST MULTI-TENANT VXLAN"
echo "=========================================="

# Funzione per trovare il nome completo del container
find_container() {
    local short_name="$1"
    docker ps --format "{{.Names}}" | grep "_${short_name}_" | head -1
}

# Test presenza container
echo "Rilevamento container in corso..."
H1A=$(find_container "h1a")
H2A=$(find_container "h2a")
H1B=$(find_container "h1b")
H2B=$(find_container "h2b")
H1C=$(find_container "h1c")
H2C=$(find_container "h2c")
S1=$(find_container "s1")
S2=$(find_container "s2")

if [ -z "$H1A" ] || [ -z "$H2A" ] || [ -z "$H1B" ] || [ -z "$H2B" ] || [ -z "$H1C" ] || [ -z "$H2C" ]; then
    echo "ERRORE: Alcuni container non sono stati trovati!"
    echo "Verifica che il lab Kathara sia avviato con: kathara lstart"
    echo ""
    echo "Container trovati:"
    echo "H1A: $H1A"
    echo "H2A: $H2A"
    echo "H1B: $H1B"
    echo "H2B: $H2B"
    echo "H1C: $H1C"
    echo "H2C: $H2C"
    exit 1
fi

echo "✓ Tutti i container trovati correttamente"
echo ""

echo "1. VERIFICA CONNETTIVITÀ INTRA-TENANT"
echo "--------------------------------------"

echo "Testing Tenant A (192.168.10.0/24):"
docker exec "$H1A" ping -c 3 192.168.10.2 >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Tenant A: h1a -> h2a OK"
else
    echo "✗ Tenant A: h1a -> h2a FAILED"
    echo "  Debug: Controllare configurazione IP su h1a e h2a"
fi

echo "Testing Tenant B (192.168.20.0/24):"
docker exec "$H1B" ping -c 3 192.168.20.2 >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Tenant B: h1b -> h2b OK"
else
    echo "✗ Tenant B: h1b -> h2b FAILED"
    echo "  Debug: Controllare configurazione IP su h1b e h2b"
fi

echo "Testing Tenant C (192.168.30.0/24):"
docker exec "$H1C" ping -c 3 192.168.30.2 >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Tenant C: h1c -> h2c OK"
else
    echo "✗ Tenant C: h1c -> h2c FAILED"
    echo "  Debug: Controllare configurazione IP su h1c e h2c"
fi

echo ""
echo "2. VERIFICA ISOLAMENTO INTER-TENANT"
echo "------------------------------------"

echo "Testing isolation A->B:"
timeout 5 docker exec "$H1A" ping -c 3 192.168.20.1 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "✓ Tenant A cannot reach Tenant B (ISOLATION OK)"
else
    echo "✗ Tenant A can reach Tenant B (ISOLATION FAILED)"
fi

echo "Testing isolation A->C:"
timeout 5 docker exec "$H1A" ping -c 3 192.168.30.1 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "✓ Tenant A cannot reach Tenant C (ISOLATION OK)"
else
    echo "✗ Tenant A can reach Tenant C (ISOLATION FAILED)"
fi

echo "Testing isolation B->C:"
timeout 5 docker exec "$H1B" ping -c 3 192.168.30.1 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "✓ Tenant B cannot reach Tenant C (ISOLATION OK)"
else
    echo "✗ Tenant B can reach Tenant C (ISOLATION FAILED)"
fi

echo ""
echo "3. VERIFICA CONFIGURAZIONE VXLAN"
echo "---------------------------------"

if [ -n "$S1" ]; then
    echo "Switch s1 VXLAN interfaces:"
    docker exec "$S1" ip link show | grep vxlan || echo "  Nessuna interfaccia VXLAN trovata su s1"
fi

if [ -n "$S2" ]; then
    echo "Switch s2 VXLAN interfaces:"
    docker exec "$S2" ip link show | grep vxlan || echo "  Nessuna interfaccia VXLAN trovata su s2"
fi

echo ""
echo "4. INFORMAZIONI DEBUG"
echo "---------------------"
echo "Container utilizzati:"
echo "H1A: $H1A"
echo "H2A: $H2A"
echo "H1B: $H1B"
echo "H2B: $H2B"
echo "H1C: $H1C"
echo "H2C: $H2C"
if [ -n "$S1" ]; then echo "S1:  $S1"; fi
if [ -n "$S2" ]; then echo "S2:  $S2"; fi

echo ""
echo "5. VERIFICA CONFIGURAZIONE IP"
echo "-----------------------------"
echo "Configurazione IP degli host:"
docker exec "$H1A" ip addr show eth0 | grep inet || echo "Errore configurazione h1a"
docker exec "$H2A" ip addr show eth0 | grep inet || echo "Errore configurazione h2a"
docker exec "$H1B" ip addr show eth0 | grep inet || echo "Errore configurazione h1b"
docker exec "$H2B" ip addr show eth0 | grep inet || echo "Errore configurazione h2b"
docker exec "$H1C" ip addr show eth0 | grep inet || echo "Errore configurazione h1c"
docker exec "$H2C" ip addr show eth0 | grep inet || echo "Errore configurazione h2c"

echo ""
echo "6. TRAFFIC GENERATION PER WIRESHARK"
echo "------------------------------------"
echo "Generating traffic for Wireshark capture..."

# Traffico simultaneo per tutti i tenant
docker exec "$H1A" ping -c 5 192.168.10.2 >/dev/null 2>&1 &
docker exec "$H1B" ping -c 5 192.168.20.2 >/dev/null 2>&1 &
docker exec "$H1C" ping -c 5 192.168.30.2 >/dev/null 2>&1 &

wait

echo "✓ Traffico generato"

echo ""
echo "=========================================="
echo "Test completato!"
echo ""
echo "Analizza il traffico con Wireshark usando:"
echo "- Filtro 'vxlan' per vedere tutto il traffico VXLAN"
echo "- Filtro 'vxlan.vni == 10' per Tenant A"
echo "- Filtro 'vxlan.vni == 20' per Tenant B" 
echo "- Filtro 'vxlan.vni == 30' per Tenant C"
echo ""
echo "Per test manuali usa i nomi completi dei container"
echo "Esempio: docker exec \"$H1A\" ping 192.168.10.2"
echo "=========================================="