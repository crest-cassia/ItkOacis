#! /usr/bin/env ../../oacis/bin/oacis_ruby
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
require 'HostStub.rb' ;
require 'ParamSetFactory.rb' ;

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
      :paramSetFactoryClass => ItkOacis::ParamSetFactory,
      :nPooledParamSet => nil,
      :paramSetFactoryConf => {},
      :interval => 1,  # sleep interval in run in sec.
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## stub to simulator entity.
    attr_reader :simulator ;
    ## stub to host or host group.
    attr_reader :host ;
    ## ParamSetFactory ;
    attr_reader :paramSetFactory ;
    ## counter of whole ParamSet.
    attr_reader :nWholeParamSet ;
    ## size of pooled ParamSet.  Generally, set doubled maxJobN of @host.
    attr_reader :nPooledParamSet ;
    ## list of running ParamSet.
    attr_reader :runningParamSetList ;
    ## list of finished ParamSet.
    attr_reader :finishedParamSetList ;
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

      @paramSetFactory =
        getConf(:paramSetFactoryClass).new(self,
                                           getConf(:paramSetFactoryConf)) ;
      
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

        cycle() ;
        
        @cycleCount += 1 ;
        break if(terminate?()) ;
      end

      runFinal() ;
    end

    #--------------------------------------------------------------
    #++
    ## to initialize run process.
    ## In default, raise exception.
    ## It can be overrided by expanded classes.
    def runInit()
      raise "runInit() is not defined." ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to check status as a cycle.
    ## In default, update status.
    ## It can be overrided by expanded classes.
    def cycle()
      checkRunning() ;
      cycleBody() ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to update all status.
    ## If some ParamSets are finished,
    ## they move from @runningParamSetList to @finishedParamSetList.
    def checkRunning() 
      syncAll() ;
      
      @finishedParamSetList = [] ;
      eachRunningParamSet(){|_psStub|
        @finishedParamSetList.push(_psStub) if(_psStub.finished?()) ;
      }
      eachFinishedParamSet(){|_psStub|
        @runningParamSetList.delete(_psStub) ;
      }
      
    end

    #--------------------------------------------------------------
    #++
    ## to update all status.
    def syncAll()
      @simulator.syncAll() ;
      eachRunningParamSet(){|_psStub|
        _psStub.sync() ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## to execute body operation for a cycle just after checkRunning() ;
    ## In default, do nothing.
    ## It can be overrided by expanded classes.
    def cycleBody() 
      # do nothing indefault.
    end
    
    #--------------------------------------------------------------
    #++
    ## to finalize run process.
    ## In default, do nothing.
    ## It can be overrided by expanded classes.
    def runFinal()
      # do nothing.
    end

    #--------------------------------------------------------------
    #++
    ## to check conditions to terminate run-loop.
    ## In default, output log.
    ## It can be overrided by expanded classes.
    ## *return*:: true when the conditions to terminate are satisfied.
    def terminate?()
      return false ;
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to get number of running ParamSet.
    ## *return*:: the number of ParamSet in @runningParamSetList.
    def nRunning()
      return @runningParamSetList.size ;
    end

    #--------------------------------------------------------------
    #++
    ## to get number of finished ParamSet.
    ## *return*:: the number of ParamSet in @finishedParamSetList.
    def nFinished()
      return @finishedParamSetList.size ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to call block for each running ParamSet.
    ## _&block_:: a procedure to call with each running ParamSet.
    def eachRunningParamSet(&_block)
      @runningParamSetList.each{|_psStub|
        _block.call(_psStub) ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## to call block for each finished ParamSet.
    ## _&block_:: a procedure to call with each finished ParamSet.
    def eachFinishedParamSet(&_block)
      @finishedParamSetList.each{|_psStub|
        _block.call(_psStub) ;
      }
    end
    
    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to spawn a ParamSetStub and push to a running list.
    ## _paramSeed_:: a Hash of paramter set. Can be partial.
    ## *return*:: a ParamSetStub.
    def spawnParamSet(_paramSeed = nil)
      if(_paramSeed) then
        _psStub = @paramSetFactory.newParamSet(_paramSeed) ;
      else
        _psStub = @paramSetFactory.newParamSet() ;
      end
      
      @runningParamSetList.push(_psStub) ;
      return _psStub ;
    end

    #--------------------------------------------------------------
    #++
    ## to spawn _n_ ParamSetStub and push to a running list.
    ## _n_:: the number of ParamSetStub to spawn.
    ## _paramSeed_:: a Hash of paramter set. Can be partial.
    ## _block_:: a procedure to generate paramSeed.
    ## *return*:: an Array of ParamSetStub to be generated.
    def spawnParamSetN(_n, _paramSeed = nil, &_block)
      _list = [] ;
      (0..._n).each{|_i|
        if(_block) then
          _seed = _block.call(_paramSeed, _i) ;
        else
          _seed = _paramSeed ;
        end
        _ps = spawnParamSet(_seed) ;
        _list.push(_ps) ;
      }
      return _list ;
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
      spawnParamSetN(10){|_seed, _i|
        _x = rand() ;
        _z = rand() ;
        { "x" => _x,
          "z" => _z, }
      } ;
    end
    
    #--------------------------------------------------------------
    #++
    ## override cycleCheck().
    def cycleBody()
      super() ;
      p [:count, @cycleCount] ;
      eachFinishedParamSet(){|_psStub|
        pp [:finished, _psStub.toJson()] ;
      }
    end
    #----------------------------------------------------
    #++
    ## override isFinished().
    def terminate?()
      return nRunning() == 0 ;
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
