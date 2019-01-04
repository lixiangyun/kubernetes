# keepalived

## Keepalived简介
Keepalived是Linux下一个轻量级别的高可用解决方案。高可用：广义来讲，是指整个系统的高可用行；狭义的来讲就是主机的冗余和接管。

它与HeartBeat实现类似的功能，都可以实现服务或者网络的高可用，但是又有差别，HeartBeat是一个专业的、功能完善的高可用软件，它提供HA软件所需的基本功能，比如：心跳检测、资源接管，检测集群中的服务，在集群节点转移共享IP地址的所有者等等。HeartBeat功能强大，但是部署和使用相对比较麻烦，与HeartBeat相比，Keepalived主要是通过虚拟路由冗余来实现高可用功能，虽然它没有HeartBeat功能强大，但是Keepalived部署和使用非常的简单，所有配置只需要一个配置文件即可以完成。


## Keepalived是什么？
Keepalived起初是为LVS设计的，专门用来监控集群系统中各个服务节点的状态，它根据TCP/IP参考模型的第三、第四层、第五层交换机制检测每个服务节点的状态，如果某个服务器节点出现异常，或者工作出现故障，Keepalived将检测到，并将出现的故障的服务器节点从集群系统中剔除，这些工作全部是自动完成的，不需要人工干涉，需要人工完成的只是修复出现故障的服务节点。

后来Keepalived又加入了VRRP的功能，VRRP（VritrualRouterRedundancyProtocol,虚拟路由冗余协议)出现的目的是解决静态路由出现的单点故障问题，通过VRRP可以实现网络不间断稳定运行，因此Keepalvied一方面具有服务器状态检测和故障隔离功能，另外一方面也有HAcluster功能。

健康检查和失败切换是keepalived的两大核心功能。所谓的健康检查，就是采用tcp三次握手，icmp请求，http请求，udp echo请求等方式对负载均衡器后面的实际的服务器(通常是承载真实业务的服务器)进行保活；而失败切换主要是应用于配置了主备模式的负载均衡器，利用VRRP维持主备负载均衡器的心跳，当主负载均衡器出现问题时，由备负载均衡器承载对应的业务，从而在最大限度上减少流量损失，并提供服务的稳定性。

## VRRP协议与工作原理
在现实的网络环境中。主机之间的通信都是通过配置静态路由或者(默认网关)来完成的，而主机之间的路由器一旦发生故障，通信就会失效，因此这种通信模式当中，路由器就成了一个单点瓶颈，为了解决这个问题，就引入了VRRP协议。

VRRP协议是一种容错的主备模式的协议，保证当主机的下一跳路由出现故障时，由另一台路由器来代替出现故障的路由器进行工作，通过VRRP可以在网络发生故障时透明的进行设备切换而不影响主机之间的数据通信。 

![](https://img-blog.csdn.net/20180828100250135?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzI0MzM2Nzcz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

**虚拟路由器**：虚拟路由器是VRRP备份组中所有路由器的集合，它是一个逻辑概念，并不是正真存在的。从备份组外面看备份组中的路由器，感觉组中的所有路由器就像一个 一样，可以理解为在一个组中： 主路由器+所有备份路由器=虚拟路由器。虚拟路由器有一个虚拟的IP地址和MAC地址。主机将虚拟路由器当作默认网关。虚拟MAC地址的格式为00-00-5E-00-01-{VRID}。通常情况下，虚拟路由器回应ARP请求使用的是虚拟MAC地址，只有虚拟路由器做特殊配置的时候，才回应接口的真实MAC地址。

**主路由器（MASTER）**：虚拟路由器通过虚拟IP对外提供服务，而在虚拟路由器内部同一时间只有一台物理路由器对外提供服务，这台提供服务的物理路由器被称为主路由器。一般情况下Master是由选举算法产生，它拥有对外服务的虚拟IP，提供各种网络功能，如：ARP请求，ICMP数据转发等。

**备份路由器（BACKUP）**：虚拟路由器中的其他物理路由器不拥有对外的虚拟IP，也不对外提供网络功能，仅接受MASTER的VRRP状态通告信息，这些路由器被称为备份路由器。当主路由器失败时，处于BACKUP角色的备份路由器将重新进行选举，产生一个新的主路由器进入MASTER角色，继续提供对外服务，整个切换对用户来说是完全透明的。


## VRRP选举机制
VRRP路由器在运行过程中有三种状态：
 
1. Initialize状态：系统启动后就进入Initialize，此状态下路由器不对VRRP报文做任何处理； 
2. Master状态；
3. Backup状态；

一般主路由器处于Master状态，备份路由器处于Backup状态。

VRRP使用选举机制来确定路由器的状态，优先级选举： 

1. VRRP组中IP拥有者。如果虚拟IP地址与VRRP组中的某台VRRP路由器IP地址相同，则此路由器为IP地址拥有者，这台路由器将被定位主路由器。 
2. 比较优先级。如果没有IP地址拥有者，则比较路由器的优先级，优先级的范围是0~255，优先级大的作为主路由器 
3. 比较IP地址。在没有Ip地址拥有者和优先级相同的情况下，IP地址大的作为主路由器。

如下图所示，虚拟IP为10.1.1.254，在VRRP组中没有IP地址拥有者，则比较优先级，很明显RB和RA的优先级要大于RC，则比较RA和RB的IP地址，RB的IP地址大。所以RB为组中的主路由器。 

![](https://img-blog.csdn.net/201808281005027?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzI0MzM2Nzcz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

## 工作过程
路由器使用VRRP 功能后，会根据优先级确定自己在备份组中的角色。优先级高的路由器成为Master 路由器，优先级低的成为Backup 路由器。Master 拥有对外服务的虚拟IP，提供各种网络功能，并定期发送VRRP 报文，通知备份组内的其他设备自己工作正常；Backup 路由器只接收Master 发来的报文信息，用来监控Master 的运行状态。当Master 失效时，Backup 路由器进行选举，优先级高的Backup 将成为新的Master 。

在抢占方式下，当Backup 路由器收到VRRP 报文后，会将自己的优先级与报文中的优先级进行比较。如果大于通告报文中的优先级，则成为Master 路由器；否则将保持Backup状态；

在非抢占方式下，只要Master 路由器没有出现故障，备份组中的路由器始终保持Master 或Backup 状态，Backup 路由器即使随后被配置了更高的优先级也不会成为Master 路由器；

如果Backup 路由器的定时器超时后仍未收到Master 路由器发送来的VRRP报文，则认为Master 路由器已经无法正常工作，此时Backup 路由器会认为自己是Master 路由器，并对外发送VRRP报文。备份组内的路由器根据优先级选举出Master 路由 器，承担报文的转发功能。

## Keepalvied的工作原理
Keepalived对服务器运行状态和故障隔离的工作原理： 
Keepalived工作在TCP/IP参考模型的三层、四层、五层（物理层，链路层）： 

**网络层（3）**：Keepalived通过ICMP协议向服务器集群中的每一个节点发送一个ICMP数据包(有点类似与Ping的功能)，如果某个节点没有返回响应数据包，那么认为该节点发生了故障，Keepalived将报告这个节点失效，并从服务器集群中剔除故障节点。

**传输层（4）**：Keepalived在传输层里利用了TCP协议的端口连接和扫描技术来判断集群节点的端口是否正常，比如对于常见的WEB服务器80端口。或者SSH服务22端口，Keepalived一旦在传输层探测到这些端口号没有数据响应和数据返回，就认为这些端口发生异常，然后强制将这些端口所对应的节点从服务器集群中剔除掉。

**应用层（5）**：Keepalived的运行方式也更加全面化和复杂化，用户可以通过自定义Keepalived工作方式，例如：可以通过编写程序或者脚本来运行Keepalived，而Keepalived将根据用户的设定参数检测各种程序或者服务是否允许正常，如果Keepalived的检测结果和用户设定的不一致时，Keepalived将把对应的服务器从服务器集群中剔除。

## Keepalived体系结构
Keepalived起初是为LVS设计的，由于Keeplalived可以实现对集群节点的状态检测，而IPVS可以实现负载均衡功能，因此,Keepalived借助于第三方模块IPVS就可以很方便地搭建一套负载均衡系统。在Keepalived当中IPVS模块是可配置的，如果需要负载均衡功能，可以在编译Keepalived时开打负载均衡功能，也可以通过编译参数关闭。 

![](https://img-blog.csdn.net/20180828101045216?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzI0MzM2Nzcz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

**SchedulerI/OMultiplexer**：是一个I/O复用分发调度器，它负载安排Keepalived所有内部的任务请求；

**Memory Mngt**：是一个内存管理机制，这个框架提供了访问内存的一些通用方法；

**Control Plane**：是keepalived的控制版面，可以实现对配置文件编译和解析；

**Core componets**：这部分主要包含了5个部分；

- Watchdog：是计算机可靠领域中极为简单又非常有效的检测工具，Keepalived正是通过它监控Checkers和VRRP进程的。
- Checkers:这是Keepalived最基础的功能，也是最主要的功能，可以实现对服务器运行状态检测和故障隔离。
- VRRP Stack:这是keepalived后来引用VRRP功能，可以实现HA集群中失败切换功能。负责负载均衡器之间的失败切换- FailOver；
- IPVS wrapper:这个是IPVS功能的一个实现，IPVSwarrper模块将可以设置好的IPVS规则发送的内核空间并且提供给IPVS模块，最终实现IPVS模块的负载功能。
- Netlink Reflector：用来实现高可用集群Failover时虚拟IP(VIP)的设置和切换。

keepalived运行时，会启动3个进程，分别为：core(核心进程)，check和vrrp；

- core：负责主进程的启动，维护和全局配置文件的加载； 
- check：负责健康检查 
- vrrp：用来实现vrrp协议

## 与heartbeat/corosync等比较
　　Heartbeat、Corosync、Keepalived这三个集群组件我们到底选哪个好，Heartbeat、Corosync是属于同一类型，Keepalived与Heartbeat、Corosync，根本不是同一类型的。Keepalived使用的vrrp虚拟路由冗余协议方式；Heartbeat或Corosync是基于主机或网络服务的高可用方式；简单的说就是，Keepalived的目的是模拟路由器的高可用，Heartbeat或Corosync的目的是实现Service的高可用。 
　　 
　　所以一般Keepalived是实现前端高可用，常用的前端高可用的组合有，就是我们常见的LVS+Keepalived、Nginx+Keepalived、HAproxy+Keepalived。而Heartbeat或Corosync是实现服务的高可用，常见的组合有Heartbeat v3(Corosync)+Pacemaker+NFS+Httpd 实现Web服务器的高可用、Heartbeat v3(Corosync)+Pacemaker+NFS+MySQL 实现MySQL服务器的高可用。总结一下，Keepalived中实现轻量级的高可用，一般用于前端高可用，且不需要共享存储，一般常用于两个节点的高可用。而Heartbeat(或Corosync)一般用于服务的高可用，且需要共享存储，一般用于多节点的高可用。

## 配置说明



## 配置举例

