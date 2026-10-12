import cv2, numpy as np
p=r'analysis_output\video_motion.mp4'; cap=cv2.VideoCapture(p); fps=cap.get(cv2.CAP_PROP_FPS); vals=[]; prev=None; times=[]; i=0
while True:
 ok,fr=cap.read()
 if not ok: break
 g=fr
 if prev is not None: vals.append(float(np.mean(cv2.absdiff(g,prev)))); times.append(i/fps)
 prev=g;i+=1
cap.release(); a=np.array(vals); print('fps',fps,'n',len(a),'mean',a.mean(),'p50',np.percentile(a,50),'p75',np.percentile(a,75),'p90',np.percentile(a,90),'p99',np.percentile(a,99))
np.savez_compressed(r'analysis_output\video_motion_stats.npz',times=np.array(times),vals=a)
