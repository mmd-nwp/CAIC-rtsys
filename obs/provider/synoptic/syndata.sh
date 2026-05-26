#!/bin/sh

#curl "https://api.synopticdata.com/v2/stations/latest?&token=c259827a38c144a299cf93395539d3cb&stids=046ID,IDP02&vars=air_temp,relative_humidity,dew_point_temperature,wind_speed,wind_direction,wind_gust"
#curl "https://api.synopticdata.com/v2/stations/latest?&token=7ad554acf5b44371a36f5eb7ee50ae39&stids=046ID,IDP02&vars=air_temp,relative_humidity,dew_point_temperature,wind_speed,wind_direction,wind_gust"


curl "https://api.synopticdata.com/v2/stations/timeseries?&token=c259827a38c144a299cf93395539d3cb&stids=046ID,IDP02&recent=60&vars=air_temp,relative_humidity,dew_point_temperature,wind_speed,wind_direction,wind_gust"
#curl "https://api.synopticdata.com/v2/stations/timeseries?&token=7ad554acf5b44371a36f5eb7ee50ae39&stids=046ID,IDP02&recent=60&vars=air_temp,relative_humidity,dew_point_temperature,wind_speed,wind_direction,wind_gust"
