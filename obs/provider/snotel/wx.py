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
import math

# Constant for rh to td conversion.

rvolv = 0.0001846  # rv/lv (461.5/2.5e6)

# Specify begin and end dates.

x = datetime.datetime.now()
enddate = x.strftime("%Y-%m-%d %H:00:00")
begdate = datetime.datetime.strptime(enddate, '%Y-%m-%d %H:%M:%S') - timedelta(days=1)
begdate = "<beginDate>" + str(begdate) + "</beginDate>"
enddate = "<endDate>" + str(enddate) + "</endDate>"

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

# Temperature.

body = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:q0="http://www.wcc.nrcs.usda.gov/ns/awdbWebService" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SOAP-ENV:Body>
    <q0:getHourlyData>""" + triplets + """<elementCd>TOBS</elementCd>
      <ordinal>1</ordinal>""" + begdate + enddate + """</q0:getHourlyData>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""

print(body)
tempxml = requests.post(url,data=body,headers=headers,verify=False)
print(tempxml.content)

# Wind speed.

body = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:q0="http://www.wcc.nrcs.usda.gov/ns/awdbWebService" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SOAP-ENV:Body>
    <q0:getHourlyData>""" + triplets + """<elementCd>WSPDV</elementCd>
      <ordinal>1</ordinal>""" + begdate + enddate + """</q0:getHourlyData>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""

wspdxml = requests.post(url,data=body,headers=headers,verify=False)
#print(wspdxml.content)

# Wind direction.

body = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:q0="http://www.wcc.nrcs.usda.gov/ns/awdbWebService" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SOAP-ENV:Body>
    <q0:getHourlyData>""" + triplets + """<elementCd>WDIRV</elementCd>
      <ordinal>1</ordinal>""" + begdate + enddate + """</q0:getHourlyData>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""

wdirxml = requests.post(url,data=body,headers=headers,verify=False)
#print(wdirxml.content)

# Wind gust.

body = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:q0="http://www.wcc.nrcs.usda.gov/ns/awdbWebService" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SOAP-ENV:Body>
    <q0:getHourlyData>""" + triplets + """<elementCd>WSPDX</elementCd>
      <ordinal>1</ordinal>""" + begdate + enddate + """</q0:getHourlyData>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""

gustxml = requests.post(url,data=body,headers=headers,verify=False)
#print(gustxml.content)

# Relative humidity.

body = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:q0="http://www.wcc.nrcs.usda.gov/ns/awdbWebService" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SOAP-ENV:Body>
    <q0:getHourlyData>""" + triplets + """<elementCd>RHUMV</elementCd>
      <ordinal>1</ordinal>""" + begdate + enddate + """</q0:getHourlyData>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""

rhumxml = requests.post(url,data=body,headers=headers,verify=False)
#print(rhumxml.content)

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

print("Temperature:")
root = ET.fromstring(tempxml.content)
for data in root.iter():
    if data.tag=='return':
      x = data.find('beginDate')
      if x==None:
        continue
      beginDate = data.find('beginDate').text
      endDate   = data.find('endDate').text
      stationId = data.find('stationTriplet').text
      x = sids.index(stationId)
      shefId = shefs[x]
      if shefId==None:
        continue
      print("  "+shefId)

# Loop through data and construct sql statement.

      sql = "insert into obsWX (time,staname,temp) values "
      for val in data.iter('values'):
        time = val.find('dateTime').text
        dateobj = datetime.datetime.strptime(time, '%Y-%m-%d %H:%M') + timedelta(hours=8)
        snotel_time = dateobj.strftime("%Y-%m-%d %H:%M")
        x = val.find('value')
        if x==None:
          continue
        val = val.find('value').text
        val = round(float(val) * 10)
        sql += "('" + snotel_time + "','" + shefId + "'," + str(val) + "),"

      sql = sql[:-1] + " on duplicate key update temp=values(temp)"
#     print(sql)

# Insert data into db.

      mycursor.execute(sql)
      mydb.commit()

# Wind speed.

print("Wind Speed:")
root = ET.fromstring(wspdxml.content)
for data in root.iter():
    if data.tag=='return':
      x = data.find('beginDate')
      if x==None:
        continue
      beginDate = data.find('beginDate').text
      endDate   = data.find('endDate').text
      stationId = data.find('stationTriplet').text
      x = sids.index(stationId)
      shefId = shefs[x]
      if shefId==None:
        continue
      print("  "+shefId)

# Loop through data and construct sql statement.

      sql = "insert into obsWX (time,staname,wspd) values "
      for val in data.iter('values'):
        time = val.find('dateTime').text
        dateobj = datetime.datetime.strptime(time, '%Y-%m-%d %H:%M') + timedelta(hours=8)
        snotel_time = dateobj.strftime("%Y-%m-%d %H:%M")
        x = val.find('value')
        if x==None:
          continue
        val = val.find('value').text
        val = round(float(val) * 10)
        sql += "('" + snotel_time + "','" + shefId + "'," + str(val) + "),"

      sql = sql[:-1] + " on duplicate key update wspd=values(wspd)"
#     print(sql)

# Insert data into db.

      mycursor.execute(sql)
      mydb.commit()

# Wind dir.

print("Wind Direction:")
root = ET.fromstring(wdirxml.content)
for data in root.iter():
    if data.tag=='return':
      x = data.find('beginDate')
      if x==None:
        continue
      beginDate = data.find('beginDate').text
      endDate   = data.find('endDate').text
      stationId = data.find('stationTriplet').text
      x = sids.index(stationId)
      shefId = shefs[x]
      if shefId==None:
        continue
      print("  "+shefId)

# Loop through data and construct sql statement.

      sql = "insert into obsWX (time,staname,wdir) values "
      for val in data.iter('values'):
        time = val.find('dateTime').text
        dateobj = datetime.datetime.strptime(time, '%Y-%m-%d %H:%M') + timedelta(hours=8)
        snotel_time = dateobj.strftime("%Y-%m-%d %H:%M")
        x = val.find('value')
        if x==None:
          continue
        val = val.find('value').text
        val = round(float(val))
        sql += "('" + snotel_time + "','" + shefId + "'," + str(val) + "),"

      sql = sql[:-1] + " on duplicate key update wdir=values(wdir)"
#     print(sql)

# Insert data into db.

      mycursor.execute(sql)
      mydb.commit()

# Wind gust.

print("Wind Gust:")
root = ET.fromstring(gustxml.content)
for data in root.iter():
    if data.tag=='return':
      x = data.find('beginDate')
      if x==None:
        continue
      beginDate = data.find('beginDate').text
      endDate   = data.find('endDate').text
      stationId = data.find('stationTriplet').text
      x = sids.index(stationId)
      shefId = shefs[x]
      if shefId==None:
        continue
      print("  "+shefId)

# Loop through data and construct sql statement.

      sql = "insert into obsWX (time,staname,gust) values "
      for val in data.iter('values'):
        time = val.find('dateTime').text
        dateobj = datetime.datetime.strptime(time, '%Y-%m-%d %H:%M') + timedelta(hours=8)
        snotel_time = dateobj.strftime("%Y-%m-%d %H:%M")
        x = val.find('value')
        if x==None:
          continue
        val = val.find('value').text
        val = round(float(val) * 10)
        sql += "('" + snotel_time + "','" + shefId + "'," + str(val) + "),"

      sql = sql[:-1] + " on duplicate key update gust=values(gust)"
#     print(sql)

# Insert data into db.

      mycursor.execute(sql)
      mydb.commit()

# Relative humidity.

print("RH:")
root = ET.fromstring(rhumxml.content)
for data in root.iter():
    if data.tag=='return':
      x = data.find('beginDate')
      if x==None:
        continue
      beginDate = data.find('beginDate').text
      endDate   = data.find('endDate').text
      stationId = data.find('stationTriplet').text
      x = sids.index(stationId)
      shefId = shefs[x]
      if shefId==None:
        continue
      print("  "+shefId)

# Loop through data and construct sql statement.

      sql = "insert into obsWX (time,staname,rh) values "
      sqltd = "insert into obsWX (time,staname,dewp) values "
      check = 0
      checktd = 0
      for val in data.iter('values'):
        time = val.find('dateTime').text
        dateobj = datetime.datetime.strptime(time, '%Y-%m-%d %H:%M') + timedelta(hours=8)
        snotel_time = dateobj.strftime("%Y-%m-%d %H:%M")
        x = val.find('value')
        if x==None:
          continue
        val = val.find('value').text
        val = round(float(val))
        if val > 101:
          continue
        if val < 2:
          continue
        sql += "('" + snotel_time + "','" + shefId + "'," + str(val) + "),"
        check = 1

# Compute dew point from temp and rh.

        sqltp = "select temp from obsWX where time='" + snotel_time + "' and staname='" + shefId + "'"

        mycursor.execute(sqltp)
        myresult = mycursor.fetchall()

        for x in myresult:
          if x[0]==None:
            continue
          tpk = (x[0] / 10 - 32) / 1.8 + 273.15
          rhp = val / 100;

          if rhp > 1:
            rhp = 1
          td = tpk / ((-rvolv * math.log(rhp) * tpk) + 1)
          if (td > tpk):
            td = tpk 
          td = round(((td - 273.15) * 1.8 + 32) * 10)
          sqltd += "('" + snotel_time + "','" + shefId + "'," + str(td) + "),"
          checktd = 1

      sql = sql[:-1] + " on duplicate key update rh=values(rh)"
      sqltd = sqltd[:-1] + " on duplicate key update dewp=values(dewp)"

# Insert data into db.

      if check > 0:
        mycursor.execute(sql)
        mydb.commit()
      if checktd > 0:
        mycursor.execute(sqltd)
        mydb.commit()
