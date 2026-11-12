"""Check the source release allowlist without printing potentially sensitive matches."""
import hashlib
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
FIXED={'AGENTS.md','.gitignore','README.md','PRIVACY.md','LICENSE','THIRD_PARTY_NOTICES.md',
       'requirements.txt','voice.example.json','Info.plist','CONTRIBUTING.md',
       'docs/RELEASE_DRAFT.md','scripts/build.sh','scripts/test.sh','scripts/check_public.py'}
PATTERNS=[re.compile(r'/'+'Users/[^\s"\x27]+'),
          re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
          re.compile(r'\bsk-(?:proj-)?[A-Za-z0-9_-]{16,}'),
          re.compile(r'\bgh[pousr]_[A-Za-z0-9]{20,}'),
          re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b')]

def public_files():
    files=[]
    for p in sorted(ROOT.rglob('*')):
        rel=p.relative_to(ROOT)
        if rel.parts[0] in ('build','.git'): continue
        if p.is_symlink(): raise ValueError('Symlink is not allowed')
        if p.is_dir(): continue
        if rel.as_posix() not in FIXED and not (len(rel.parts)==2 and rel.parts[0] in ('src','tests') and p.suffix in ('.swift','.py')):
            raise ValueError('Unexpected release file: '+rel.as_posix())
        content=p.read_text(encoding='utf-8')
        if any(pattern.search(content) for pattern in PATTERNS):
            raise ValueError('Review required: '+rel.as_posix())
        files.append((rel.as_posix(),p))
    return files

if __name__=='__main__':
    files=public_files()
    print('PASS: source allowlist and common sensitive-data pattern checks; files='+str(len(files)))
    for name,p in files: print(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+name)
