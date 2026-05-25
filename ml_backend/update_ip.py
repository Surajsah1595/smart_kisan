import socket
import re
import os

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

dart_file = os.path.join(os.path.dirname(__file__), '..', 'lib', 'crop_advisory.dart')

try:
    with open(dart_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    current_ip = get_local_ip()
    print(f"Detected local IP: {current_ip}")
    
    # Replace wifiIp using regex to catch the line
    content = re.sub(r"const String wifiIp = '.*?';", f"const String wifiIp = '{current_ip}';", content)
    
    with open(dart_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Successfully updated wifiIp in crop_advisory.dart")
except Exception as e:
    print(f"Failed to update IP: {e}")
