import exifread

im = "/Users/scottedenbaum/nycdatsci/Python/images_sample/15.jpg"

f = open(im, 'rb')
tags = exifread.process_file(f)
print tags
