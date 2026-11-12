import json
import tempfile
import unittest
from pathlib import Path
from voice_config import load_config

class ConfigurationTests(unittest.TestCase):
    def test_missing_config_does_not_use_a_builtin_voice(self):
        with self.assertRaises(FileNotFoundError):
            load_config('/nonexistent/voice.json')

    def test_incomplete_and_remote_paths_are_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'voice.json'
            p.write_text('{}')
            with self.assertRaises(ValueError): load_config(p)
            p.write_text(json.dumps(dict(python='https://example.invalid/python',model_path='model',reference_audio='voice.wav',reference_text='example')))
            with self.assertRaises(ValueError): load_config(p)

    def test_separate_local_files_are_required(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            python=root/'python'; python.write_text('test fixture'); python.chmod(0o700)
            model=root/'model'; model.mkdir()
            ref=root/'sample.wav'; ref.write_bytes(b'fixture only')
            settings=dict(python=str(python),model_path=str(model),reference_audio=str(ref),reference_text='This is a test.')
            p=root/'voice.json';p.write_text(json.dumps(settings))
            self.assertEqual(load_config(p)['reference_text'],'This is a test.')
            ref.unlink()
            with self.assertRaises(ValueError): load_config(p)

if __name__=='__main__': unittest.main()
