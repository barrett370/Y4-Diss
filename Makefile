
.PHONY: logs
logs:
	cp ./research/logs/*.md ./site/content/posts/

.PHONY: site
site:
	cd site && hugo && cd ..
.PHONY: deploy
deploy:
	make site && git add * && ./utils/datecommit.sh && git push
