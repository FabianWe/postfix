# TODO this is really a dirty fix, but working with sed is pain in the ass
# so I created this file.
# In the Dockerfile I explained in some detail why I have to extract the ip
# from the DB_HOST inside the container

import sys
import socket

db_host = sys.argv[1]
ips = socket.gethostbyname_ex(db_host)[2]
if not ips:
    print('No host with name "%s" found, you must specify a database host!' % db_host)
    sys.exit(1)
print(ips[0])
