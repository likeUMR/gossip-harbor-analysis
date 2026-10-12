import numpy as np
z=np.load(r'analysis_output\video_motion_stats.npz'); t=z['times']; a=z['vals'];
for thr in [5,8,10,15,20,30,40]:
 act=a>thr; runs=[]; s=None
 for j,x in enumerate(act):
  if x and s is None:s=j
  if s is not None and ((not x) or j==len(act)-1):
   e=j if not x else j+1
   if e-s>=1:runs.append((t[s],t[e-1]+.5,e-s))
   s=None
 print(thr,'runs',len(runs),'active_sec',sum(r[2]*.5 for r in runs),'dur median',np.median([r[2]*.5 for r in runs]),'dur p90',np.percentile([r[2]*.5 for r in runs],90))
print('long gaps')
act=a>10; idx=np.where(act)[0]; gaps=np.diff(t[idx]); print(np.percentile(gaps,[50,75,90,95,99]),'n',len(gaps))
