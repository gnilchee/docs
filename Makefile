.PHONY: live-docs
live-docs:
	@docker build --pull -t mkdocs-builder Docker/mkdocs
	@docker run --rm -p 8080:8080 -v ${PWD}:/root/working --name mkdocs-builder mkdocs-builder mkdocs serve -a 0.0.0.0:8080

.PHONY: build-docs
build-docs:
	@docker build --pull -t mkdocs-builder Docker/mkdocs
	@docker run --rm -v ${PWD}:/root/working --name mkdocs-builder mkdocs-builder mkdocs build

.PHONY: publish-docs
publish-docs:
	@git clone --branch=gh-pages --depth=1 git@github.com:gnilchee/docs.git gh-pages
	@cd gh-pages && git rm -r .
	@cp -r site/* gh-pages/.
	@cd gh-pages && git add -A
	@cd gh-pages && git commit -m "Publishing changes from Makefile"
	@cd gh-pages && git push origin gh-pages

.PHONY: clean
clean:
	@docker rm -f mkdocs-builder 2>/dev/null || echo "No build containers"
	@docker rmi -f mkdocs-builder 2>/dev/null || echo "No build images present"
	@rm -rf site gh-pages