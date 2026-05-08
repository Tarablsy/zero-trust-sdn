#!/usr/bin/env python3
"""
Zero Trust SDN — Four-zone Mininet topology.

Connects to the ONOS controller running in the Docker container
on host port 6653.

Zones:
  - DMZ        (10.0.1.0/24): web, mail, dns
  - Internal   (10.0.2.0/24): app1, app2, db
  - Restricted (10.0.3.0/24): finance, hr
  - IoT        (10.0.4.0/24): sensor1, sensor2, camera
"""

from mininet.net import Mininet
from mininet.node import RemoteController, OVSKernelSwitch
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.link import TCLink


def create_topology():
    net = Mininet(controller=RemoteController,
                  switch=OVSKernelSwitch,
                  link=TCLink,
                  autoSetMacs=True)

    info('*** Adding ONOS Controller (Docker container)\n')
    # 'localhost' works because the ONOS container maps port 6653 to the host
    c1 = net.addController('c1', controller=RemoteController,
                           ip='127.0.0.1', port=6653)

    info('*** Creating Switches\n')
    s_core     = net.addSwitch('s100', protocols='OpenFlow13')
    s_dmz      = net.addSwitch('s1',   protocols='OpenFlow13')
    s_internal = net.addSwitch('s2',   protocols='OpenFlow13')
    s_restrict = net.addSwitch('s3',   protocols='OpenFlow13')
    s_iot      = net.addSwitch('s4',   protocols='OpenFlow13')

    info('*** Creating Hosts\n')
    # DMZ Zone (10.0.1.0/24)
    web  = net.addHost('web',  ip='10.0.1.10/24')
    mail = net.addHost('mail', ip='10.0.1.20/24')
    dns  = net.addHost('dns',  ip='10.0.1.30/24')

    # Internal Zone (10.0.2.0/24)
    app1 = net.addHost('app1', ip='10.0.2.10/24')
    app2 = net.addHost('app2', ip='10.0.2.20/24')
    db   = net.addHost('db',   ip='10.0.2.30/24')

    # Restricted Zone (10.0.3.0/24)
    fin = net.addHost('finance', ip='10.0.3.10/24')
    hr  = net.addHost('hr',      ip='10.0.3.20/24')

    # IoT Zone (10.0.4.0/24)
    s1h = net.addHost('sensor1', ip='10.0.4.10/24')
    s2h = net.addHost('sensor2', ip='10.0.4.20/24')
    cam = net.addHost('camera',  ip='10.0.4.30/24')

    info('*** Creating Links\n')
    # Core <-> zone switches at 1 Gbps
    for s in [s_dmz, s_internal, s_restrict, s_iot]:
        net.addLink(s_core, s, bw=1000)

    # Hosts <-> zone switches
    net.addLink(web,  s_dmz)
    net.addLink(mail, s_dmz)
    net.addLink(dns,  s_dmz)
    net.addLink(app1, s_internal)
    net.addLink(app2, s_internal)
    net.addLink(db,   s_internal)
    net.addLink(fin,  s_restrict)
    net.addLink(hr,   s_restrict)
    net.addLink(s1h,  s_iot)
    net.addLink(s2h,  s_iot)
    net.addLink(cam,  s_iot)

    info('*** Starting Network\n')
    net.build()
    c1.start()
    for s in [s_core, s_dmz, s_internal, s_restrict, s_iot]:
        s.start([c1])

    info('*** Zero Trust Topology Ready\n')
    info('*** 4 Zones: DMZ(s1), Internal(s2), Restricted(s3), IoT(s4)\n')
    CLI(net)
    net.stop()


if __name__ == '__main__':
    setLogLevel('info')
    create_topology()
