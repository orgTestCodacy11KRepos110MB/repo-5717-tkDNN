# Monocular depth estimation with tkDNN

Currently tkDNN supports only Monodepth2 as monocular depth esitmation network.


## Run the demo

To run the depth estimation demo follow these steps (example with monodepth2):
```
rm monodepth2_fp32.rt        # be sure to delete(or move) old tensorRT files
./test_monodepth2            # run the yolo test (is slow)
./demoDepth monodepth2_fp32.rt ../demo/yolo_test.mp4 
```
In general the demo program takes the following parameters:
```
./demoDepth <network-rt-file> <path-to-video> <show-flag> <save-flag>
```
where
*  ```<network-rt-file>``` is the rt file generated by a test
*  ```<<path-to-video>``` is the path to a video file or a camera input  
*  ```<show-flag>``` if set to 0 the demo will not show the visualization, it will otherwise (default=1)
*  ```<save-flag>``` if set to 1 the demo will save the video into result.mp4, it won't otherwise (default=1)

NB) By default it is used FP32 inference


![demo](https://user-images.githubusercontent.com/11939259/160845358-0d6ab15d-c5f4-46ae-b9da-bfaf3903389d.gif "Results on yolo_test.mp4")  


<!-- ## FPS Results

Inference FPS of shelfnet with tkDNN, average of 1200 images on:
  * RTX 2080Ti (CUDA 10.2, TensorRT 7.0.0, Cudnn 7.6.5);
  * Xavier AGX, Jetpack 4.3 (CUDA 10.0, CUDNN 7.6.3, tensorrt 6.0.1 );

| Platform   | Test                     | Phase   | FP32, ms  | FP32, FPS | FP16, ms  |	FP16, FPS  | INT8, ms |	INT8, FPS | 
| :------:   | :-----:                  | :-----: | :-----:   | :-----:   | :-----:   |	:-----:    | :-----:  |	:-----:   | 
| RTX 2080Ti | shelfnet 1024x1024 (B=1) | pre     | 6.11863   |  163.435  |   5.81465 |  171.979   |  5.88699 |   169.866 |
| RTX 2080Ti | shelfnet 1024x1024 (B=1) | inf     | 11.5464   |  86.6074  |   7.35396 |  135.981   |  6.37623 |   156.832 |
| RTX 2080Ti | shelfnet 1024x1024 (B=1) | post    | 4.09058   |  244.464  |   3.91961 |  255.128   |  4.07343 |   245.493 |
| RTX 2080Ti | shelfnet 1024x1024 (B=1) | tot     | 21.7556   |  45.9652  |   17.0882 |  58.5199   |  16.3366 |   61.2121 |
| RTX 2080Ti | shelfnet 2048x2048 (B=4) | pre     | 25.435    |  39.3158  |   25.2953 |  39.5331   |  25.9303 |   38.565  | 
| RTX 2080Ti | shelfnet 2048x2048 (B=4) | inf     | 36.5015   |  27.3961  |   17.0534 |  58.6395   |  15.6061 |   64.0773 |  
| RTX 2080Ti | shelfnet 2048x2048 (B=4) | post    | 17.3917   |  57.4985  |   17.1649 |  58.2583   |  17.5539 |   56.9675 |  
| RTX 2080Ti | shelfnet 2048x2048 (B=4) | tot     | 79.3283   |  12.6058  |   59.5136 |  16.8029   |  59.0903 |   16.9233 |  
| AGX Xavier | shelfnet 1024x1024 (B=1) | pre     | 8.0174    |  124.729  |   7.5117  |  133.126   |  7.47333 |   133.809 |
| AGX Xavier | shelfnet 1024x1024 (B=1) | inf     | 72.4173   |  13.8089  |   37.505  |  26.6631   |  31.3286 |   31.9197 |
| AGX Xavier | shelfnet 1024x1024 (B=1) | post    | 8.89958   |  112.365  |   8.83576 |  113.176   |  9.42655 |   106.083 |
| AGX Xavier | shelfnet 1024x1024 (B=1) | tot     | 89.3342   |  11.1939  |   53.8525 |  18.5692   |  48.2285 |   20.7346 |
| AGX Xavier | shelfnet 2048x2048 (B=4) | pre     | 47.1454   |  21.211   |   21.6475 |  46.1947   |  21.4201 |   46.6851 | 
| AGX Xavier | shelfnet 2048x2048 (B=4) | inf     | 266.537   |  3.75183  |   128.321 |  7.79293   |  107.621 |   9.29185 |  
| AGX Xavier | shelfnet 2048x2048 (B=4) | post    | 44.0711   |  22.6906  |   40.1732 |  24.8922   |  39.873  |   25.0796 |  
| AGX Xavier | shelfnet 2048x2048 (B=4) | tot     | 357.753   |  2.79522  |   190.142 |  5.25922   |  168.914 |   5.92016 |   -->

