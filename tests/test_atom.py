import sys
from os.path import dirname, join
sys.path.insert(0, join(dirname(dirname(__file__)), "build"))

import libpd

libpd.test_Atom()
