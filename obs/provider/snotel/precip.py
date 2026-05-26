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

# Specify begin and end dates.

#begdate = "2020-01-01 00:00:00"
#enddate = "2020-02-01 00:00:00"
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

# Precip Accumulation.

body = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:q0="http://www.wcc.nrcs.usda.gov/ns/awdbWebService" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SOAP-ENV:Body>
    <q0:getHourlyData>""" + triplets + """<elementCd>PREC</elementCd>
      <ordinal>1</ordinal><beginDate>""" + begdate + "</beginDate><endDate>" + enddate + """</endDate>
    </q0:getHourlyData>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""

pcpacxml = requests.post(url,data=body,headers=headers,verify=False)
#print(pcpacxml.content)

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
# Temp.

print("Precip:")
root = ET.fromstring(pcpacxml.content)
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
      check = 0

# Loop through data and construct sql statement.

      pcplast = -1
      sql = "insert into obsHydro (time,staname,pcp1) values "
      for val in data.iter('values'):
        time = val.find('dateTime').text
        dateobj = datetime.datetime.strptime(time, '%Y-%m-%d %H:%M') + timedelta(hours=8)
        snotel_time = dateobj.strftime("%Y-%m-%d %H:%M")
        x = val.find('flag')
        if x==None:
          continue
        flag = val.find('flag').text
        x = val.find('value')
        if x==None:
          continue
        val = float(val.find('value').text)
        if pcplast < 0:
          pcplast = val
          continue
        if flag == "S":
          continue
        pcp = round((val-pcplast) * 100)
        if pcp < 0:
          pcp = 0
        if pcp > 5000:
          continue
        pcplast = val
        sql += "('" + snotel_time + "','" + shefId + "'," + str(pcp) + "),"
        check = 1

      sql = sql[:-1] + " on duplicate key update pcp1=values(pcp1)"
      sqldel = "delete from obsHydro where staname='" + shefId + "' and time>='" + begdate + ' and time<=' + enddate + "'"
#     print(sql)

# Insert data into db.

#     mycursor.execute(sqldel)
      if (check == 1):
        mycursor.execute(sql)
        mydb.commit()
      else:
        print("  All precip data flagged as bad.")
