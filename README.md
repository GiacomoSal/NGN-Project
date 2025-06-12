# NGN-Project

---

## Project Structure

```
NGN-Project/
├── README.md                           # Project overview and documentation
└── VXLAN_Project/                      # Multi-tenant VXLAN implementation
    ├── h1a.startup                     # Tenant A host - Site 1 (192.168.10.1)
    ├── h1b.startup                     # Tenant B host - Site 1 (192.168.20.1)
    ├── h1c.startup                     # Tenant C host - Site 1 (192.168.30.1)
    ├── h2a.startup                     # Tenant A host - Site 2 (192.168.10.2)
    ├── h2b.startup                     # Tenant B host - Site 2 (192.168.20.2)
    ├── h2c.startup                     # Tenant C host - Site 2 (192.168.30.2)
    ├── lab.conf                        # Kathara lab topology configuration
    ├── r1.startup                      # Router configuration (transport network)
    ├── s1.startup                      # Switch 1 - VXLAN VTEP configuration (Site 1)
    ├── s2.startup                      # Switch 2 - VXLAN VTEP configuration (Site 2)
    ├── setup_wireshark_monitoring.sh   # Automated Wireshark setup for traffic analysis
    ├── shared/                         # Shared resources and captures
    │   └── vxlan_capture.pcap          # Sample VXLAN traffic capture
    └── test_multitenant.sh             # Automated testing script for tenant isolation
```

---

## Contact us

- **Davide Valer**: [davide.valer@studenti.unitn.it](mailto:davide.valer@studenti.unitn.it)
- **Dimitri Corraini**: [dimitri.corraini@studenti.unitn.it](mailto:dimitri.corraini@studenti.unitn.it)
- **Giacomo Saltori**: [giacomo.saltori-1@studenti.unitn.it](mailto:giacomo.saltori-1@studenti.unitn.it)

---

_Project realised for the Next Generation Network 2024/2025 course - University of Trento_
