import cv2, numpy as np, json, os
p=r'C:\Users\TU\Documents\xwechat_files\wxid_efy8socw73jk22_346e\msg\file\2026-09\share_video_tmp_3dfafdc66440676599f91a1d8c4b6bf01'
cap=cv2.VideoCapture(p)
fps=cap.get(cv2.CAP_PROP_FPS); n=int(cap.get(cv2.CAP_PROP_FRAME_COUNT)); dur=n/fps
print(fps,n,dur)
# process every 6 frames ~4.1 fps, ROI central board x 0:1200 y 700:2200
step=6; times=[]; vals=[]; prev=None; i=0
while True:
 ok,fr=cap.read()
 if not ok: break
 if i%step==0:
  g=cv2.cvtColor(fr[650:2200,:],cv2.COLOR_BGR2GRAY)
  g=cv2.resize(g,(300,388))
  if prev is not None:
   vals.append(float(np.mean(cv2.absdiff(g,prev))))
   times.append(i/fps)
  prev=g
 i+=1
cap.release()
arr=np.array(vals); print('samples',len(arr),'mean',arr.mean(),'p50',np.percentile(arr,50),'p90',np.percentile(arr,90),'p99',np.percentile(arr,99))
np.savez_compressed(r'analysis_output\video_motion.npz',times=np.array(times),vals=arr)
# intervals above threshold
thr=max(np.percentile(arr,75),2.0); active=arr>thr
# runs
runs=[]; s=None
for j,a in enumerate(active):
 if a and s is None:s=j
 if s is not None and (not a or j==len(active)-1):
  e=j if not a else j+1
  if e-s>=1:runs.append((times[s],times[e-1],e-s))
  s=None
print('thr',thr,'runs',len(runs),'first',runs[:20])
