#!/usr/bin/env python3

import signal
import time
import sys
import threading
import netifaces
import psutil
import re
import subprocess
import requests
import json
import board
import RPi.GPIO as GPIO
import adafruit_ssd1306
from PIL import Image, ImageDraw, ImageFont

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

WIDTH = 128
HEIGHT = 64
BORDER = 5
DELAY = 5
MARGIN = 2
AVAIL_WIDTH = 114
AVAIL_HIGH = 40
MAX_BUCKET_COUNT = 28
START_WIDTH = 5

# -----------------------------------------------------------------------------
# Pages
# -----------------------------------------------------------------------------


def intro(draw):
    # Draw a white background
    draw.rectangle((0, 0, oled.width - 1, oled.height - 1), outline=255, fill=255)

    # Draw a smaller inner rectangle
    draw.rectangle(
        (BORDER, BORDER, oled.width - BORDER - 1, oled.height - BORDER - 1),
        outline=0,
        fill=0,
    )

    # Write title
    text = "RAKPiOS"
    font = ImageFont.truetype("DejaVuSans-Bold", 20)
    (font_width, font_height) = font.getsize(text)
    draw.text((oled.width // 2 - font_width // 2, oled.height // 2 - 20), text, font=font, fill=255)

    # Version
    p = subprocess.run('cat /etc/os-release | grep VERSION_ID | sed \'s/.*"rakpios-\(.*\)"/\\1/\'', shell=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    text = p.stdout.decode()
    font = ImageFont.truetype("DejaVuSans-Bold", 10)
    (font_width, font_height) = font.getsize(text)
    draw.text((oled.width // 2 - font_width // 2, oled.height // 2 + 5), text, font=font, fill=255)

    return True


def network(draw):
    # Create blank image for drawing
    font = ImageFont.load_default()
    (font_width, font_height) = font.getsize("H")
    y = 0

    draw.rectangle((0, 0, oled.width - 1, font_height - 1), outline=255, fill=255)
    draw.text((0, y), "NETWORK", font=font, fill=0)
    y += font_height

    # Get IP
    ifaces = netifaces.interfaces()
    pattern = "^bond.*|^[ewr].*|^br.*|^lt.*|^umts.*|^lan.*"

    # Get bridge interfaces created by docker
    p = subprocess.run('docker network ls -f driver=bridge --format "br-{{.ID}}"', shell=True, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    br_docker_ifaces = p.stdout.decode()

    for iface in ifaces:
        # Match only interface names starting with e (Ethernet), br (bridge), w (wireless), r (some Ralink drivers use>
        # Get rid off of the br interface created by docker
        if re.match(pattern, iface) and iface not in br_docker_ifaces:
            ifaddresses = netifaces.ifaddresses(iface)
            ipv4_addresses = ifaddresses.get(netifaces.AF_INET)
            if ipv4_addresses:
                for address in ipv4_addresses:
                    addr = address['addr']
                    draw.text((0, y), ("%s: %s" % (iface[:6], addr)), font=font, fill=255)
                    y += font_height

    return True


def stats(draw):
    # Create blank image for drawing
    font = ImageFont.load_default()
    (font_width, font_height) = font.getsize("H")
    y = 0

    draw.rectangle((0, 0, oled.width - 1, font_height - 1), outline=255, fill=255)
    draw.text((0, y), "STATS", font=font, fill=0)
    y += font_height

    # Get cpu percent
    cpu = psutil.cpu_percent(None)
    draw.text((0, y), ("CPU: %.1f%%" % cpu), font=font, fill=255)
    y += font_height

    # Get free memory percent
    memory = 100 - psutil.virtual_memory().percent
    draw.text((0, y), ("Free memory: %.1f%%" % memory), font=font, fill=255)
    y += font_height

    # Get temperature
    p = subprocess.run('vcgencmd measure_temp 2> /dev/null | sed \'s/temp=//\'', shell=True, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    draw.text((0, y), ("Temperature: %s" % p.stdout.decode()), font=font, fill=255)
    y += font_height

    # Get uptime
    p = subprocess.run('uptime -p | sed \'s/up //\' | sed \'s/ hours*/h/\' | sed \'s/ minutes*/m/\' | sed \'s/,//\'',
                       shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    draw.text((0, y), ("Uptime: %s" % p.stdout.decode()), font=font, fill=255)
    y += font_height

    return True


def docker(draw):
    # Get the list of docker services
    p = subprocess.run(
        'docker ps -a --format \'{{.Names}}\t{{.Status}}\' | sort -r -k2 -k1 | awk \'{ print $1, $2 }\' | sed \'s/Exited/Down/\'',
        shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    services = p.stdout.decode().split('\n')[:-1]
    limit = len(services)
    if limit > 5:
        limit = 4

    # If no docker services do not display this page
    if limit == 0:
        return False

    # Create blank image for drawing
    font = ImageFont.load_default()
    (font_width, font_height) = font.getsize("H")
    y = 0

    # Title
    draw.rectangle((0, 0, oled.width - 1, font_height - 1), outline=255, fill=255)
    draw.text((0, y), "DOCKER", font=font, fill=0)
    y += font_height

    # Show services and status
    for service in services[:limit]:
        (name, status) = service.split(' ')
        draw.text((0, y), name.lower().ljust(17)[:17] + status.upper().rjust(4), font=font, fill=255)
        y += font_height
    if len(services) > limit:
        draw.text((0, y), "... and %d more" % (len(services) - limit), font=font, fill=255)
        y += font_height

    return True

def lorawan(draw):

    font = ImageFont.load_default()
    (font_width, font_height) = font.getsize("H")

    # require bucket data from log2api
    url = "http://127.0.0.1:8888/api/metrics"
    try:
        res = requests.get(url)
    except:
        return False
    
    bucket_data = json.loads(res.text)
    bucket_count = min(bucket_data.get('bucket_count'), MAX_BUCKET_COUNT)
    bucket_size = bucket_data.get('bucket_size')
    buckets = bucket_data['buckets']
    totals = bucket_data['totals']
    rx_max = int(totals['rx_max'])
    if rx_max == 0:
        return False

    # calculate the width of each bucket and real bucket count displayed.
    bucket_width = int(AVAIL_WIDTH / bucket_count)

    # calculate the pixel of every packet
    unit = float(AVAIL_HIGH / rx_max)

    # draw y-axis, the packet count of each bucket.
    draw.line((3, 0, 3, 60), width=1, fill=128)
    draw.line((3, 0, 0, 3), width=1, fill=128)
    draw.line((3, 0, 6, 3), width=1, fill=128)

    # draw x-axis, the time.
    draw.line((3, 60, 127, 60), width=1, fill=128)
    draw.line((124, 63, 127, 60), width=1, fill=128)
    draw.line((124, 57, 127, 60), width=1, fill=128)
    draw.text((121, 45), "t", font=font, fill=255)

    # draw every bucket 
    for i in range(bucket_count):
        tmp = buckets.get(str(i), {'rx': 0, 'tx': 0})
        rx = tmp['rx']
        draw.rectangle(
            (START_WIDTH + i * bucket_width, 60, START_WIDTH + (i + 1) * bucket_width - 1, 60 - int(rx * unit) - 1), 
            outline=1, 
            fill=1
        )
    
    # draw top line
    top = "LAST %dm, MAX:%d"%(bucket_count * bucket_size / 60, rx_max)
    draw.text((10, 0), top, font=font, fill=255)
    
    return True

def power_message(text1, text2):
    # Clear display.
    oled.fill(0)
    oled.show()
    # Create blank image for drawing.
    # Make sure to create image with mode '1' for 1-bit color.
    image = Image.new("1", (oled.width, oled.height))
    # Get drawing object to draw on image.
    draw = ImageDraw.Draw(image)
    # Draw a white background
    draw.rectangle((0, 0, oled.width, oled.height), outline=255, fill=255)
    # Draw a smaller inner rectangle
    draw.rectangle(
        (MARGIN, MARGIN, oled.width - MARGIN - 1, oled.height - MARGIN - 1),
        outline=0,
        fill=0, )
    # Load font.
    font = ImageFont.truetype("DejaVuSans-Bold", 12)
    # Draw Some Text
    draw.text(
        (10, 15),
        text1,
        font=font,
        fill=255,
    )
    draw.text(
        (10, 15 + oled.height // 4),
        text2,
        font=font,
        fill=255,
    )

    # Display image
    oled.image(image)
    oled.show()
    return True


class Graceful_shutdown:
    """Catch signals to allow graceful shutdown."""

    def __init__(self):
        self.receivedSignal = self.receivedTermSignal = False
        # 1 : SIGHUP 2: SIGINT 3: SIGQUIT 10: SIGUSR1 12:SIGUSR2 15: SIGTERM
        catchSignals = [
            1,
            2,
            3,
            10,
            12,
            15,
        ]
        for signum in catchSignals:
            signal.signal(signum, self.handler)
        signal.pause()

    def handler(self, signum, frame):
        self.lastSignal = signum
        self.receivedSignal = True
        if signum in [2, 3, 15]:
            self.receivedTermSignal = True
            system_shutdown()
            sys.exit()

def system_shutdown():
    timer.cancel()
    power_message("SYSTEM", "SHUTDOWN")
    time.sleep(5)
    # power off the OLED before the system shuts down
    oled.poweroff()


def power_supply_issues(channel):
    global timer
    timer.cancel()
    power_message("POWER SUPPLY", "ISSUES !")
    time.sleep(60)
    timer = RepeatTimer(DELAY, show_page)
    timer.start()


# -----------------------------------------------------------------------------
# State machine
# -----------------------------------------------------------------------------

def show_page(page):
    # Prepare canvas
    image = Image.new("1", (oled.width, oled.height))
    draw = ImageDraw.Draw(image)

    response = False
    while not response:

        # Show page (returns false if the page should not be displayed)
        response = pages[page](draw)

        # Update next page
        # We are not showing page 0 (intro) again
        page = page + 1
        if page >= len(pages):
            page = 1

    # Update screen
    oled.fill(0)
    oled.image(image)
    oled.show()

    # Return pointer to next page
    return page


# -----------------------------------------------------------------------------
# Main loop
# -----------------------------------------------------------------------------

class RepeatTimer(threading.Timer):
    page = 1

    def run(self):
        while not self.finished.wait(self.interval):
            self.page = self.function(self.page, *self.args, **self.kwargs)


try:
    i2c = board.I2C()
    oled = adafruit_ssd1306.SSD1306_I2C(WIDTH, HEIGHT, i2c)
except Exception:
    print("OLED screen not found")
    sys.exit()

pages = [intro, network, docker, stats, lorawan]
show_page(0)
timer = RepeatTimer(DELAY, show_page)
timer.start()


# Once detect GPIO 16 is falling, trigger the callback function
GPIO.setmode(GPIO.BCM)
GPIO.setup(16, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.add_event_detect(16, GPIO.FALLING, callback=power_supply_issues)
# signal handler for graceful shutdown
signal_handler = Graceful_shutdown()
