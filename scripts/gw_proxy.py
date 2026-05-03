#!/usr/bin/env python3
"""简单的TCP端口转发：从 0.0.0.0:18790 转到 127.0.0.1:18789"""
import socket, threading, sys, os, signal

LISTEN_ADDR = '0.0.0.0'
LISTEN_PORT = 18790
TARGET_HOST = '127.0.0.1'
TARGET_PORT = 18789

def forward(src, dst):
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except:
        pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def handle(conn):
    try:
        target = socket.create_connection((TARGET_HOST, TARGET_PORT), timeout=10)
        threading.Thread(target=forward, args=(conn, target), daemon=True).start()
        threading.Thread(target=forward, args=(target, conn), daemon=True).start()
    except Exception as e:
        conn.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTEN_ADDR, LISTEN_PORT))
    server.listen(128)
    pid = os.getpid()
    print(f"[gw_proxy] PID {pid}: {LISTEN_ADDR}:{LISTEN_PORT} -> {TARGET_HOST}:{TARGET_PORT}")
    with open('/tmp/gw_proxy.pid', 'w') as f:
        f.write(str(pid))

    def cleanup(*args):
        print("\n[gw_proxy] shutting down")
        server.close()
        sys.exit(0)
    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    while True:
        conn, addr = server.accept()
        threading.Thread(target=handle, args=(conn,), daemon=True).start()

if __name__ == '__main__':
    main()
