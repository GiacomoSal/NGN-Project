# NGN-Project

This project implements a multi-tenant VXLAN network architecture using Kathara network emulation platform. The system demonstrates network isolation across three tenants (A, B, C) using a combination of 802.1Q VLAN tagging and VXLAN overlay technology.

Key features include tenant isolation, VLAN-to-VXLAN gateway functionality, automated Wireshark monitoring for traffic analysis, and a complete multi-site network simulation.

---

## Getting Started

These instructions will help you set up the project on your local machine for development and testing.

### Prerequisites

Before getting started, ensure that you have the following installed:

- **Docker** - [Download Docker](https://www.docker.com/get-started)
- **Kathara** - [Download Kathara](https://www.kathara.org/)
- **Git** - [Download Git](https://git-scm.com/)

---

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/GiacomoSal/NGN-Project.git
   cd NGN-Project
   ```

2. Navigate to the VXLAN project directory:
   ```bash
   cd VXLAN_Project
   ```

3. Make the setup script executable:
   ```bash
   chmod +x setup_wireshark_monitoring.sh
   ```

---

### Running the Project

#### Automated Setup (Recommended)

To automatically start the entire lab environment with Wireshark monitoring:

```bash
./setup_wireshark_monitoring.sh
```

This command will:
- Check if the Kathara lab is running
- Start the lab if not already running
- Launch Wireshark monitoring container
- Connect monitoring to all relevant network segments

#### Manual Setup (Alternative)

If the automated setup doesn't work, you can start the components manually:

1. **Start the Kathara lab**:
   ```bash
   kathara lstart
   ```

2. **Wait for the lab to initialize** (approximately 45 seconds)

3. **Start Wireshark monitoring**:
   ```bash
   ./setup_wireshark_monitoring.sh
   ```

#### Accessing Wireshark

Once the setup is complete:
- Open your web browser and go to: `http://localhost:3000` or `http://127.0.0.1:3000` (if the previous doesn't work)
- You'll have access to Wireshark with the following interfaces:
  - **eth1**: VLAN_TRUNK (s1 ↔ s3) - VLAN tagged traffic
  - **eth2**: TRANSPORT1 (s3 ↔ r1) - VXLAN encapsulated traffic
  - **eth3**: TRANSPORT2 (r1 ↔ s2) - VXLAN encapsulated traffic

---

### Testing the Network

#### Tenant Connectivity Testing

You can test connectivity between hosts of the same tenant:

```bash
# Test Tenant A connectivity
kathara exec h1a -- ping 192.168.10.2

# Test Tenant B connectivity
kathara exec h1b -- ping 192.168.20.2

# Test Tenant C connectivity
kathara exec h1c -- ping 192.168.30.2
```

#### Traffic Analysis

Monitor traffic using Wireshark at `http://localhost:3000` or `http://127.0.0.1:3000` (if the previous doesn't work):
- **VLAN Traffic**: Observe 802.1Q tagged packets on eth1
- **VXLAN Traffic**: Observe VXLAN encapsulated packets on eth2 and eth3
- **Tenant Isolation**: Verify that traffic from different tenants uses different VNIs

---

### Stopping the Project

To stop the entire lab environment:

```bash
# Stop Wireshark monitoring
docker stop wireshark-vlan-vxlan && docker rm wireshark-vlan-vxlan

# Clean up Kathara lab
kathara lclean
```

---

### Network Architecture

#### Tenant Configuration
- **Tenant A**: VLAN 10 → VNI 100 (192.168.10.0/24)
- **Tenant B**: VLAN 20 → VNI 200 (192.168.20.0/24)
- **Tenant C**: VLAN 30 → VNI 300 (192.168.30.0/24)

#### Traffic Flow
1. **h1x → s1**: Untagged Ethernet frames
2. **s1 → s3**: 802.1Q VLAN tagged frames
3. **s3 → r1**: VXLAN encapsulated packets
4. **r1 → s2**: VXLAN forwarded packets
5. **s2 → h2x**: VXLAN decapsulated to Ethernet

#### Transport Network
- **s3 ↔ r1**: 10.0.1.0/24 network
- **r1 ↔ s2**: 10.0.2.0/24 network

---

## Project Structure

```
NGN-Project/
├── README.md                           # Main project documentation and overview
└── VXLAN_Project/                      # Multi-tenant VXLAN network implementation
    ├── h1a.startup                     # Tenant A host - Site 1 (192.168.10.1/24, gw 192.168.10.254)
    ├── h1b.startup                     # Tenant B host - Site 1 (192.168.20.1/24, gw 192.168.20.254)
    ├── h1c.startup                     # Tenant C host - Site 1 (192.168.30.1/24, gw 192.168.30.254)
    ├── h2a.startup                     # Tenant A host - Site 2 (192.168.10.2/24, gw 192.168.10.254)
    ├── h2b.startup                     # Tenant B host - Site 2 (192.168.20.2/24, gw 192.168.20.254)
    ├── h2c.startup                     # Tenant C host - Site 2 (192.168.30.2/24, gw 192.168.30.254)
    ├── lab.conf                        # Kathara topology configuration (network connections)
    ├── r1.startup                      # Transport router (10.0.1.1/24 ↔ 10.0.2.1/24, IP forwarding)
    ├── s1.startup                      # VLAN switch (untagged → 802.1Q tagged via trunk)
    ├── s2.startup                      # VXLAN endpoint switch (VXLAN VNI 100/200/300 → untagged)
    ├── s3.startup                      # VLAN-to-VXLAN gateway (802.1Q VLAN → VXLAN encapsulation)
    └── setup_wireshark_monitoring.sh   # Automated Wireshark setup for traffic analysis
```

---

## Links
- [Presentation]()

---

## Contact us

- **Davide Valer**: [davide.valer@studenti.unitn.it](mailto:davide.valer@studenti.unitn.it)
- **Dimitri Corraini**: [dimitri.corraini@studenti.unitn.it](mailto:dimitri.corraini@studenti.unitn.it)
- **Giacomo Saltori**: [giacomo.saltori-1@studenti.unitn.it](mailto:giacomo.saltori-1@studenti.unitn.it)

---

_Project realised for the Next Generation Network 2024/2025 course - University of Trento_
