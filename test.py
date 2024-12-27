#!/usr/bin/env python3
import socket
import sys
import time

def test_piper_server(host='localhost', port=8765, text='Hallo, dies ist ein Test.'):
    """
    Test the Piper TTS server by sending a text message
    """
    try:
        # Create socket
        print(f"Connecting to {host}:{port}...")
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((host, port))
        
        # Send test message
        print(f"Sending text: '{text}'")
        sock.send(text.encode('utf-8'))
        
        # Wait for response
        response = sock.recv(1024).decode('utf-8')
        print(f"Received response: {response}")
        
        # Close connection
        sock.close()
        return True
        
    except ConnectionRefusedError:
        print(f"Error: Could not connect to server at {host}:{port}")
        print("Make sure the server is running and the port is correct")
        return False
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return False

if __name__ == "__main__":
    # Get command line arguments if provided
    host = sys.argv[1] if len(sys.argv) > 1 else 'localhost'
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8765
    text = sys.argv[3] if len(sys.argv) > 3 else 'Hallo, dies ist ein Test.'
    
    # Run multiple test messages with delay
    test_messages = [
        "Hallo, dies ist der erste Test.",
        "Dies ist der zweite Test.",
        "Und dies ist der letzte Test."
    ]
    
    if len(sys.argv) <= 3:  # If no specific text provided, run multiple tests
        print("Running multiple test messages...")
        for msg in test_messages:
            test_piper_server(host, port, msg)
            time.sleep(2)  # Wait for previous message to finish
    else:
        # Run single test with provided text
        test_piper_server(host, port, text)
