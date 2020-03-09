#! /usr/bin/env ../../oacis/bin/oacis_ruby
## -*- mode: ruby -*-
## = Itk Oacis ParamSet Factory
## Author:: Itsuki Noda
## Version:: 0.0 2020/03/09 I.Noda
##
## === History
## * [2020/03/09]: Create This File.
## * [YYYY/MM/DD]: add more
## == Usage
## * ...

def $LOAD_PATH.addIfNeed(path)
  self.unshift(path) if(!self.include?(path)) ;
end

$LOAD_PATH.addIfNeed(File.dirname(__FILE__));
$LOAD_PATH.addIfNeed(File.dirname(__FILE__) + "/itkLib");

require 'pp' ;
require 'json' ;

require 'WithConfParam.rb' ;

require 'SimulatorStub.rb' ;
require 'HostStub.rb' ;
require 'ParamSetStub.rb' ;

#--======================================================================
#++
## package module of Interactive Toolkit for Oacis.
module ItkOacis
  #--======================================================================
  #++
  ## to control functionarities of OACIS via Oacis Watcher facility.
  class ParamSetFactory < WithConfParam
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default configulation for initialization.
    DefaultConf = {
      :paramSetClass => ItkOacis::ParamSetStub,
      :nRun => 1,
      :defaultSeed => {},
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## a Conductor.
    attr_reader :conductor ;
    ## ParamSetStub class.
    attr_reader :paramSetClass ;
    ## number of runs
    attr_reader :nRun ;
    ## default seed to create new ParamSet.
    attr_reader :defaultSeed ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## initialize an instance.
    ## _conf_:: configulation for the initialization.
    def initialize(_conductor, _conf = {})
      super(_conf) ;

      @conductor = _conductor ;
      @paramSetClass = getConf(:paramSetClass) ;
      @nRun = getConf(:nRun) ;
      @defaultSeed = getConf(:defaultSeed) ;
      
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## set SimulatorStub by name.
    ## _simName_:: the name of simulator.
    ## *return*:: the SimulatorStub.
    def getSimulator()
      return @conductor.simulator ;
    end

    #--------------------------------------------------------------
    #++
    ## set SimulatorStub by name.
    ## _simName_:: the name of simulator.
    ## *return*:: the SimulatorStub.
    def getHost()
      return @conductor.host ;
    end
    
    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to create ParamSetStub.
    ## Can be override.
    ## _seed_:: an seed data to create new ParamSet.
    ## _nRun_:: number of runs.
    ## *return*:: a ParamSetStub.
    def newParamSet(_seed = @defaultSeed, _nRun = @nRun)
      _param = setupNewParam(_seed) ;
      _psStub = @paramSetClass.new(_param, self, _nRun) ;
      return _psStub ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to setup ParamSet setting for new one.
    ## As a default, just return _seed.
    ## Can be override.
    ## _seed_:: an seed data to create new ParamSet.
    ## *return*:: a Hash of ParamSet setting.
    def setupNewParam(_seed)
      return _seed ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to create PS.
    ## _param_:: a Hash of a parameter set. Can be partial.
    ## *return*:: a Ps.
    def createPs(_param)
      return getSimulator().createPs(_param) ;
    end

    #--------------------------------------------------------------
    #++
    ## to run ParamSetStub on Host.
    ## _psStub_:: a ParamSetStub.
    ## _nRun_:: number of runs.
    def runParamSet(_psStub, _nRun)
      getHost().createRuns(_psStub, _nRun) ;
    end
    
    #--////////////////////////////////////////////////////////////
    #--============================================================
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #--------------------------------------------------------------
  end # class paramSetFactory
end # module ItkOacis

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  #--============================================================
  #++
  ## test conductor
  class FooConductor < ItkOacis::Conductor
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default configulation for initialization.
    DefaultConf = {
      :simulatorName => "foo00",
      :hostName => "localhost",
    } ;
    
    #----------------------------------------------------
    #++
    ## override runInit().
    def runInit()
      (0...10).each{|i|
        _x = rand() ;
        _param = { "x" => _x } ;
        spawnParamSet(_param) ;
      }
    end
    
    #--------------------------------------------------------------
    #++
    ## override cycleCheck().
    def cycleCheck()
      super() ;
      p [:count, @cycleCount] ;
    end
    #----------------------------------------------------
    #++
    ## override isFinished().
    def isFinished()
      return @cycleCount >= 10 ;
    end
    
  end # class FooConductor
  
  #--============================================================
  #++
  ## unit test for this file.
  class ItkTest

    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## Singleton of this Class.
    Singleton = self.new() ;
    ## test data
    TestData = nil ;

    #--==================================================
    #----------------------------------------------------
    #++
    ## list-up test methods.
    def self.listTestMethods()
      _r = [] ;
      Singleton.methods(true).each{|_method|
        _r.push(_method.to_s) if(_method.to_s =~ /^test_/) ;
      }
      return _r ;
    end

    #--==================================================
    #----------------------------------------------------
    #++
    ## run
    def self.run(_argv = [])
      _methodList = ((_argv.size == 0) ?
                       self.listTestMethods() :
                       _argv) ;
      _methodList.each{|_method|
        self.callTest(_method) ;
      }
    end
    
    #--==================================================
    #----------------------------------------------------
    #++
    ## call method of Singleton.
    def self.callTest(_method)
      if(self.listTestMethods.member?(_method)) then
        pp [:call, _method] ;
        Singleton.send(_method) ;
      else
        puts "Warning!!" ;
        pp [:no_test_method, _method] ;
      end
    end
    
    #----------------------------------------------------
    #++
    ## host name list.
    def test_a()
      _conductor = ItkOacis::Conductor.new() ;
      pp [:test_a, _conductor] ;
    end

    #----------------------------------------------------
    #++
    ## my conductor.
    def test_b()
      _conductor = FooConductor.new() ;
      pp [:test_b, _conductor] ;
      _conductor.run() ;
    end

  end # class ItkTest

  ##########################################
  ##########################################
  ##########################################
  
  ItkTest.run($*) ;
  
end # if($0 == __FILE__)
