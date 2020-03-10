## -*- mode: Makefile -*-
## 
## = Itk's Oacis Utility
## Author:: Itsuki Noda
## Version:: 0.0 2020/03/10 I.Noda
##
## === History
## * [2020/03/10]: Create This File.


RDOC_FILES = docItkOacis.rb \
		Conductor.rb HostStub.rb SimulatorStub.rb \
		ParamSetStub.rb \
		ParamSetFactory.rb ParamSetFactoryRandom.rb

top : rdoc

rdoc :
	rdoc --main docItkOacis.rb --markup rdoc --hyperlink-all --force-update --line-numbers $(RDOC_FILES) 
#	rdoc --force-update --one-file --line-numbers --diagram $(RDOC_FILES)
