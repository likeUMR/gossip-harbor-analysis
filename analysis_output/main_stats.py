import numpy as np
from scipy.signal import find_peaks
z=np.load(r'analysis_output\video_color_stats.npz');t=z['times'];a=z['motion'];b=z['blue'];main=(b>.3)&(np.r_[False,b[:-1]>.3]); x=a.copy(); x[~main]=0
print('main sec',main.sum()/2,'motion p',np.percentile(x[main],[50,75,90,95,99]))
for thr in [3,5,8,10,15,20,30]:
 act=(x>thr); runs=[];s=None
 for j,q in enumerate(act):
  if q and s is None:s=j
  if s is not None and ((not q) or j==len(act)-1):
   e=j if not q else j+1
   if e-s>=1:runs.append((t[s],t[e-1]+.5,e-s))
   s=None
 d=np.array([r[2]/2 for r in runs]); print(thr,'runs',len(d),'active',d.sum(),'dur med/p75',np.median(d) if len(d) else 0,np.percentile(d,75) if len(d) else 0)
# peak intervals within main
s=np.convolve(x,np.ones(3)/3,'same');pk,_=find_peaks(s,distance=2,prominence=5)
pk=pk[main[pk]];ints=np.diff(t[pk]); ints=ints[ints<30]; print('peaks',len(pk),'int',np.percentile(ints,[10,25,50,75,90]),'mean',ints.mean())
