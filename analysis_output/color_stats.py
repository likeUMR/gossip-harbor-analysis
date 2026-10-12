import cv2,numpy as np
cap=cv2.VideoCapture(r'analysis_output\video_color.mp4');fps=cap.get(cv2.CAP_PROP_FPS); prev=None; vals=[]; blue=[]; times=[];i=0
while 1:
 ok,fr=cap.read()
 if not ok:break
 hsv=cv2.cvtColor(fr,cv2.COLOR_BGR2HSV); # blue board approximate H 80-130, sat >45
 mask=((hsv[:,:,0]>80)&(hsv[:,:,0]<125)&(hsv[:,:,1]>45)&(hsv[:,:,2]>60)); blue.append(mask.mean())
 if prev is not None: vals.append(np.mean(cv2.absdiff(cv2.cvtColor(fr,cv2.COLOR_BGR2GRAY),cv2.cvtColor(prev,cv2.COLOR_BGR2GRAY))))
 prev=fr;times.append(i/fps);i+=1
cap.release(); a=np.array(vals); b=np.array(blue); print('n',len(b),'blue p',np.percentile(b,[10,25,50,75,90]),'corr',np.corrcoef(a,b[1:])[0,1]);
for cut in [.05,.1,.15,.2,.25]: print(cut,'secs',sum(b>cut)/fps)
np.savez_compressed(r'analysis_output\video_color_stats.npz',times=np.array(times),motion=np.r_[0,a],blue=b)
