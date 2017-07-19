Rancher Host-subnet Networking
=================================

#### About Host-subnet Networking
Rancher now has IPsec/VXLAN networking belongs to the Overlay model, although there is a good scalability, but the performance is not good.
Especially when it is running in the Cloud environment, since the VM networking may be already Overlay model, 
so there will be nested Overlay, which leads to greater performance loss.

Host-subnet network is to solve this problem, while taking full advantage of the Cloud environment itself.
Its main principle is that in each Agent node containers have a separate subnet, 
different hosts different subnet containers connected together in the Router through the route tables.
Because there is no Overlay loss, the network performance is extremely high in this case. 
![](https://ws3.sinaimg.cn/mw1024/006tKfTcly1fhoembsca6j31kw0xe427.jpg)
