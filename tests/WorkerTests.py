import unittest
from voice import validate
class Inputs(unittest.TestCase):
 def test_empty(self):
  with self.assertRaises(ValueError): validate('  ')
 def test_no_english(self):
  with self.assertRaises(ValueError): validate('变量')
 def test_over_limit(self):
  with self.assertRaises(ValueError): validate('a'*1501)
 def test_literal_shell_text_preserved(self):
  self.assertEqual(validate('  return $(touch /tmp/not-to-run)  '),'return $(touch /tmp/not-to-run)')
if __name__=='__main__': unittest.main()
