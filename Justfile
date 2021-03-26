default:
    @just --list

logs:
	cp ./research/logs/*.md ./site/content/posts/

report:
	cp ./research/report/report.pdf ./site/static/

update-report: 
    just report && just deploy

site:
	cd site && hugo && cd ..

deploy: 
    just site && git add docs && ./utils/datecommit.sh && git push

