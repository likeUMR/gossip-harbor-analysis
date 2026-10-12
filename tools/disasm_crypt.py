from elftools.elf.elffile import ELFFile
from capstone import *
p=r'apk_extract/gossip_harbor_3.98.10/native_extracted/lib/arm64-v8a/libil2cpp.so'
addrs={'CryptBytes':0x111eb14,'CryptStringWithKey':0x1128640,'CryptCurrency':0x112871c,'CryptFile':0x112878c,'IsEncryptedBytes':0x111eb00,'IsEncryptedString':0x1128e44,'CryptBytesParallel':0x112281c,'Execute':0x1123d30}
f=open(p,'rb'); e=ELFFile(f); secs=list(e.iter_sections())
for n,a in addrs.items():
 s=next((s for s in secs if s['sh_addr']<=a<s['sh_addr']+s['sh_size']),None)
 if not s: continue
 off=s['sh_offset']+(a-s['sh_addr']); f.seek(off); b=f.read(500)
 print('\n###',n,hex(a),'file',hex(off))
 for i in Cs(CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN).disasm(b,a):
  print(f'{i.address:08x}: {i.mnemonic:8} {i.op_str}')
  if i.mnemonic=='ret': break
