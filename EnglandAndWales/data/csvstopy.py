#! /usr/bin/env python3

from pathlib import Path

import numpy as np
import pandas as pd
from geographiclib.geodesic import Geodesic
from tqdm import tqdm

WORKING_DIR = Path(__file__).parent.absolute()

# populations.head()
#    Unnamed: 0  Abingdon  Abram  Accrington  Acton  Adlington  Adwick.le.Street  Aldeburgh  ...  Ruthin  Swansea  Tenby  Towyn  Tredegar   Usk  Welshpool  Wrexham
# 0          44      8714   5507       36850  54530       3560             17770       1678  ...    3370   138090   4336   3820     20180  1408       5585    25970
# 1          45      9350   5563       37510  57200       3592             18060       1855  ...    3526   139950   4311   3664     19920  1375       5474    25670
# 2          46     10240   5845       38670  65150       3827             19120       2205  ...    3573   148940   4387   3609     19970  1593       5714    27800
# 3          47     10070   5840       39130  65790       3871             18630       2458  ...    3528   152600   4487   3679     19720  1607       5687    28640
# 4          48     10410   5957       40180  67140       4000             18880       2555  ...    3573   158000   4537   3665     19930  1660       5817    29100

# [5 rows x 955 columns]
populations = pd.read_csv(WORKING_DIR / "ewPu4464.csv")

# births.head()
#    Year  Abingdon  Abram  Accrington  Acton  Adlington  Adwick.le.Street  Aldeburgh  ...  Ruthin  Swansea  Tenby  Towyn  Tredegar  Usk  Welshpool  Wrexham
# 0    44       159    124         570   1024         82               442         46  ...      55     2679     91     73       406   29        103      533
# 1    45       198     99         570   1043         58               392         36  ...      36     2247     77     52       376   26         87      501
# 2    46       175    103         634   1282         79               418         49  ...      44     2918     58     60       442   33        125      590
# 3    47       202    130         708   1351         80               506         44  ...      59     3324     92     58       424   39        123      655
# 4    48       185    128         687   1142         63               451         44  ...      51     2868     90     53       393   33        126      599

# [5 rows x 955 columns]
births = pd.read_csv(WORKING_DIR / "ewBu4464.csv")

# cases.head()
#        Year  Abingdon  Abram  Accrington  Acton  Adlington  Adwick.le.Street  Aldeburgh  ...  Ruthin  Swansea  Tenby  Towyn  Tredegar  Usk  Welshpool  Wrexham
# 0  44.01923         0      0           0      0          0                 0          0  ...       0        0      0      0         1    0          0        0
# 1  44.03846         0      0           0      1          0                 0          0  ...       0        0      0      0         1    0          0        1
# 2  44.05769         0      0           0      0          0                 0          0  ...       0        0      0      0         0    0          0        0
# 3  44.07692         0      0           0      0          0                 0          0  ...       0        0      0      0         2    0          0        0
# 4  44.09615         0      0           0      0          0                 0          0  ...       0        0      0      0         6    1          0        0

# [5 rows x 955 columns]
cases = pd.read_csv(WORKING_DIR / "ewMu4464.csv")

# locations.head()
#   row.names  Abingdon   Abram  Accrington   Acton  Adlington  Adwick.le.Street  Aldeburgh  ...  Ruthin  Swansea   Tenby   Towyn  Tredegar     Usk  Welshpool  Wrexham
# 0      Long    -1.285  -2.597      -2.372  -0.265     -2.598            -1.193      1.603  ...  -3.308   -3.958  -4.698  -4.078    -3.240  -2.905     -3.147   -2.993
# 1       Lat    51.673  53.508      53.752  51.510     53.617            53.562     52.152  ...  53.117   51.632  51.672  52.587    51.777  51.698     52.658   53.047

# [2 rows x 955 columns]
locations = pd.read_csv(WORKING_DIR / "ewXYu4464.csv")

print(f"Saving data to {WORKING_DIR / 'measles.py'}...")

names = sorted(populations.columns[1:])
years = sorted(births["Year"])
reports = sorted(cases["Year"])

latlong = {}

with Path(WORKING_DIR / "measles.py").open("w") as file:
    file.write("import numpy as np\n\n")
    file.write("class __Container:\n")
    file.write("    pass\n\n")
    file.write("class Place:\n")
    file.write("    def __init__(self, population, births, cases, latitude, longitude):\n")
    file.write("        self.population = population\n")
    file.write("        self.births = births\n")
    file.write("        self.cases = cases\n")
    file.write("        self.latitude = latitude\n")
    file.write("        self.longitude = longitude\n\n")
    file.write("data = __Container()\n\n")
    placenames = ", ".join(map(lambda x: f'"{x}"', names))
    file.write(f'data.placenames = [ {placenames} ]\n')
    file.write(f'data.years = np.array([ {", ".join(map(str, years))} ], dtype=np.uint32)\n')
    file.write(f'data.reports = np.array([ {", ".join(map(str, reports))} ], dtype=np.float32)\n')
    file.write('data.places = {\n')
    for i in tqdm(range(len(names))):
        place = names[i]
        file.write(f'    "{place}": Place(\n')
        file.write(f'        population=np.array([{",".join(map(str, populations[place].values))}], dtype=np.uint32),\n')
        file.write(f'        births=np.array([{",".join(map(str, births[place].values))}], dtype=np.uint32),\n')
        file.write(f'        cases=np.array([{",".join(map(str, cases[place].values))}], dtype=np.uint32),\n')
        latitude = locations.iloc[1][place]
        file.write(f'        latitude={latitude},\n')
        longitude = locations.iloc[0][place]
        file.write(f'        longitude={longitude}),\n')
        latlong[place] = (latitude, longitude)
    file.write('}\n') # close "places"

# Compute distances
distances = np.zeros((len(names), len(names)), dtype=np.float32)

geodesic = Geodesic.WGS84

print(f"Computing distances between {len(names)} locations...")
for i in tqdm(range(len(names))):
    placei = names[i]
    lat1, long1 = latlong[placei]
    for j in range(i+1, len(names)):
        placej = names[j]
        lat2, long2 = latlong[placej]
        distances[i,j] = distances[j,i] = geodesic.Inverse(lat1, long1, lat2, long2, Geodesic.DISTANCE)['s12'] / 1000  # km

binary = WORKING_DIR / "distances.npy"
print(f"Saving distances to {binary}...")
np.save(binary, distances)

...
