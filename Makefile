## -*- mode: Makefile -*-
## 
## = Itk's Oacis Utility
## Author:: Itsuki Noda
## Version:: 0.0 2020/03/10 I.Noda
##
## === History
## * [2020/03/10]: Create This File.


RDOC_FILES = docItkOacis.rb ItkOacis.rb \
		Conductor.rb \
		ConductorRandom.rb ConductorCombine.rb \
		ConductorGaSimple.rb ConductorGaProgressive.rb \
		HostStub.rb SimulatorStub.rb ParamSetStub.rb

top : rdoc

rdoc :
	rdoc --all --main docItkOacis.rb --title ItkOacis --hyperlink-all --force-update --line-numbers $(RDOC_FILES) 
#	rdoc --force-update --one-file --line-numbers --diagram $(RDOC_FILES)
