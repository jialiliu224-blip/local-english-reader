import os
os.environ['HF_HUB_OFFLINE']='1'
os.environ['HF_HUB_DISABLE_TELEMETRY']='1'
import sys, json
from pathlib import Path

def validate(text):
    text=text.strip()
    if not text: raise ValueError('请先选中或输入英文。')
    if len(text)>1500: raise ValueError('一次请选中不超过 1500 个字符。')
    if not any('a' <= c.lower() <= 'z' for c in text): raise ValueError('请选中包含英文的文本。')
    return text

def main():
    import socket,time,tempfile
    request=json.loads(Path(sys.argv[1]).read_text())
    request['text']=validate(request['text'])
    endpoint=str(Path(tempfile.gettempdir())/'local-english-reader-voice-v1'/'voice.sock')
    start=time.monotonic();conn=None
    while time.monotonic()-start<30:
        try:
            conn=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM);conn.settimeout(1);conn.connect(endpoint);break
        except OSError:
            if conn:conn.close()
            conn=None;time.sleep(.1)
    if conn is None:raise RuntimeError('语音后端尚未就绪，请重试')
    with conn:
        conn.settimeout(180);conn.sendall((json.dumps(request)+'\n').encode())
        response=b''
        while not response.endswith(b'\n') and len(response)<8192:
            part=conn.recv(4096)
            if not part:raise RuntimeError('语音后端连接结束')
            response+=part
        result=json.loads(response)
        if not result.get('ok'):raise RuntimeError('本机声音生成失败')
        print(json.dumps(result),flush=True)

if __name__=='__main__':main()
