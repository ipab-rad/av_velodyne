#!/usr/bin/env python3
"""Script to automatically spin up and down all configured lidar sensors."""

import atexit  # For sending curl to stop velodynes at exit
import json
import subprocess  # For executing ping shell command
import time
import urllib.request
from io import BytesIO
from urllib.parse import urlencode

from multiprocessing.dummy import Pool as ThreadPool

import pycurl

lidar_ips = ['172.31.2.2', '172.31.2.3']
RPM_on = '600'
RPM_off = '0'
debug = True


def ping(host):
    """Return True if host (str) responds to a ping request."""
    # '-c 1' ping stops after one successful ping
    # Timeout is about 3 seconds, left as default
    # Building the command. Ex: "ping -c 1 192.168.0.1"
    command = ['ping', '-c', '1', host]
    return subprocess.call(command, stdout=subprocess.DEVNULL) == 0


def ip_URL(ip):
    """Return string http:// + ip + /cgi/ ."""
    return 'http://' + ip + '/cgi/'


def sensor_do(s, url, pf, buf):
    """Send command to sensor given ip url."""
    s.setopt(s.URL, url)
    s.setopt(s.POSTFIELDS, pf)
    s.setopt(s.WRITEDATA, buf)
    s.perform()
    rcode = s.getinfo(s.RESPONSE_CODE)
    success = rcode in range(200, 207)
    print('%s %s: %d (%s)' % (url, pf, rcode, 'OK' if success else 'ERROR'))
    return success


def set_lidar_RPM(ips, RPM):
    """Send target Revolutions Per Minute to a list of sensor ips."""
    for ip in ips:
        sensor = pycurl.Curl()
        buffer = BytesIO()
        sensor_do(
            sensor, ip_URL(ip) + 'setting', urlencode({'rpm': RPM}), buffer
        )
        sensor.close()

def set_laser_off(ip):
    sensor = pycurl.Curl()
    buffer = BytesIO()
    sensor_do(
        sensor, ip_URL(ip) + 'setting', urlencode({'laser':'off'}), buffer
    )
    sensor.close()

def set_laser_on(ip):
    sensor = pycurl.Curl()
    buffer = BytesIO()
    sensor_do(
        sensor, ip_URL(ip) + 'setting', urlencode({'laser':'on'}), buffer
    )
    sensor.close()

def set_lidar_on(ip):
    sensor = pycurl.Curl()
    buffer = BytesIO()
    sensor_do(
        sensor, ip_URL(ip) + 'setting', urlencode({'rpm': RPM_on}), buffer
    )
    sensor.close()


def check_lidar_RPM(ips):
    """Check and print the current RPM of a list of sensor ips."""
    for ip in ips:
        sensor = pycurl.Curl()
        response = urllib.request.urlopen(ip_URL(ip) + 'status.json')
        if response:
            status = json.loads(response.read())
            print(
                'Sensor laser at %s is %s, motor rpm is %s'
                % (ip, status['laser']['state'], status['motor']['rpm'])
            )
        sensor.close()


# Check if velodynes are powered on and reachable
for ip in lidar_ips:
    if not ping(ip):
        raise ConnectionError('Velodyne lidars are not online')
        exit()


@atexit.register
def on_close():
    """Spin down all sensors after script is closed e.g. Ctrl+C."""
    print('Spinning down Velodynes')
    set_lidar_RPM(lidar_ips, RPM_off)


# Set both velodynes to spin up, when at speed laser turns on
#set_lidar_RPM(lidar_ips, RPM_on)

# Hack-fix to get velodynes semi-synchronised
pool = ThreadPool(2)
results = pool.map(set_lidar_on, lidar_ips)

set_laser_off('172.31.2.2')
time.sleep(0.073)
set_laser_on('172.31.2.2')

# Optional: Print velodyne status
if debug:
    print("Checking Velodynes' status")
    time.sleep(6)
    check_lidar_RPM(lidar_ips)

while True:
    time.sleep(1)
