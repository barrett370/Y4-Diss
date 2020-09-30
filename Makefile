
.PHONY site:
site:
	cd site && hugo && cd ..
.PHONY deploy:
deploy:
	make site && git add * && ./utils/datecommit.sh && git push
