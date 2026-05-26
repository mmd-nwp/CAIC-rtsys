#!/usr/bin/python3.6

# xml parsing section derived from Ron script.
# -*- coding: utf-8 -*-
"""
Created on Tue Sep  1 20:10:14 2020

@author: Ron Simenhois
"""

from datetime import timedelta 
from urllib.request import urlopen
import json
import datetime
import requests
from xml.etree import ElementTree as ET
import math

# Constant for rh to td conversion.

rvolv = 0.0001846  # rv/lv (461.5/2.5e6)

# Read data using SOAP API.

#url="https://api.synopticdata.com/v2/stations/latest?bbox=-112.291260,40.544070,-111.593628,40.972640&vars=air_temp&token=c259827a38c144a299cf93395539d3cb"
#url="https://api.synopticdata.com/v2/stations/latest?stids=046ID,IDP02&vars=air_temp&token=c259827a38c144a299cf93395539d3cb"
url = "https://api.synopticdata.com/v2/stations/latest?&token=c259827a38c144a299cf93395539d3cb&stids=046ID,IDP02&vars=air_temp,relative_humidity,dew_point_temperature,wind_speed,wind_direction,wind_gust"

response = urlopen(url) 
  
data_json = json.loads(response.read()) 
  
for key,item in data_json.items():
  print(key)
