#!/usr/bin/env python3
import socket
import subprocess
from threading import Thread

def handle_client(client_socket):
    data = client_socket.recv(1024).decode('utf-8')
    if not data:
        return
    
    try:
        # Escape single quotes in the text
        text = data.replace("'", "\\'")
        
        # Create the piper command
        cmd = f"echo '{text}' | /opt/piper/build/piper --model /opt/piper/voices/kerstint/low/de_DE-kerstin-low.onnx --output-raw | aplay -r 16000 -f S16_LE -t raw -"
        
        # Execute the command
        subprocess.run(cmd, shell=True)
        
        # Send confirmation back
        client_socket.send(b"OK")
    except Exception as e:
        client_socket.send(str(e).encode())
    finally:
        client_socket.close()

def start_server(host='0.0.0.0', port=8765):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((host, port))
    server.listen(5)
    
    print(f"[*] Listening on {host}:{port}")
    
    while True:
        client, addr = server.accept()
        print(f"[*] Accepted connection from {addr[0]}:{addr[1]}")
        client_handler = Thread(target=handle_client, args=(client,))
        client_handler.start()

if __name__ == "__main__":
    start_server()
