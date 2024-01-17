import timeit
import gc

class ArgDict():
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

setup = """
gc.enable()
import os, sys
sys.path.insert(0, os.path.abspath("."))

from SIRSingleNode import test_sir

def runthemodel(**kwargs):
    params = ArgDict(**kwargs)
    test_sir(params)

r_naught = {}
pop_size = {}
initial_inf = {}
"""

n_run = 10

tt = timeit.Timer('runthemodel(r_naught=r_naught, pop_size=pop_size, initial_inf=initial_inf)', setup=setup.format(2.5, 50_000, 1))
a = tt.repeat(n_run, 1)
median_time = sorted(a)[n_run // 2 + n_run % 2]
print("Numpy-numba SIRSingleNode (ms):", median_time*1e3)
