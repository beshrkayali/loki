.PHONY: format
format:
	nimfmt -i $(shell find . -type f -regex ".*\.nim")

.PHONY: docker-test
docker-test:
	docker-compose \
		-f tests/docker-compose.test.yml \
		-p loki-test \
		up \
		--exit-code-from sut \
		--force-recreate
