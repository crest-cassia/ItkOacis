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
require 'logger' ;

require 'WithConfParam.rb' ;

require 'SimulatorStub.rb' ;
require 'HostStub.rb' ;
require 'ParamSetStub.rb' ;

#--======================================================================
module ItkOacis
  #--======================================================================
  #++
  ## to control functionarities of OACIS via Oacis Watcher facility.
  ## === Usage
  ##  class FooConductor < ItkOacis::Conductor
  ##    ## Override DefaultConf
  ##    DefaultConf = {
  ##      :simulatorName => "foo00",  # registered name on Oacis.
  ##      :hostName => "localhost",   # registered name on Oacis.
  ##    } ;
  ##    
  ##    ## override runInit().
  ##    def runInit()
  ##      fillRunningParamSetList(){|_seed, _i|
  ##        _x = rand() ;
  ##        _z = rand() ;
  ##        { "x" => _x, "z" => _z, }
  ##      } ;
  ##    end
  ##    
  ##    ## override cycleCheck().
  ##    def cycleBody()
  ##      super() ;
  ##      eachDoneParamSet(){|_psStub| pp [:done, _psStub.toJson()] ; }
  ##    end
  ##
  ##    ## override terminate?(). (use default in this sample).
  ##    def terminate?()
  ##      super() ;
  ##    end
  ##  end
  ##
  ##  # create a FooConductor and run.
  ##  conductor0 =   FooConductor.new() ;
  ##  conductor0.run() ;
  ##  # OR, to run jobs on "another_host"
  ##  conductor1 =   FooConductor.new({:host => "another_host"}) ;
  ##  conductor1.run() ;
  ##
  class Conductor < WithConfParam
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default values of _conf_ in new () method.
    ## It should be a Hash. 
    ## See below for meaning of each key:
    ## - :simulatorName : simulator. (default: "foo00")
    ## - :hostName : host. (default: "localhost")
    ## - :hostParam : host. (default: nil)
    ## - :paramSetClass : ParamSetStub class or its extended class,
    ##   used to manage parameter set (PS) in Oacis.
    ## - :nofRun : number of simulation runs per a ParamSetStub. (default: 1)
    ## - :defaultVariedParam : default value for newParamSet ().
    ##   See also defaultVariedParam. (default: {})
    ## - :nofInitParamSet : getNofInitParamSet (). (default: nil)
    ## - :interval : interval to wait each at cycle () in run (). (default: 1)
    ## - :logger : logger and setupLogger (). (default: :stderr)
    ## - :logLevel : one of :debug, :info, :warn, :error, and :fatal.
    ##   (default: :info)
    ##
    DefaultConf = {
      :simulatorName => "foo00",  ## hogehoge
      :hostName => "localhost",
      :hostParam => nil,
      :paramSetClass => ItkOacis::ParamSetStub,
      :nofRun => 1,
      :defaultVariedParam => {},
      :nofInitParamSet => nil,
      :interval => 1,  # sleep interval in run in sec.
      :logger => :stderr,
      :logLevel => :info,
      nil => nil } ;

    ## a table of LogLevel that maps from Symbol to Logger's LogLevel
    LogLevelTable = { :fatal => Logger::FATAL,
                      :error => Logger::ERROR,
                      :warn => Logger::WARN,
                      :info => Logger::INFO,
                      :debug => Logger::DEBUG,
                    } ;

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
    ## by key <tt>:nofRun</tt>.
    attr_reader :nofRun ;
    
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
    
    ## counter of whole ParamSet.
    attr_reader :nWholeParamSet ;
    ## list of running ParamSet.
    attr_reader :runningParamSetList ;
    ## list of finished or failed ParamSet.
    attr_reader :doneParamSetList ;

    ## an Array of Loggers.
    ## The definition of each elements are specified in _conf_ in new method
    ## by key <tt>:logger</tt> as follows:
    ## - <tt> :stdout </tt> :: STDOUT.
    ## - <tt> :stderr </tt> :: STDERR. (default)
    ## - String :: a filename.
    ## - IO :: IO stream.
    ## - Logger :: an instance of Logger
    ## - [ <Logger>, <Logger>, ... ] :: an Array of above.
    attr_reader :loggerList ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## initialize an instance.
    ## _conf_:: configulation for the initialization.
    ##          This override DefaultConf.
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
      @nofRun = getConf(:nofRun) ;
      @defaultVariedParam = getConf(:defaultVariedParam) ;
      
      @nWholeParamSet = 0 ;
      @runningParamSetList = [] ;
      @interval = getConf(:interval) ;

      setupLogger() ;

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
    ## to get the number of initial ParamSet.
    ## If <tt>:nofInitParamSet</tt> is specified in _conf_ in new(),
    ## its value is returned.
    ## If <tt>:nofInitParamSet</tt> is not specified,
    ## double of maxJobN is returned.
    ## Can be override in extended classes.
    ## *return*:: the number of ParamSet.
    def getNofInitParamSet()
      return (getConf(:nofInitParamSet) ||
              2 * @host.maxJobN()) ;
    end

    #--------------------------------------------------------------
    #++
    ## to setup @loggerList.
    ## The value of <tt>:logger</tt> in _spec_ in run() specifies 
    ## the type of logging device as follow:
    ## - :stdout : STDOUT.
    ## - :stderr : STDERR.
    ## - a String : a log filename.
    ## - an IO : a IO device for logging.
    ## - an Array : a list of above.  The log messages are outputted to
    ##   all of them.
    ## *return*:: an Array of Logger.
    def setupLogger()
      @loggerList = [] ;
      if(getConf(:logger)) then
        setupLoggerBody(getConf(:logger)) ;
      end
      return @loggerList ;
    end

    #--------------------------------------------------------------
    #++
    ## to setup @loggerList (body).
    ## _loggerSpec_:: a specification of the Logger.
    ## *return*:: an Array of Logger.
    def setupLoggerBody(_loggerSpec)
      _logdev = nil ;
      if   (_loggerSpec == :stdout) then
        _logdev = STDOUT ;
      elsif(_loggerSpec == :stderr) then
        _logdev = STDERR ;
      elsif(_loggerSpec.is_a?(IO)) then
        _logdev = _loggerSpec ;
      elsif(_loggerSpec.is_a?(String)) then
        _logdev = _loggerSpec ;
      elsif(_loggerSpec.is_a?(Array)) then
        _loggerSpec.each{|_spec| setupLoggerBody(_spec) ; } ;
      else
        raise "unknown Logger specification: " + _loggerSpec.inspect ;
      end

      if(_logdev) then
        _logger = Logger.new(_logdev,
                             level: LogLevelTable[getConf(:logLevel)],
                             datetime_format: "%Y-%m-%d_%H:%M:%S") ;
        @loggerList.push(_logger) ;
      end

      return _logger ;
    end  

    #--------------------------------------------------------------
    #++
    ## to logging information.
    ## _level_:: log level.
    ## _message_:: 
    def logging(_level, *_message)
      _fullMessage = _message.join(" ") ;
      @loggerList.each{|_logger|
        _logger.log(LogLevelTable[_level], _fullMessage) ;
      }
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
    ## the size of initial set equals to getNofInitParamSet().
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
      logging(:info, :cycle, @cycleCount,
              [getNofInitParamSet(), nofRunning(), nofDone()].inspect) ; 
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
      return nofRunning() == 0 ;
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to get number of running ParamSet.
    ## *return*:: the number of ParamSet in @runningParamSetList.
    def nofRunning()
      return @runningParamSetList.size ;
    end

    #--------------------------------------------------------------
    #++
    ## to get number of done ParamSet.
    ## *return*:: the number of ParamSet in @doneParamSetList.
    def nofDone()
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
    ## If _block_ is given, it calls _block_ with arguments _paramSeed_ and _i_,
    ## where _paramSeed_ is the same one of given _paramSeed_, and _i_ indicate
    ## nth in the generating ParamSet.
    ## The return value of _block_ is passed to spawnParamSet () instead of
    ## _paramSeed_.
    ## _n_:: the number of ParamSetStub to spawn.
    ## _paramSeed_:: a Hash of paramter set. Can be partial.
    ## _block_:: a procedure to generate paramSeed to pass createParamSet ().
    ## *return*:: an Array of ParamSetStub to be generated.
    ## :call-seq:
    ##     spawnParamSetN(_n) 
    ##     spawnParamSetN(_n, _paramSeed) 
    ##     spawnParamSetN(_n){|_paramSeed, _i| ... }
    ##     spawnParamSetN(_n, _paramSeed){|_paramSeed, _i| ... }
    def spawnParamSetN(_n, _paramSeed = nil, &_block) # :yield: _paramSeed_, _i_
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
    ## If _block_ is given, _paramSeed_ is modified as described in
    ## spawnParamSetN ().
    ## _max_:: maximum number to fill.  If nil, use getNofInitParamSet().
    ## _paramSeed_:: a Hash of paramter set. Can be partial.
    ## _block_:: a procedure to generate paramSeed to pass createParamSet ().
    ## *return*:: an Array of ParamSetStub to be generated.
    ## :call-seq:
    ##     fillRunningParamSetList()
    ##     fillRunningParamSetList(_n) 
    ##     fillRunningParamSetList(_n, _paramSetSeed)) 
    ##     fillRunningParamSetList(){|_paramSeed, _i| ... }
    ##     fillRunningParamSetList(_n){|_paramSeed, _i| ... }
    ##     fillRunningParamSetList(_n, _paramSetSeed)){|_paramSeed, _i| ... }
    def fillRunningParamSetList(_max = nil, _paramSeed = nil,
                                &_block) # :yield: _paramSeed_, _i_
      _max = getNofInitParamSet() if(_max.nil?) ;
      _n = _max - nofRunning() ;
      spawnParamSetN(_n, _paramSeed, &_block)
    end
      
    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to create ParamSetStub.
    ## Can be override.
    ## _varied_:: a paried information to generate ParamSet.
    ## _nofRun_:: number of runs.
    ## *return*:: a ParamSetStub.
    def newParamSet(_varied = @defaultVariedParam, _nofRun = @nofRun)
      _param = setupNewParam(_varied) ;
      _psStub = @paramSetClass.new(_param, self, _nofRun) ;
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
    ## _nofRun_:: number of runs.
    def runParamSet(_psStub, _nofRun)
      host().createRuns(_psStub, _nofRun) ;
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
      :nofRun => 3,
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
      eachDoneParamSet(){|_psStub|
        pp [:all, _psStub.toJson(:whole, :all)] ;
        pp [:ave, _psStub.toJson(:whole, :average)] ;
        pp [:first, _psStub.toJson(:whole, :first)] ;
        pp [:last, _psStub.toJson(:whole, :last)] ;
        pp [:_1th, _psStub.toJson(:whole, 1)] ;
        pp [:ave, _psStub.toJson(:whole, :stat)] ;
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
