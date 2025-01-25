.PHONY: test install

test:
	bats -r test/synthetic

install:
    install.sh
