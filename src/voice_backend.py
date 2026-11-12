import os
os.environ['HF_HUB_OFFLINE']='1'
os.environ['HF_HUB_DISABLE_TELEMETRY']='1'
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import io,json,time,wave,socket,tempfile,hashlib,fcntl,signal,uuid
from pathlib import Path
from collections import OrderedDict

ROOT=Path(tempfile.gettempdir())/'local-english-reader-voice-v1'
SOCKET=ROOT/'voice.sock'

class AudioCache:
 def __init__(self,max_entries=64,max_bytes=32*1024*1024):
  self.items=OrderedDict();self.max_entries=max_entries;self.max_bytes=max_bytes;self.size=0
 def get(self,text):
  key=hashlib.sha256(text.encode()).digest()
  if key not in self.items:return None
  self.items.move_to_end(key);return self.items[key]
 def put(self,text,audio):
  if len(audio)>self.max_bytes:return
  key=hashlib.sha256(text.encode()).digest()
  old=self.items.pop(key,None)
  if old is not None:self.size-=len(old)
  self.items[key]=audio;self.size+=len(audio)
  while len(self.items)>self.max_entries or self.size>self.max_bytes:
   _,old=self.items.popitem(last=False);self.size-=len(old)

def validate_request(request):
 text=request.get('text','').strip()
 if not text or len(text)>1500 or not any('a'<=c.lower()<='z' for c in text):raise ValueError('英文选区无效')
 output=Path(request['output']).resolve()
 parent=output.parent
 if output.name!='voice.wav' or not parent.name.startswith('local-english-reader-') or parent.parent!=Path(tempfile.gettempdir()).resolve():raise ValueError('输出位置不属于阅读器临时目录')
 if not parent.is_dir() or parent.stat().st_uid!=os.getuid():raise ValueError('输出目录无效')
 return text,output

def write_audio(output,data):
 temporary=output.parent/('.voice-'+uuid.uuid4().hex+'.pending')
 try:
  descriptor=os.open(temporary,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
  with os.fdopen(descriptor,'wb') as file:file.write(data)
  os.replace(temporary,output)
 finally:temporary.unlink(missing_ok=True)

def disconnected(conn):
 try:return conn.recv(1,socket.MSG_PEEK|socket.MSG_DONTWAIT)==b''
 except BlockingIOError:return False
 except OSError:return True

class MlxVoice:
 def __init__(self):
  import mlx.core as mx
  import numpy as np
  from mlx_audio.tts.utils import load_model
  from mlx_audio.utils import load_audio
  self.mx=mx;self.np=np
  from voice_config import load_config
  config=load_config()
  self.model=load_model(config['model_path'])
  self.ref=load_audio(config['reference_audio'],sample_rate=self.model.sample_rate)
  self.ref_text=config['reference_text']
 def generate(self,text,cancelled):
  mx=self.mx;np=self.np;mx.random.seed(20261112)
  chunks=[];tokens=0
  for part in self.model.generate(text=text,lang_code='english',ref_audio=self.ref,ref_text=self.ref_text,temperature=.7,top_k=50,top_p=1.,repetition_penalty=1.05,max_tokens=2048,verbose=False,stream=True,streaming_interval=.5):
   if cancelled():raise InterruptedError('请求已取消')
   chunks.append(part.audio);tokens+=part.token_count
  if not chunks or tokens>=2048:raise ValueError('声音为空或超过生成上限')
  audio=np.asarray(mx.concatenate(chunks))
  if not np.isfinite(audio).all() or np.max(np.abs(audio))<1e-5:raise ValueError('声音无效')
  data=io.BytesIO()
  with wave.open(data,'wb') as out:
   out.setnchannels(1);out.setsampwidth(2);out.setframerate(self.model.sample_rate)
   out.writeframes((np.clip(audio,-1,1)*32767).astype('<i2').tobytes())
  return data.getvalue()

def serve():
 os.umask(0o077)
 ROOT.mkdir(mode=0o700,exist_ok=True)
 if ROOT.is_symlink() or ROOT.stat().st_uid!=os.getuid():raise RuntimeError('后端目录无效')
 ROOT.chmod(0o700)
 with (ROOT/'server.lock').open('a') as lock:
  try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
  except BlockingIOError:return
  SOCKET.unlink(missing_ok=True)
  listener=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM)
  listener.bind(str(SOCKET));SOCKET.chmod(0o600);listener.listen(8);listener.settimeout(.5)
  try:
   engine=MlxVoice();cache=AudioCache();print('VOICE_MODEL_READY',flush=True)
   while True:
    try:conn,_=listener.accept()
    except socket.timeout:continue
    with conn:
     try:
      conn.settimeout(2);data=b''
      while not data.endswith(b'\n') and len(data)<=65536:
       part=conn.recv(4096)
       if not part:raise InterruptedError()
       data+=part
      if len(data)>65536:raise ValueError('请求过长')
      request=json.loads(data);text,output=validate_request(request);conn.setblocking(False)
      if disconnected(conn):continue
      start=time.monotonic();audio=cache.get(text);hit=audio is not None
      if audio is None:audio=engine.generate(text,lambda:disconnected(conn))
      if disconnected(conn):continue
      cache.put(text,audio)
      write_audio(output,audio)
      conn.setblocking(True);conn.settimeout(2)
      conn.sendall((json.dumps({'ok':True,'cache_hit':hit,'seconds':round(time.monotonic()-start,3)})+'\n').encode())
     except (InterruptedError,BrokenPipeError,ConnectionResetError):pass
     except Exception as exc:
      try:conn.setblocking(True);conn.settimeout(1);conn.sendall((json.dumps({'ok':False,'error':type(exc).__name__})+'\n').encode())
      except OSError:pass
  finally:listener.close();SOCKET.unlink(missing_ok=True)

if __name__=='__main__':
 def terminate(*_):raise SystemExit()
 signal.signal(signal.SIGTERM,terminate)
 serve()
