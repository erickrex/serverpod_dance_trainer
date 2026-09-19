import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('extract_poses', Path(__file__).parents[1] / 'extract_poses.py')
m = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = m
spec.loader.exec_module(m)

class OutputSafetyTests(unittest.TestCase):
    def test_archival_destination_rejected(self):
        source = Path(m.__file__).resolve().parents[3] / 'content/source/test'
        with self.assertRaises(ValueError):
            m.validate_output_paths(source, 'test')

    def test_existing_file_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            p = Path(directory) / 'routine.json'
            p.write_text('original')
            with self.assertRaises(FileExistsError):
                m.validate_output_paths(Path(directory), 'routine')
            self.assertEqual(p.read_text(), 'original')

    def test_traversal_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                m.validate_output_paths(Path(directory), '../source/routine')

    def test_symlink_to_archive_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            link = Path(directory) / 'alias'
            link.symlink_to(Path(m.__file__).resolve().parents[3] / 'content/source', target_is_directory=True)
            with self.assertRaises(ValueError):
                m.validate_output_paths(link, 'routine')

if __name__ == '__main__': unittest.main()
