import unittest
from voice_backend import AudioCache, validate_request, write_audio
class BackendTests(unittest.TestCase):
 def test_cache_reuses_exact_phrase(self):
  cache=AudioCache(max_entries=2,max_bytes=20);cache.put('Variable',b'wave')
  self.assertEqual(cache.get('Variable'),b'wave');self.assertIsNone(cache.get('variable'))
 def test_cache_evicts_oldest_and_bounds_memory(self):
  cache=AudioCache(max_entries=2,max_bytes=8)
  cache.put('a',b'1234');cache.put('b',b'5678');cache.get('a');cache.put('c',b'abcd')
  self.assertIsNone(cache.get('b'));self.assertEqual(cache.get('a'),b'1234')
  cache.put('huge',b'0'*9);self.assertIsNone(cache.get('huge'))
 def test_write_does_not_follow_existing_pending_link(self):
  import tempfile
  from pathlib import Path
  with tempfile.TemporaryDirectory(prefix='local-english-reader-') as directory:
   root=Path(directory);victim=root/'original';victim.write_bytes(b'keep')
   (root/'voice.pending').symlink_to(victim)
   write_audio(root/'voice.wav',b'new audio')
   self.assertEqual(victim.read_bytes(),b'keep');self.assertEqual((root/'voice.wav').read_bytes(),b'new audio')
 def test_rejects_non_app_output(self):
  with self.assertRaises(ValueError):validate_request({'text':'return','output':'/not-a-reader-directory/file.wav'})
 def test_rejects_empty_text(self):
  with self.assertRaises(ValueError):validate_request({'text':' ','output':'/tmp/voice.wav'})
if __name__=='__main__':unittest.main()
