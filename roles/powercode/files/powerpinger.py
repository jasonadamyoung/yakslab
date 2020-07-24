#!/usr/bin/env python
import pyping
import smtplib
import time
import RPi.GPIO as io
io.setmode(io.BCM)
power_pin = 17

result = pyping.ping('8.8.8.8')
if result.ret_code == 0:
    server = smtplib.SMTP( "localhost")
    msg = "Ping successful!"
    msg['Subject'] = "Ping successful!"
    server.sendmail("powerpi@outfielding.net", "jay@outfielding.net", msg)
    server.quit()
else:
    server = smtplib.SMTP( "localhost")
    msg = "Ping failed!"
    msg['Subject'] = "Ping failed!"
    server.sendmail("powerpi@outfielding.net", "jay@outfielding.net", msg)
    server.quit()
    io.setup(power_pin, io.OUT)
    io.output(power_pin, True)
    time.sleep(5)
    io.output(power_pin, False)
