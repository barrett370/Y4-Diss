
.PHONY site:
site:
	cd site && hugo
.PHONY deploy:
deploy:
	make site && git add * && git commit -m "update site at $(date +"%D-%R")" && git push
