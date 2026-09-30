"""
Python PBO Packer for Arma 3
Packs an addon directory into a 100% valid Bohemia Interactive PBO file
with proper 'sreV' metadata headers and SHA-1 checksum.
"""

import os
import sys
import struct
import hashlib
import time

def pack_to_pbo(source_dir, output_pbo_path, default_prefix="arma_radar"):
    source_dir = os.path.abspath(source_dir)
    output_pbo_path = os.path.abspath(output_pbo_path)
    os.makedirs(os.path.dirname(output_pbo_path), exist_ok=True)
    
    # Read $PBOPREFIX$ if exists
    prefix_file = os.path.join(source_dir, '$PBOPREFIX$')
    pbo_prefix = default_prefix
    if os.path.isfile(prefix_file):
        with open(prefix_file, 'r', encoding='utf-8', errors='ignore') as f:
            pbo_prefix = f.read().strip()

    entries = []
    for root, dirs, files in os.walk(source_dir):
        for f in files:
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, source_dir).replace('/', '\\')
            size = os.path.getsize(full_path)
            mtime = int(os.path.getmtime(full_path))
            entries.append((rel_path, full_path, size, mtime))

    # Sort entries for deterministic order
    entries.sort(key=lambda x: x[0].lower())

    pbo_bytes = bytearray()

    # 1. PBO Header Extension ('sreV' tag)
    pbo_bytes.append(0) # empty filename
    pbo_bytes.extend(struct.pack('<IIIII', 0x56657273, 0, 0, 0, 0)) # 'sreV' tag, all 0s
    
    # Prefix property: prefix\0arma_radar\0\0
    pbo_bytes.extend(b'prefix\0' + pbo_prefix.encode('utf-8') + b'\0')
    pbo_bytes.append(0) # End of properties block

    # 2. File entry headers
    for rel_path, full_path, size, mtime in entries:
        pbo_bytes.extend(rel_path.encode('utf-8') + b'\0')
        pbo_bytes.extend(struct.pack('<IIIII', 0, size, 0, mtime, size))

    # 3. End of headers entry (21 null bytes)
    pbo_bytes.append(0)
    pbo_bytes.extend(b'\0' * 20)

    # 4. File data bodies
    for rel_path, full_path, size, mtime in entries:
        with open(full_path, 'rb') as f:
            pbo_bytes.extend(f.read())

    # 5. Checksum trailer: \0 + 20-byte SHA-1 digest
    sha1 = hashlib.sha1(pbo_bytes).digest()
    pbo_bytes.append(0)
    pbo_bytes.extend(sha1)

    with open(output_pbo_path, 'wb') as f:
        f.write(pbo_bytes)

    print(f"[OK] Successfully packed {len(entries)} files into '{output_pbo_path}' (Prefix: {pbo_prefix})")

if __name__ == '__main__':
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), 'Source', 'arma_radar')
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), '@AirDefender_Radar', 'addons', 'arma_radar.pbo')
    pack_to_pbo(src, out)
