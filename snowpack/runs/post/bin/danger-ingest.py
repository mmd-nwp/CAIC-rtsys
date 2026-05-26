#!/usr/bin/python3.6

from datetime import timedelta 
from urllib.request import urlopen
import json
import datetime
import requests
import os
from dotenv import load_dotenv

# Define danger ratings and problems.

danger = {
  "low":          1,
  "moderate":     2,
  "considerable": 3,
  "high":         4,
  "extreme":      5
}

avproblems = {
  "dryLoose":           1,
  "wetLoose":           2,
  "stormSlab":          3,
  "windSlab":           4,
  "persistentSlab":     5,
  "deepPersistentSlab": 6,
  "wetSlab":            7,
  "glideSlab":          8,
  "cornice":            9
}

aspects = {
  "n":    1,
  "ne":   2,
  "e":    4,
  "se":   8,
  "s":   16,
  "sw":  32,
  "w":   64,
  "nw": 128,
}

likelihood = {
  "unlikely":           1,
  "possible_unlikely":  2,
  "possible":           3,
  "likely_possible":    4,
  "likely":             5,
  "veryLikely_likely":  6,
  "veryLikely":         7,
  "certain_veryLikely": 8,
  "certain":            9
}

# Load API key.

load_dotenv()
api_key = os.getenv("MY_SECRET_API_KEY")
print(api_key)

# Connect to db.

import mysql.connector

mydb = mysql.connector.connect(
  host="127.0.0.1",
  user="caic",
  password="steepndeep",
  database="snowpack"
)

mycursor = mydb.cursor()

# Specify start and end dates.

endtime = datetime.datetime.now() + timedelta(hours=12)
enddate = endtime.strftime("%Y-%m-%d") 
urldate = enddate
#urldate = "2026-03-01"  
#enddate = "2026-03-04"
#print(urldate,enddate)

while urldate <= enddate:
  print(urldate)

# Read data using API.

  url = "https://avid-api.avalanche.state.co.us/public/en/products/all"
  params = {
    "datetime": urldate + "T12:00:00Z"
  }  

  headers = {
    "x-api-key": api_key,
    "Content-Type": "application/json"
  }

  try:
  # Perform the GET request
    response = requests.get(url, headers=headers, params=params)

  # Raise an error for bad responses (4xx or 5xx)
    response.raise_for_status()
    
  # Parse the JSON data
    data_json = response.json()
    
  except requests.exceptions.RequestException as e:
    print(f"An error occurred: {e}")

  for record in data_json:
    if record["type"] == "avalancheforecast":
      polygons = record["publicName"].split("-")
      ratings = record["dangerRatings"]["days"][0]  # Only current day for now
      date = ratings["date"][:10]

      rating = ratings["alp"]
      atl = 0
      if rating in danger:
        atl = danger[rating]

      rating = ratings["tln"]
      ntl = 0
      if rating in danger:
        ntl = danger[rating]

      rating = ratings["btl"]
      btl = 0
      if rating in danger:
        btl = danger[rating]

      if atl+ntl+btl == 0:
        continue

      for i in range(len(polygons)):

        sql  = "replace into polyDanger (date,polygon,atl,ntl,btl) values "
        sql += "('" + date + "'," + str(polygons[i]) + "," + str(atl) + "," + str(ntl) + "," + str(btl) + ")"
#       print(sql)

# Insert data into db.

        mycursor.execute(sql)
        mydb.commit()

      problems = record["avalancheProblems"]["days"][0]
      n = 1
      for avprob in problems:
        avtype = avprob["type"]
        avcode = 0
        if avtype in avproblems:
          avcode = avproblems[avtype]

        aspectBTL = 0
        aspectNTL = 0
        aspectATL = 0
        if "aspectElevations" in avprob:
          for aspectelev in avprob["aspectElevations"]:
            [aspect,elev] = aspectelev.split("_",1)
            code = 0
            if aspect in aspects:
              code = aspects[aspect]
            if   elev == "btl": aspectBTL += code
            elif elev == "tln": aspectNTL += code
            elif elev == "alp": aspectATL += code

        lcode = 0
        if "likelihood" in avprob:
          like = avprob["likelihood"]
          if like in likelihood:
            lcode = likelihood[like]

        minsize = 0
        maxsize = 0
        if "expectedSize" in avprob:
          minsize = int(float(avprob["expectedSize"]["min"]) * 10)
          maxsize = int(float(avprob["expectedSize"]["max"]) * 10)

        for i in range(len(polygons)):

          if n == 1:
            sql  = "replace into polyProblems (date,polygon,prob1,btlAspect1,ntlAspect1,atlAspect1,likelihood1,minSize1,maxSize1) values "
            sql += "('" + date + "'," + str(polygons[i]) 
            sql += "," + str(avcode) 
            sql += "," + str(aspectBTL) 
            sql += "," + str(aspectNTL) 
            sql += "," + str(aspectATL) 
            sql += "," + str(lcode) 
            sql += "," + str(minsize) 
            sql += "," + str(maxsize) 
            sql += ")"
          elif n == 2:
            sql  = "update polyProblems set prob2=" + str(avcode) 
            sql += ", btlAspect2=" + str(aspectBTL) 
            sql += ", ntlAspect2=" + str(aspectNTL) 
            sql += ", atlAspect2=" + str(aspectATL) 
            sql += ", likelihood2=" + str(lcode) 
            sql += ", minSize2=" + str(minsize) 
            sql += ", maxSize2=" + str(maxsize) 
            sql += " where date='" + date + "' and polygon=" + str(polygons[i]);
          elif n == 3:
            sql  = "update polyProblems set prob3=" + str(avcode) 
            sql += ", btlAspect3=" + str(aspectBTL) 
            sql += ", ntlAspect3=" + str(aspectNTL) 
            sql += ", atlAspect3=" + str(aspectATL) 
            sql += ", likelihood3=" + str(lcode) 
            sql += ", minSize3=" + str(minsize) 
            sql += ", maxSize3=" + str(maxsize) 
            sql += " where date='" + date + "' and polygon=" + str(polygons[i]);
#         print(sql)

# Insert data into db.

          mycursor.execute(sql)
          mydb.commit()

        n += 1

  urldate = datetime.datetime.strptime(urldate, '%Y-%m-%d') + timedelta(days=1)
  urldate = str(urldate)[:10]
