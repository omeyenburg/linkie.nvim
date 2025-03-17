.PHONY: test

test:
	nvim --headless -u test/init.lua -c "PlenaryBustedDirectory test"
