# net-tools vs. iproute2

> net-tools will be deprecated in favor of iproute2
Ref.: https://www.debian.org/releases/stable/amd64/release-notes/ch-information.en.html#iproute2

```
legacy      | iproute2
net-tools   | replacement
commands    | commands
----------------------------------------------------
arp         | ip n (ip neighbor)
ifconfig    | ip a (ip addr), 
            | ip link, 
            | ip -s (ip -stats)
iptunnel    | ip tunnel
nameif      | ip link
netstat     | ss, 
            | ip route (for netstat -r),
            | ip -s link (for netstat -i),
            | ip maddr (for netstat -g)
route       | ip r (ip route)
```
