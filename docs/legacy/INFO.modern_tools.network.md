# Network Tools for Administration, Programming & Debugging

---

## Traffic Analysis & Sniffing

**Wireshark**
The gold standard GUI packet analyzer. Captures and dissects traffic at the protocol level — supports hundreds of protocols with deep inspection.

**tshark** *(replaces: Wireshark CLI)*
Terminal version of Wireshark. Scriptable packet capture and analysis — pipe output, filter with display expressions, export to JSON/CSV.

**tcpdump**
The classic low-level packet capture tool. Lightweight, available on almost every Unix system, indispensable for remote SSH sessions.

**termshark**
Terminal UI for `tshark` — brings a Wireshark-like interface to the CLI without a desktop environment.

---

## Port Scanning & Discovery

**nmap**
The definitive network scanner. Host discovery, port scanning, OS detection, service version detection, and scriptable via NSE.

**rustscan** *(replaces: nmap for speed)*
Scans all 65535 ports in seconds, then hands results off to `nmap` for deeper inspection. Dramatically faster initial sweep.

**masscan**
Fastest port scanner available — capable of scanning the entire IPv4 space in minutes. Useful for large subnet sweeps.

**naabu**
Modern port scanner from ProjectDiscovery focused on reliability and integration with recon pipelines.

---

## HTTP Debugging & Testing

**curl**
The universal HTTP Swiss Army knife. Supports every protocol and option you'll ever need — the baseline tool everything else is measured against.

**httpie** *(replaces: curl for humans)*
Intuitive HTTP client with JSON-aware syntax, colored output, and session support. Great for interactive API testing.

**xh** *(replaces: httpie)*
Httpie-compatible but written in Rust — significantly faster startup, same friendly syntax.

**hurl**
Run HTTP requests defined in plain text files — useful for scripted API testing and CI pipelines without a full test framework.

**mitmproxy**
Interactive HTTPS proxy. Intercept, inspect, modify, and replay HTTP/S traffic in real time — invaluable for debugging apps and APIs.

**insomnia** / **bruno**
GUI REST/GraphQL/gRPC clients. Bruno is the modern open-source alternative to Insomnia with local-first, Git-friendly config files.

---

## DNS Tools

**dog** *(replaces: dig)*
Colorful DNS client with DNS-over-TLS and DNS-over-HTTPS support. Human-readable output.

**dig**
The standard DNS lookup tool — detailed, scriptable, universally available. Still the reference tool for DNS debugging.

**drill**
Lightweight `dig` alternative from the ldns library. Simpler output, useful for DNSSEC verification.

**dnsx**
Fast DNS toolkit for bulk lookups, bruteforcing subdomains, and chaining with other recon tools.

**systemd-resolve / resolvectl**
Query and flush the local systemd DNS resolver cache — useful for diagnosing local resolution issues on modern Linux systems.

---

## Connectivity & Diagnostics

**ping / ping6**
The first tool you reach for — ICMP echo to verify reachability and measure round-trip latency.

**mtr** *(replaces: traceroute)*
Combines `ping` and `traceroute` into a live, continuously updating path analysis. Shows per-hop packet loss and latency in real time.

**traceroute / tracepath**
Maps the route packets take across the network, hop by hop. `tracepath` requires no root privileges.

**ss** *(replaces: netstat)*
Socket statistics — faster and more detailed than `netstat`. Shows open ports, connections, socket state, and process ownership.

**iproute2 (ip)** *(replaces: ifconfig / route)*
The modern toolkit for managing interfaces, routes, tunnels, and namespaces. `ip addr`, `ip route`, `ip link` are the standard today.

**netcat (nc)**
The network Swiss Army knife — open raw TCP/UDP connections, transfer files, test ports, build quick servers and proxies.

**socat** *(replaces: netcat)*
More powerful `netcat` — bidirectional data relay between almost any two endpoints: TCP, UDP, Unix sockets, files, TLS, serial ports.

---

## Bandwidth & Performance

**iperf3**
Measures TCP/UDP throughput between two hosts. The standard tool for network performance testing and troubleshooting bottlenecks.

**nload**
Real-time incoming/outgoing bandwidth per interface — simple, minimal, fast to read at a glance.

**bandwhich** *(see also: system tools)*
Shows bandwidth usage broken down by process and remote connection — answers "what is using my network right now."

**speedtest-cli**
Runs an Speedtest.net test from the terminal — useful for verifying ISP throughput on headless servers.

**nethogs**
Groups bandwidth usage by process in real time — similar to `bandwhich` but older and more widely packaged.

---

## Proxies, Tunnels & VPN

**ssh -L / -R / -D**
Built-in SSH port forwarding — local, remote, and dynamic (SOCKS) tunnels without any extra tools.

**bore / frp / chisel**
Modern reverse tunnel tools — expose a local port through a firewall or NAT to a public server. Useful for webhooks, demos, and remote access.

**wireguard / wg**
Modern, fast, minimal VPN built into the Linux kernel. `wg` is its CLI for managing peers, keys, and interfaces.

**stunnel**
Wraps a plain TCP service in TLS without modifying the application — useful for securing legacy protocols.

---

## Load Testing & Stress Testing

**wrk**
High-performance HTTP benchmarking tool — measures requests/sec, latency percentiles, and throughput under load.

**hey** *(replaces: ab)*
Simple HTTP load generator written in Go. Successor to Apache Bench (`ab`) with cleaner output and histogram support.

**k6**
Developer-centric load testing tool with JavaScript scripting, thresholds, and good CI integration.

**vegeta**
Constant-rate HTTP load tester — useful when you want to test behavior at a specific sustained request rate rather than maximum throughput.

---

## SSL/TLS Inspection

**openssl s_client**
Inspect TLS handshakes, certificate chains, cipher negotiation, and protocol versions from the command line.

**sslyze**
Fast TLS/SSL configuration analyzer — checks for weak ciphers, expired certs, HSTS, OCSP stapling, and known vulnerabilities.

**testssl.sh**
Shell script that thoroughly audits a server's TLS configuration without requiring Python or Ruby dependencies.

**certscan / mkcert**
`mkcert` generates locally-trusted development certificates instantly — eliminates self-signed certificate warnings during local development.

