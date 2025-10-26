# Deltafetch Ruzen42  

all:
	@echo Building...
	@set -e 
	@stack build

clean:
	@echo Cleaning...
	@stack clean

install: all 
	@echo Installing...
	@install -m755 deltafetch /usr/local/bin/deltafetch

install-local: all
	@echo Installing in ~/.local/bin...
	@stack install

uninstall: 
	@echo Uninstalling...
	@rm -rf /usr/local/bin/deltafetch

