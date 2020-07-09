# DHCP (Win Srv) template for Zabbix

This template will discover and check used IP percentage in each scope. It also include performance counter for requests/releases.

## Performance Counter

There are a number of Performance Monitor counters that are related specifically to the DHCP services. You can use these counters not only to see how well your DHCP server is performing, but also the number of requests being received by the DHCP server at a given time.

### DHCPDISCOVER

One way that you can measure the load that is being placed on your DHCP server is to look at how frequently it receives a DHCPDISCOVER packet. When a client is initially brought online, it has no IP address and no knowledge of DHCP servers on your network. Consequently, it will transmit a DHCPDISCOVER packet in an effort to detect DHCP servers on your network.

### DHCPOFFER

Because DHCPOFFER packets are transmitted in response to DHCPDISCOVER packets, the number of DHCPOFFER packets sent each second should roughly mirror the number of DHCPDISCOVER packets sent each second. If the number of DHCPOFFER packets seems low compared to the number of DHCPDISCOVER packets, then the server may have a performance bottleneck that needs to be addressed.

### DHCPREQUEST

When a client initiates a DHCPDISCOVER, It is possible that the client may receive multiple DHCPOFFER messages (assuming that there are multiple DHCP servers on the network). For this reason, the client must choose which DHCP server it wishes to lease an IP address from. The client does this by transmitting a DHCPREQUEST packet to the desired DHCP server.

### DHCPACK

When a DHCP server receives a DHCPREQUEST packet, the server replies with a DHCPACK packet. This is an acknowledgement packet that the DHCP server sends to the client to confirm that the client can lease the IP address that was previously offered.

### DHCPNACK

If a DHCP server receives a DHCPREQUEST packet requesting an IP address that is not available, then the server will return a DHCPNACK packet, which is the server's way of telling the client that the request was denied.

### Packets Received

This counter will display the total number of inbound DHCP packets each second.

### Active Queue Length

The basic idea is that when requests are received by a Windows based DHCP server, those requests are not immediately process, but are rather placed into a queue for processing. Normally, this queue should contain no more than a couple of items that most. However, if the server is experiencing a heavy workload and is having trouble keeping pace with the demand, then the queue can become backed up. By watching the active queue length, you can gauge just how efficiently your server processes requests.

### Expired Packets

If a packet sits in the active queue for 30 seconds, then the packet is considered to be stale, and is automatically expired. A high number of expired packets usually indicates a serious performance problem with the server.

### Conflict Detection

Because IP address conflicts can cause problems, Windows based DHCP servers have the ability to test for the presence of an IP address prior to issuing it. Basically, this means pinging the address that is about to be assigned to make sure that nobody else is already using the address.

### Declines

If the client detects that another host on the network is already using the address, then it will return a DHCPDECLINE message to the server, indicating that it does not want the address.

Normally, DHCP declines should not happen.

### DHCP Releases

This counter displays the number of times per second that DHCP issued IP addresses are released by a client. Normally, addresses are only released if the client is configured to release leased addresses on shutdown, or if the client manually releases an address by issuing the IPCONFIG /RELEASE command. As such, this probably isn't the best counter to monitor in an effort to gauge your server's performance.

### Duplicates Dropped

The idea is that sometimes duplicate packets are sent to a DHCP server, which in turn drops the duplicates. Duplicate packets can be caused by having multiple DHCP relay agents that forward the same packet to the server. However, dropped duplicates can also indicate that clients are timing out too quickly, or that the DHCP server is not responding quickly enough.

### DHCP Informs

This counter indicates the number of times per second that DHCPINFORM messages are received by the server. These messages occur when the DHCP server queries the Active Directory for the enterprise root or when the server performs dynamic updates on behalf of the clients.

### Milliseconds per Packet

Indicates the number of milliseconds that the DHCP server takes to process each packet that it receives. Unfortunately, I cannot tell you what an acceptable value for this counter is because the value varies widely from server to server depending on the server's hardware and workload. What I can tell you is that it is a good idea to monitor this counter in an effort to determine what is normal for your DHCP server.

## DHCP scope use (%)

* Check how many IPs (in percentage) are used.

:rotating_light: *Triger an alert when use is grather tan 80%*

## How to use this template

You will need:

* __template-DHCP.xml__ template imported on Zabbix
* __dhcp.conf__ file with the required config options for the agent.
* __Gb-CheckDHCP.ps1__ for discover/query.
