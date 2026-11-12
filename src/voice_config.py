"""Load local-only voice settings. Never bundle real voice settings in a release."""
import json
import os
from pathlib import Path

CONFIG_PATH = Path.home() / 'Library/Application Support/LocalEnglishReader/voice.json'

def load_config(path=None):
    data = json.loads(Path(path or CONFIG_PATH).read_text())
    for key in ('python', 'model_path', 'reference_audio', 'reference_text'):
        if not isinstance(data.get(key), str) or not data[key].strip():
            raise ValueError('Voice settings are incomplete')
    for key in ('python', 'model_path', 'reference_audio'):
        if not Path(data[key]).is_absolute():
            raise ValueError('Voice paths must be absolute')
    if not Path(data['python']).is_file() or not os.access(data['python'], os.X_OK):
        raise ValueError('Python executable is unavailable')
    if not Path(data['model_path']).is_dir():
        raise ValueError('Local model directory is unavailable')
    if not Path(data['reference_audio']).is_file():
        raise ValueError('Reference audio is unavailable')
    return data
