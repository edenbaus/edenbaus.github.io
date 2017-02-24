import requests
import pandas as pd
from lxml import etree
from sys import version_info
import os

# READ IN AND PARSE WEB DATA

py3 = version_info[0] > 2 #creates boolean value for test that Python major version > 2

if py3:
  ticker = input("Please enter ticker: ")
else:
  ticker = raw_input("Please enter ticker: ")

url = "https://finance.yahoo.com/q/hp?s="+ticker+"+Historical+Prices"
rq = requests.get(url)
htmlpage = etree.HTML(rq.content)

# INITIALIZE LISTS
dates = []
openstock = []
highstock = []
lowstock = []
closestock = []
volume = []
adjclose = []

# ITERATE THROUGH SEVEN COLUMNS OF TABLE
for i in range(1,8):
    htmltable = htmlpage.xpath("//tr[td/@class='yfnc_tabledata1']/td[{}]".format(i))

    # APPEND COLUMN DATA TO CORRESPONDING LIST
    for row in htmltable:
        if i == 1: dates.append(row.text)
        if i == 2: openstock.append(row.text)
        if i == 3: highstock.append(row.text)
        if i == 4: lowstock.append(row.text)
        if i == 5: closestock.append(row.text)
        if i == 6: volume.append(row.text)
        if i == 7: adjclose.append(row.text)

# CLEAN UP COLSPAN VALUE (AT FEB. 4)
dates = [d for d in dates if len(d.strip()) > 3]
#del dates[7]
#del openstock[7]

# MIGRATE LISTS TO DATA FRAME
df = pd.DataFrame({'Dates':dates,
                   'Open':openstock,
                   'High':highstock,
                   'Low':lowstock,
                   'Close':closestock,
                   'Volume':volume,
                   'AdjClose':adjclose})

df.to_csv(ticker+".csv")
