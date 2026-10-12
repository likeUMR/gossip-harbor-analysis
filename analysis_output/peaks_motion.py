import numpy as np
from scipy.signal import find_peaks
z=np.load(r'analysis_output\video_motion_stats.npz'); t=z['times']; a=z['vals']
# smooth 3 samples, peaks prominence
s=np.convolve(a,np.ones(3)/3,'same')
for prom in [5,10,20,30]:
 pk,_=find_peaks(s,distance=2,prominence=prom)
 intervals=np.diff(t[pk]); print('prom',prom,'peaks',len(pk),'int median',np.median(intervals),'p25/p75',np.percentile(intervals,[25,75]),'lt3',np.mean(intervals<3),'lt2',np.mean(intervals<2))
 print('dur active around peak median',np.median(s[pk]),'p90',np.percentile(s[pk],90))
