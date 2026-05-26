#!/usr/bin/python3.6

# -*- coding: utf-8 -*-

from datetime import timedelta 
import datetime
import requests
from xml.etree import ElementTree as ET
import math
from urllib.request import urlopen
import json

# Constant for rh to td conversion.

rvolv = 0.0001846  # rv/lv (461.5/2.5e6)

# Specify begin and end dates.

x = datetime.datetime.now()
enddate = x.strftime("%Y-%m-%d %H:00:00")
begdate = datetime.datetime.strptime(enddate, '%Y-%m-%d %H:%M:%S') - timedelta(days=1)
begdate = "<beginDate>" + str(begdate) + "</beginDate>"
enddate = "<endDate>" + str(enddate) + "</endDate>"

# Read Synoptic data using API.

url = "https://api.synopticdata.com/v2/stations/latest?&token=c259827a38c144a299cf93395539d3cb&stids=046ID,IDP02&vars=air_temp,relative_humidity,dew_point_temperature,wind_speed,wind_direction,wind_gust"

response = urlopen(url) 
  
data_json = json.loads(response.read()) 

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

for key,item in data_json.items():
  print(key,item)

quit()

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
