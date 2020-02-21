NIM_SRC = $(shell find . -type f -regex ".*\.nim")

.PHONY: format
format:
	for target in $(NIM_SRC); do \
		nimpretty $$target; \
	done

.PHONY: docker-test
docker-test:
	docker-compose \
		-f tests/docker-compose.test.yml \
		-p loki-test \
		up \
		--exit-code-from sut \
		--force-recreate
