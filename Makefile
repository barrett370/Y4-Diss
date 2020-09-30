
.PHONY site:
site:
	cd site && hugo
.PHONY deploy:
deploy:
	make site && git add * && ./utils/datecommit.sh && git push
