.PHONY: test install

test:
	bats -r test/

install:
	bin/openai-proxy-install $(ARGS)
