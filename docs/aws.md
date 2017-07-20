### Running on AWS
Host-Subnet can run on most public clouds, we just use the more popular AWS as a demo.

Here pay attention to one step key operation,
Due to the security mechanism of AWS, it is necessary to disable the src/dst check of all the agent hosts, and the other clouds are according to their own situation:
![](https://ws2.sinaimg.cn/mw1024/006tKfTcly1fho07y2r0uj317k0bwdgo.jpg)

Then you can follow the deployment steps described above.

Please note in AWS, VPC RouteTable needs to be updated as follow:
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnzmzasbsj30vi0jwab4.jpg)

