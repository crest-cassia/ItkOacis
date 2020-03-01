#! /usr/bin/env ruby
## -*- mode: ruby -*-
## = Itk Oacis Conductor
## Author:: Itsuki Noda
## Version:: 0.0 2020/02/14 I.Noda
##
## === History
## * [2020/02/14]: Create This File.
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
require 'ParamSetSub.rb' ;


#--======================================================================
#++
## package module of Interactive Toolkit for Oacis.
module ItkOacis
  #--======================================================================
  #++
  ## to control functionarities of OACIS via Oacis Watcher facility.
  class Conductor < WithConfParam
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default configulation for initialization.
    DefaultConf = {
      :simulatorName => "foo00",
      :hostName => "localhost",
      :hostParam => nil,
      :paramSetClass => ParamSetStub,
      :nPooledParamSet => nil,
      :interval => 1,  # sleep interval in run in sec.
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## stub to simulator entity.
    attr_reader :simulator ;
    ## stub to host or host group.
    attr_reader :host ;
    ## counter of whole ParamSet.
    attr_reader :nWholeParamSet ;
    ## size of pooled ParamSet.  Generally, set doubled maxJobN of @host.
    attr_reader :nPooledParamSet ;
    ## list of running ParamSet.
    attr_reader :runningParamSetList ;
    ## duration of sleep in run cycle in sec.
    attr_reader :interval ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## initialize an instance.
    ## _conf_:: configulation for the initialization.
    def initialize(_conf = {})
      super(_conf) ;
      
      setSimulator(getConf(:simulatorName)) ;
      setHost(getConf(:hostName), getConf(:hostParam)) ;

      @nWholeParamSet = 0 ;
      @runningParamSetList = [] ;
      @interval = getConf(:interval) ;

      @nPooledParamSet = (getConf(:nPooledParamSet) ||
                          2 * @host.maxJobN()) ;
      
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## set SimulatorStub by name.
    ## _simName_:: the name of simulator.
    ## *return*:: the SimulatorStub.
    def setSimulator(_simName)
      @simulator = SimulatorStub.new(_simName) ;
      return @simulator ;
    end

    #--------------------------------------------------------------
    #++
    ## set HostStub by name.
    ## _hostName_:: the name of Host or HostGroup.
    ## _hostParam_:: a Hash of the parameters for the Host.
    ## *return*:: the HostStub.
    def setHost(_hostName, _hostParam = nil)
      @host = HostStub.new(_hostName, { :hostParam => _hostParam }) ;
      return @host ;
    end

    #--------------------------------------------------------------
    #++
    ## get number of running ParamSet.
    ## *return*:: the number of running ParamSet.
    def nRunningParamSet()
      return @runningParamSetList.size() ;
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## run loop
    def run()
      runInit() ;

      @cycleCount = 0 ;
      while(true)
        sleep(@interval) ;

        @cycleCount += 1 ;
        cycleCheck() ;

        break if(isFinished()) ;
      end

      runFinal() ;
    end

    #--------------------------------------------------------------
    #++
    ## to initialize run process.
    ## In default, spawn new parameter set to fill the pool.
    ## It can be overrided by expanded classes.
    def runInit()
      spawnNewParamSetN(@nPooledParamSet) ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to finalize run process.
    ## In default, output log.
    ## It can be overrided by expanded classes.
    def runFinal()
      logFinal() ;
    end
    
    

    #--////////////////////////////////////////////////////////////
    #--============================================================
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #--------------------------------------------------------------
  end # class Conductor
end # module ItkOacis

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  require 'test/unit'

  #--============================================================
  #++
  ## unit test for this file.
  class TC_Foo < Test::Unit::TestCase
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## desc. for TestData
    TestData = nil ;

    #----------------------------------------------------
    #++
    ## show separator and title of the test.
    def setup
#      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      name = "#{(@method_name||@__name__)}(#{self.class.name})" ;
      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    #----------------------------------------------------
    #++
    ## about test_a
    def test_a
      pp [:test_a] ;
      assert_equal("foo-",:foo.to_s) ;
    end

  end # class TC_Foo < Test::Unit::TestCase
end # if($0 == __FILE__)
