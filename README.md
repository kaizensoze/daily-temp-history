
The goal of this project is to take a history of daily average temperatures in various cities throughout the world
and make it easily searchable.

Each city is a text file and each line in the text file is of the format:

month | day | year | average daily temp |
------|-----|------|--------------------|
1     | 3   | 1995 | -99                |
8     | 15  | 2000 | 78.8               |

where -99 is a placeholder for missing data

http://academic.udayton.edu/kissock/http/Weather/source.htm

data urls

temp data: http://academic.udayton.edu/kissock/http/Weather/gsod95-current/allsites.zip
data file list: http://academic.udayton.edu/kissock/http/Weather/citywbanwmo.txt
station list: http://www.wunderground.com/about/faq/international_cities.asp, http://weather.rap.ucar.edu/surface/stations.txt

Starting from scratch when downloading the latest temperature data:

remove ISTELAVIV.txt
remove WS_FTP.LOG
replace second JDAMMAN with SYDMSCUS in the cities list