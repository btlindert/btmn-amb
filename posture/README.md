Posture
======

Posture is classified using the accelerometer signals from one sensor at the chest and one at the thigh. 
Each of the sensor records bodily movement and gravitational acceleration along 3 perpendicular axis.
In the absence of bodily movement, the output along all 3 axes is equal to the direction of gravity. The orientation of the sensor relative to gravity can then be calculated.
Under the assumption of a fixed position of the sensor relative to the body part, we can infer body part orientation relative to gravity.
From the orientation of body parts we can then finally infer a body posture.

The inclination of the chest sensor is used to estimate upright vs sitting/supine posture. The additional sensor at the 
left upper thigh is then used to differentiate between sitting and lying. If lying down, the chest sensor is again used to estimate 
prone, supine, left and right lying.

From the above it's clear that we make several assumptions. To reduce the number of assumptions one can run a training protocol in each participant to 
get individual orientations of sensors relative to body parts. Unfortunately we lacks such a training sessions. 
Therefore we resort to fixed threshold classification of body posture with the corresponding reduction in accuracy.

## Sensor axes in normal placement
In normal placement the axes of the sensors are oriented as described below.
	
### Chest - upright
In upright posture, with the sensor placed near the sternum:

Axis | Direction | Positive  | Negative
-----|-----------|-----------|---------
x    | vertical  | down      | up
y    | lateral   |
z    | ant/post  | posterior | anterior

To estimate forward or backward inclination of the body, we use the angle between the vertical (x) axis and gravity.
We choose positive (down) x-axis direction: [1, 0, 0].

### Chest - supine
In supine posterior, the transverse angle is calculated relative to the posterior (positive z-axis) direction [0, 0, 1]. I.e. in supine 
posture the angle should be near 0 degrees.

### Thigh - upright
In upright posture, with the sensor placed on the lateral upper left thigh: 

Axis | Direction | Positive  | Negative
-----|-----------|-----------|---------
x    | vertical  | down      | up
y    | ant/post  |           |  
z    | lateral   |           |
 






 



