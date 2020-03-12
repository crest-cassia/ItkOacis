#! /usr/bin/env ../../,Work/oacis_current/bin/oacis_ruby
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
require 'ParamSetStub.rb' ;

#--======================================================================
module ItkOacis
  #--======================================================================
  #++
  ## to control functionarities of OACIS via Oacis Watcher facility.
  class Conductor < WithConfParam
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default values of _conf_ in new method.
    DefaultConf = {
      :simulatorName => "foo00",
      :hostName => "localhost",
      :hostParam => nil,
      :paramSetClass => ItkOacis::ParamSetStub,
      :nRun => 1,
      :defaultVariedParam => {},
      :interval => 1,  # sleep interval in run in sec.
      :nPooledParamSet => nil,
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## a SimulatorStub, stub to simulator entity.
    ## The simulator is looked up by the name registered in Oacis.
    ## The name is specified in _conf_ in new method
    ## by key <tt>:simulatorName</tt>. 
    attr_reader :simulator ;
    
    ## a HostStub, stub to host or host group.
    ## The host (host group) is looked up by the name registered in Oacis.
    ## The name is specified in _conf_ in new method
    ## by key <tt>:hostName</tt>.
    attr_reader :host ;
    
    ## ParamSetStub class.
    ## The class is specified in _conf_ in new method
    ## by key <tt>:paramSetClass</tt>.
    attr_reader :paramSetClass ;
    
    ## number of runs.
    ## The number of runs will be created and executed for each ParamSet.
    ## The number is specified in _conf_ in new method
    ## by key <tt>:nRun</tt>.
    attr_reader :nRun ;
    
    ## default varied ParamSet in Hash.
    ## When a new ParamSet is created, the value of each parameter is selected
    ## from specification in _varidParam_ argument in spawnParamSet,
    ## this defaultVariedParam, and the default of the simulator.
    ## The Hash is specified in _conf_ in new method
    ## by key <tt>:defaultVairdParam</tt>.
    attr_reader :defaultVariedParam ;

    ## duration of sleep in run cycle in sec.
    ## The duration is specified in _conf_ in new method
    ## by key <tt>:interval</tt>.
    attr_reader :interval ;
    
    ## size of pooled ParamSet.
    ## Generally, set doubled maxJobN of @host.
    ## The duration is specified in _conf_ in new method
    ## by key <tt>:nPooledParamSet</tt>.
    attr_reader :nPooledParamSet ;
    
    ## counter of whole ParamSet.
    attr_reader :nWholeParamSet ;
    ## list of running ParamSet.
    attr_reader :runningParamSetList ;
    ## list of finished or failed ParamSet.
    attr_reader :doneParamSetList ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## initialize an instance.
    ## _conf_:: configulation for the initialization.
    def initialize(_conf = {})
      super(_conf) ;

      setup() ;
    end

    #--------------------------------------------------------------
    #++
    ## to setup configulations.
    def setup()
      setSimulator(getConf(:simulatorName)) ;
      setHost(getConf(:hostName), getConf(:hostParam)) ;

      @paramSetClass = getConf(:paramSetClass) ;
      @nRun = getConf(:nRun) ;
      @defaultVariedParam = getConf(:defaultVariedParam) ;
      
      @nWholeParamSet = 0 ;
      @runningParamSetList = [] ;
      @interval = getConf(:interval) ;

      @nPooledParamSet = getInitialNPooledParamSet()
    end

    #--------------------------------------------------------------
    #++
    ## to set SimulatorStub by name.
    ## _simName_:: the name of simulator.
    ## *return*:: the SimulatorStub.
    def setSimulator(_simName)
      @simulator = SimulatorStub.new(_simName) ;
      return @simulator ;
    end

    #--------------------------------------------------------------
    #++
    ## to set HostStub by name.
    ## _hostName_:: the name of Host or HostGroup.
    ## _hostParam_:: a Hash of the parameters for the Host.
    ## *return*:: the HostStub.
    def setHost(_hostName, _hostParam = nil)
      @host = HostStub.new(_hostName, { :hostParam => _hostParam }) ;
      return @host ;
    end

    #--------------------------------------------------------------
    #++
    ## to get initial number of pooled ParamSet.
    ## *return*:: the number of ParamSet.
    def getInitialNPooledParamSet()
      return (getConf(:nPooledParamSet) ||
              2 * @host.maxJobN()) ;
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
    ## to generate initial set of ParamSets.
    ## In fillRunningParamSetList(),
    ## the size of initial set equals to nPooledParamSet.
    ## It can be overrided by expanded classes.
    def runInit()
      fillRunningParamSetList() ;
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
    ## If some ParamSets are done,
    ## they move from @runningParamSetList to @doneParamSetList.
    def checkRunning() 
      syncAll() ;
      
      @doneParamSetList = [] ;
      eachRunningParamSet(){|_psStub|
        @doneParamSetList.push(_psStub) if(_psStub.done?()) ;
      }
      eachDoneParamSet(){|_psStub|
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
      return nRunning() == 0 ;
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
    ## to get number of done ParamSet.
    ## *return*:: the number of ParamSet in @doneParamSetList.
    def nDone()
      return @doneParamSetList.size ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to call block for each running ParamSet.
    ## _block_:: a procedure to call with each running ParamSet.
    def eachRunningParamSet(&_block) # :yield: _psStub
      @runningParamSetList.each{|_psStub|
        _block.call(_psStub) ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## to call block for each done ParamSet.
    ## _block_:: a procedure to call with each done ParamSet.
    def eachDoneParamSet(&_block) # :yield: _psStub
      @doneParamSetList.each{|_psStub|
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
        _psStub = newParamSet(_paramSeed) ;
      else
        _psStub = newParamSet() ;
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

    #--------------------------------------------------------------
    #++
    ## to spawn multiple ParamSetStub to fill a running list.
    ## _paramSeed_:: a Hash of paramter set. Can be partial.
    ## _block_:: a procedure to generate paramSeed.
    ## *return*:: an Array of ParamSetStub to be generated.
    def fillRunningParamSetList(_paramSeed = nil, &_block)
      _n = @nPooledParamSet - nRunning() ;
      spawnParamSetN(_n, _paramSeed, &_block)
    end
      
    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to create ParamSetStub.
    ## Can be override.
    ## _varied_:: a paried information to generate ParamSet.
    ## _nRun_:: number of runs.
    ## *return*:: a ParamSetStub.
    def newParamSet(_varied = @defaultVariedParam, _nRun = @nRun)
      _param = setupNewParam(_varied) ;
      _psStub = @paramSetClass.new(_param, self, _nRun) ;
      return _psStub ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to setup ParamSet setting for new one.
    ## As a default, just return _seed.
    ## Can be override.
    ## _varied_:: a paried information to generate ParamSet.
    ## *return*:: a Hash of ParamSet setting.
    def setupNewParam(_varied)
      return _varied ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to create PS.
    ## _param_:: a Hash of a parameter set. Can be partial.
    ## *return*:: a Ps.
    def createPs(_param)
      return simulator().createPs(_param) ;
    end

    #--------------------------------------------------------------
    #++
    ## to run ParamSetStub on Host.
    ## _psStub_:: a ParamSetStub.
    ## _nRun_:: number of runs.
    def runParamSet(_psStub, _nRun)
      host().createRuns(_psStub, _nRun) ;
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
      fillRunningParamSetList(){|_seed, _i|
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
      p [:cycle, @cycleCount, nRunning(), nDone()] ;
      eachDoneParamSet(){|_psStub|
        pp [:done, _psStub.toJson()] ;
      }
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
