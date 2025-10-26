# Deltafetch Ruzen42  

all:
	@echo Building...
	@set -e 
	@stack build

clean:
	@echo Cleaning...
	@stack clean

install: install-local
	@echo Installing...
	@install -m755 ~/local/bin/deltafetch /usr/local/bin/deltafetch
	@rm ~/.local/bin/deltafetch

install-local: all
	@echo Installing in ~/.local/bin...
	@stack install

uninstall: 
	@echo Uninstalling...
	@rm -rf /usr/local/bin/deltafetch

