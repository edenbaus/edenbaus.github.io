from bs4 import BeautifulSoup
import urllib,re, csv
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
import time
import lxml
import os

try:
    start_time = time.time()


    def count_lines(filename):
        len = 0
        with open(filename) as f:
            for i, l in enumerate(f):
                len = i
                pass
            return len + 1

    zip=raw_input('Please Enter a Zip Code: ')
    print 'Starting Scraper'
    base='https://www.zocdoc.com/search/?dr_specialty=&address='+zip+'&insurance_carrier=-1'
    r = urllib.urlopen(base).read()
    soup = BeautifulSoup(r,"lxml")
    pages=soup.find_all(href=re.compile("offset"))
    for e in pages:
        x=e.get_text()
        if not x.isspace():
            y=int(x)
    print 'Scraping ', y, 'pages of doctors in', zip
    for x in range(0,y):
        print 'Page ', x+1
        p=str(x*10)
        url= base+"&offset="+p
        r = urllib.urlopen(url).read()
        soup = BeautifulSoup(r,"lxml")
        names = soup.find_all("div", class_="sg-header7 js-doc-name")
        f=open("doctor_links.txt","a")

        for element in names:
            p=element.a.get_text()
            f.write('http://zocdoc.com'+element.a['href']+'\n')
            #print p

    f.close()
    len2 = count_lines("doctor_links.txt")
    print 'Found', len2, 'doctors'
    print "Scraping Doctor Details"
    dname = []
    dadd = []
    dspec = []
    dcap = dict()
    dcap["phantomjs.page.settings.userAgent"] = (
         "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/53 "
         "(KHTML, like Gecko) Chrome/15.0.87")
    regex = re.compile(r'[\n\r\t]')


    with open('doctor_links.txt') as fp:
        for i,line in enumerate(fp):
            print 'Doctor #', i+1
            url=line
            r = urllib.urlopen(url).read()
            soup = BeautifulSoup(r,"lxml")
            Doctor_name = soup.find_all("span",itemprop="name")
            adress = soup.find_all("div",itemprop="address")
            specialty= soup.find_all("li",class_="specialty")
            try:
                rating = soup.find('meta',itemprop="ratingValue")['content']
            except Exception as e:
                rating = 'No rating found'

            try:
                mydriver = webdriver.PhantomJS(desired_capabilities = dcap)
                mydriver.get(url)
                src = mydriver.page_source
                text_found = re.search(r'Next availability', src)
                if text_found:
                    try:
                        mydriver.execute_script("document.getElementsByClassName('tg-next-avail-btn DesktopTimesGridContent__tg-next-avail-btn___3CLNB TimesGridShared__tg-next-avail-btn___2DLqN')[0].click()")
                        Time = mydriver.find_element_by_xpath('//div[@class="DesktopTimesGridContent__tg-slot-wrapper___22KU1"]/a').text
                        links = mydriver.find_elements_by_partial_link_text(Time)
                        apt_link = links[0].get_attribute("href")
                        mydriver.get(apt_link)
                        apt_time = mydriver.find_elements_by_xpath('//div[@class="sg-h3 js-time"]')[0].text
                    except Exception as e:
                        do = 0
                else:
                    Time = mydriver.find_element_by_xpath('//div[@class="DesktopTimesGridContent__tg-slot-wrapper___22KU1"]/a').text
                    links = mydriver.find_elements_by_partial_link_text(Time)
                    apt_link = links[0].get_attribute("href")
                    mydriver.get(apt_link)
                    apt_time = mydriver.find_elements_by_xpath('//div[@class="sg-h3 js-time"]')[0].text
            except Exception as e:
                apt_time = 'Not found'


            for name in Doctor_name:
                dname= name.get_text().strip()
                print 'Doctor Name', dname

            for add in adress:
                dadd = add.get_text().strip()
                t = regex.sub("", dadd)
            for spec in specialty:
                dspec += [spec.get_text().strip()]
            with open(zip+'.csv','a') as f:
                write=csv.writer(f)
                write.writerow([dname,t,dspec,rating,apt_time])

    os.remove('doctor_links.txt')

    print("Scraping Completed. Total Time taken: %s seconds ---" % (time.time() - start_time))

    """for index, (v1,v2) in enumerate(zip(dname,dadd)):
        print "Name: "+v1+"\n"+"Address: "+v2"""
except Exception as e:
    print e
    raw_input()
