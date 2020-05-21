#!/bin/bash

cat /etc/crontab > /home/saouas/new
DIFF=$(diff new tmp)
if [ "$DIFF" != "" ]; then
	sudo sendmail salimaouas@gmail.com < /home/saouas/mail.txt
	rm -rf /home/saouas/tmp
	cp /home/saouas/new /home/saouas/tmp
fi
