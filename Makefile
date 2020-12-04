
.PHONY: logs
logs:
	cp ./research/logs/*.md ./site/content/posts/

.PHONY: report
report:
	cp ./research/report/report.pdf ./site/static/

.PHONY: site
site:
	cd site && hugo && cd ..
.PHONY: deploy
deploy:
	make site && git add docs && ./utils/datecommit.sh && git push
.PHONY: update-report
update-report:
	make report && make deploy	
