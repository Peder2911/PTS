
from typing import Set

import pandas as pd

pts = pd.read_csv("data/PTS-2019.csv")
uos = pd.read_csv("data/ucdp-onesided-201.csv")

#========================================================
# Fix UCDP data

uos = uos[["year","gwno_location","best_fatality_estimate"]]

rows = []
for _,r in uos.iterrows():
    locations = [int(c) for c in r["gwno_location"].split(",")]
    fatalities = int(r["best_fatality_estimate"] / len(locations))
    for l in locations:
        rows.append({"year":r["year"],"cow":l,"fatalities":fatalities})

uos = pd.DataFrame(rows)
uos = uos.groupby(by=["year","cow"]).sum()

#========================================================
# Fix PTS data

print("Raw PTS missingness")
for v in "PTS_A","PTS_H","PTS_S":
    prop = pts[v].isna().sum() / pts.shape[0]
    print(f"\t{v}:{prop}")

pts = pts[pts["Year"] >= min([yr for yr,_ in uos.index.values])]
rows = []
for _,r in pts.iterrows():
    pts = r["PTS_H"] if not pd.isna(r["PTS_H"]) else r["PTS_A"]
    pts = r["PTS_S"] if pd.isna(pts) else pts
    rows.append({"year":r["Year"],"cow":r["COW_Code_N"],"pts":pts})

pts = pd.DataFrame(rows)
print(f"\tFinal missingness: {pts['pts'].isna().sum() / pts.shape[0]}")
pts = pts.dropna()
pts = pts.groupby(["year","cow"]).max()

#========================================================
# Merging

getloc = lambda df: {int(l) for _,l in df.index.values}
allLocations = getloc(uos).union(getloc(pts))

mkSkeleton = lambda cow: pd.DataFrame(index=pd.MultiIndex.from_product([[*range(1989,2019)],(cow,)],names=("year","cow")))

skeletons = {c:mkSkeleton(c) for c in allLocations}
locData = []
for c,skel in skeletons.items():
    data = (mkSkeleton(c)
                .merge(uos,left_index=True,right_index=True,how="left")
                .merge(pts,left_index=True,right_index=True,how="left")
            ) 
    data["fatalities"] = data["fatalities"].fillna(0)
    data["pts"] = data["pts"].interpolate("linear")
    locData.append(data)

allData = pd.concat(locData)
assert allData.shape[0] == len(set(allData.index.values))
assert len(set(allData.groupby(level=0).size())) == 1
assert len(set(allData.groupby(level=1).size())) == 1

allData.to_csv("cache/data.csv")
