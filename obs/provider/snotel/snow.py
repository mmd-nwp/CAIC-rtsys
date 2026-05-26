#!/usr/bin/python3.6

# xml parsing section derived from Ron script.
# -*- coding: utf-8 -*-
"""
Created on Tue Sep  1 20:10:14 2020

@author: Ron Simenhois
"""

from datetime import timedelta 
import datetime
import requests
from xml.etree import ElementTree as ET
from time import sleep

# Specify begin and end dates.

#begdate = "2019-10-01 00:00:00"
#enddate = "2019-10-31 23:00:00"
x = datetime.datetime.now()
enddate = str(x.strftime("%Y-%m-%d %H:00:00"))
begdate = str(datetime.datetime.strptime(enddate, '%Y-%m-%d %H:%M:%S') - timedelta(days=1))

# Read station list.

sids = []
shefs = []
triplets = ""

# Colorado.

root = ET.parse('/home/caic/caic/rtsys/obs/provider/snotel/stnlist/stnlist-co.xml').getroot()
for data in root.iter():
    if data.tag=='return':
      snotelId = data.find('stationTriplet').text
      shefId = data.find('shefId').text
      sids.append(snotelId)
      shefs.append(shefId)
      triplets += "<stationTriplets>" + snotelId + "</stationTriplets>"

# Montana.

root = ET.parse('/home/caic/caic/rtsys/obs/provider/snotel/stnlist/stnlist-mt.xml').getroot()
for data in root.iter():
    if data.tag=='return':
      snotelId = data.find('stationTriplet').text
      shefId = data.find('shefId').text
      sids.append(snotelId)
      shefs.append(shefId)
      triplets += "<stationTriplets>" + snotelId + "</stationTriplets>"

# California.

root = ET.parse('/home/caic/caic/rtsys/obs/provider/snotel/stnlist/stnlist-ca.xml').getroot()
for data in root.iter():
    if data.tag=='return':
      snotelId = data.find('stationTriplet').text
      shefId = data.find('shefId').text
      sids.append(snotelId)
      shefs.append(shefId)
      triplets += "<stationTriplets>" + snotelId + "</stationTriplets>"

# Wyoming.

root = ET.parse('/home/caic/caic/rtsys/obs/provider/snotel/stnlist/stnlist-wy.xml').getroot()
for data in root.iter():
    if data.tag=='return':
      snotelId = data.find('stationTriplet').text
      shefId = data.find('shefId').text
      sids.append(snotelId)
      shefs.append(shefId)
      triplets += "<stationTriplets>" + snotelId + "</stationTriplets>"

# Idaho.

root = ET.parse('/home/caic/caic/rtsys/obs/provider/snotel/stnlist/stnlist-id.xml').getroot()
for data in root.iter():
    if data.tag=='return':
      snotelId = data.find('stationTriplet').text
      shefId = data.find('shefId').text
      sids.append(snotelId)
      shefs.append(shefId)
      triplets += "<stationTriplets>" + snotelId + "</stationTriplets>"

# Read Snotel data using SOAP API.

url="https://wcc.sc.egov.usda.gov/awdbWebService/services?wsdl"
headers = {'content-type': 'application/soap+xml'}
#headers = {'content-type': 'text/xml'}

# Snow depth.

body = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:q0="http://www.wcc.nrcs.usda.gov/ns/awdbWebService" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SOAP-ENV:Body>
    <q0:getHourlyData>""" + triplets + """<elementCd>SNWD</elementCd>
      <ordinal>1</ordinal><beginDate>""" + begdate + "</beginDate><endDate>" + enddate + """</endDate>
    </q0:getHourlyData>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""

hsxml = requests.post(url,data=body,headers=headers,verify=False)
#print(hsxml.content)

# Connect to db.

import mysql.connector

mydb = mysql.connector.connect(
  host="127.0.0.1",
  user="caic",
  password="steepndeep",
  database="weather"
)

mycursor = mydb.cursor()

# Parse data from xml strings and insert into db.
# Snow depth.

print("Snow Depth:")
root = ET.fromstring(hsxml.content)
for data in root.iter():
    if data.tag=='return':
      x = data.find('beginDate')
      if x==None:
        continue
      beginDate = data.find('beginDate').text
      endDate   = data.find('endDate').text
      stationId = data.find('stationTriplet').text
      x = sids.index(stationId)
      shefId = str(shefs[x])
      if shefId=="None":
        continue
      print("  "+shefId)

# Loop through data and construct sql statement.

      sql = "insert into obsSnow (time,staname,depth) values "
      check = 0
      for val in data.iter('values'):
        time = val.find('dateTime').text
        dateobj = datetime.datetime.strptime(time, '%Y-%m-%d %H:%M') + timedelta(hours=8)
        snotel_time = dateobj.strftime("%Y-%m-%d %H:%M")
        x = val.find('value')
        if x==None:
          continue
        val = val.find('value').text
        val = round(float(val) * 10)
        if val < 0:
          continue
        sql += "('" + snotel_time + "','" + shefId + "'," + str(val) + "),"
        check = 1

# Insert data into db.

      if (check > 0):
        sql = sql[:-1] + " on duplicate key update depth=values(depth)"
#       print(sql)
        mycursor.execute(sql)
        mydb.commit()
