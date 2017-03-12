# TODO this is really a dirty fix, but working with sed is pain in the ass
# so I created this file.
# In the Dockerfile I explained in some detail why I have to extract the ip
# from the DB_HOST inside the container

import sys
db_host = sys.argv[1]
ip_chars = set('0123456789.')
f = open('/etc/hosts', 'r')
for line in f:
    if ' ' + db_host in line or '\t' + db_host in line:
        # find first charachter that is not a number or a point
        for i, c in enumerate(line):
            if c not in ip_chars:
                print(line[:i])
                f.close()
                sys.exit()

f.close()
sys.exit(1)
