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
  ##    ## override runInitPrepareParamSetList().
  ##    def runInitPrepareParamSetList()
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
  ##      eachDoneInCycle(){|_psStub| pp [:done, _psStub.toJson()] ; }
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
    ## - :configFile : filename to save configuiation.
    ##   If nil, do not save.
    ##   (default: "~/tmp/itkOacisConductor.config.json")
    ## - :resultFile : filename to save results.
    ##   If nil, do not save.
    ##   (default: "~/tmp/itkOacisConductor.result.json")
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
      :logger => [:stderr],
      :logLevel => :info,
      :configFile => "~/tmp/itkOacisConductor.config.json",
      :resultFile => "~/tmp/itkOacisConductor.result.json",
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
    ## list of finished or failed ParamSet in the current cycle.
    attr_reader :doneInCycleList ;

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
      setupLogger() ;
      
      setSimulator(getConf(:simulatorName)) ;
      setHost(getConf(:hostName), getConf(:hostParam)) ;

      @paramSetClass = getConf(:paramSetClass) ;
      @nofRun = getConf(:nofRun) ;
      @defaultVariedParam = getConf(:defaultVariedParam) ;
      
      @nWholeParamSet = 0 ;
      @runningParamSetList = [] ;
      @doneParamSetList = [] ;
      @interval = getConf(:interval) ;

      loggingInfo(:setup, :done) ;
    end

    #--------------------------------------------------------------
    #++
    ## to set SimulatorStub by name.
    ## _simName_:: the name of simulator.
    ## *return*:: the SimulatorStub.
    def setSimulator(_simName)
      @simulator = SimulatorStub.new(_simName) ;
      loggingInfo(:setSimulator, _simName) ;
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
      loggingInfo(:setHost, _hostName, _hostParam) ;
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
      loggingInfo(:setupLogger, :done) ;
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
                             formatter: proc{|severity, datetime, progname, msg|
                               ("[#{datetime.strftime("%Y-%m-%d_%H:%M:%S")}] " +
                                severity + " " +
                                msg + "\n") }) ;
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

    #--------------------------------------------------------------
    #++
    ## to logging information.
    ## _level_:: log level.
    ## _label_:: label for the log message.
    ## _values_:: values to output. Each of them are inspected for the message. 
    def loggingInspected(_level, _label, *_values)
      _logP = false ;
      _logLevel = LogLevelTable[_level] ;
      @loggerList.each{|_logger|
        if(_logLevel >= _logger.level) then
          _logP = true ;
          break ;
        end
      }
      if(_logP) then
        _fullMessage = _label.to_s + ": " ;
        _fullMessage +=
          _values.map{|_val| _val.inspect}.join(", ") ;
        @loggerList.each{|_logger|
          _logger.log(_logLevel, _fullMessage) ;
        }
      end
    end
      
    #--------------------------------------------------------------
    #++
    ## to logging information in DEBUG level.
    ## _label_:: label for the log message.
    ## _values_:: values to output. Each of them are inspected for the message. 
    def loggingDebug(_label, *_values)
      loggingInspected(:debug, _label, *_values) ;
    end      

    #--------------------------------------------------------------
    #++
    ## to logging information in INFO level.
    ## _label_:: label for the log message.
    ## _values_:: values to output. Each of them are inspected for the message. 
    def loggingInfo(_label, *_values)
      loggingInspected(:info, _label, *_values) ;
    end      

    #--------------------------------------------------------------
    #++
    ## to logging information in WARN level.
    ## _label_:: label for the log message.
    ## _values_:: values to output. Each of them are inspected for the message. 
    def loggingWarn(_label, *_values)
      loggingInspected(:warn, _label, *_values) ;
    end      

    #--------------------------------------------------------------
    #++
    ## to logging information in ERROR level.
    ## _label_:: label for the log message.
    ## _values_:: values to output. Each of them are inspected for the message. 
    def loggingError(_label, *_values)
      loggingInspected(:error, _label, *_values) ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to logging information in FATAL level.
    ## _label_:: label for the log message.
    ## _values_:: values to output. Each of them are inspected for the message. 
    def loggingFatal(_label, *_values)
      loggingInspected(:fatal, _label, *_values) ;
    end      

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## run loop
    def run()
      loggingInfo("run()") ;
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
    ## to prepare to start main run-loop.
    ## It call saveConfig () and runInitPrepareParamSetList()
    def runInit()
      loggingInfo("runInit()") ;
      saveConfig(getConf(:configFile)) ;
      runInitPrepareParamSetList() ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to generate initial set of ParamSets.
    ## the size of initial set equals to getNofInitParamSet().
    ## It can be overrided by expanded classes.
    def runInitPrepareParamSetList()
      loggingInfo("runInitPrepareParamSetList()") ;
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
    ## they move from @runningParamSetList to @doneInCycleList.
    ## They also push to @doneParamSetListInCycle.
    def checkRunning() 
      syncAll() ;
      
      @doneInCycleList = [] ;
      eachRunning(){|_psStub|
        if(_psStub.done?()) then
          @doneInCycleList.push(_psStub) ;
          @doneParamSetList.push(_psStub) ;
        end
      }
      @doneInCycleList.each(){|_psStub|
        @runningParamSetList.delete(_psStub) ;
      }
      
    end

    #--------------------------------------------------------------
    #++
    ## to update all status.
    ## _wholeP_ :: if true, sync whole Runs and ParamSets
    def syncAll(_wholeP = false)
      if(_wholeP) then
        @simulator.syncAll() ;
      else
        @simulator.sync() ;
      end
      eachRunning(){|_psStub|
        _psStub.sync() ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## to execute body operation for a cycle just after checkRunning() ;
    ## In default, do nothing.
    ## It can be overrided by expanded classes.
    def cycleBody() 
      loggingInfo(:cycle, @cycleCount,
                  [getNofInitParamSet(), nofRunning(),
                   nofDoneInCycle(), nofDone()]) ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to finalize run process.
    ## In default, do nothing.
    ## It can be overrided by expanded classes.
    def runFinal()
      saveResult(getConf(:resultFile)) ;
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
    ## to get number of done ParamSet in the current cycle.
    ## *return*:: the number of ParamSet in @doneInCycleList.
    def nofDoneInCycle()
      return @doneInCycleList.size ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to call block for each running ParamSet.
    ## _block_:: a procedure to call with each running ParamSet.
    def eachRunning(&_block) # :yield: _psStub
      @runningParamSetList.each{|_psStub|
        _block.call(_psStub) ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## to call block for each done ParamSet.
    ## _block_:: a procedure to call with each done ParamSet.
    def eachDone(&_block) # :yield: _psStub
      @doneParamSetList.each{|_psStub|
        _block.call(_psStub) ;
      }
    end
    
    #--------------------------------------------------------------
    #++
    ## to call block for each done ParamSet in the current cycle.
    ## _block_:: a procedure to call with each done ParamSet.
    def eachDoneInCycle(&_block) # :yield: _psStub
      @doneInCycleList.each{|_psStub|
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
      loggingInfo(:fillRunningParamSetList, [_max, _paramSeed]) ;
      _max = getNofInitParamSet() if(_max.nil?) ;
      _n = _max - nofRunning() ;
      _list = spawnParamSetN(_n, _paramSeed, &_block) ;
      loggingInfo(:fillRunningParamSetList, _n, :done) ;
      return _list ;
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
    ## File IO.
    #--------------------------------------------------------------
    #++
    ## save configulation to a file.
    ## _filename_ :: filename to save configulation.
    def saveConfig(_filename)
      if(_filename) then
        open(File::expand_path(_filename), "w"){|_strm|
          _strm << JSON.pretty_generate(@conf) << "\n" ;
        }
      end
    end
            
    #--------------------------------------------------------------
    #++
    ## save results to a file.
    ## _filename_ :: filename to save results.
    def saveResult(_filename)
      if(_filename) then
        _jsonList = prepareResultAsJsonList() ;
        open(File::expand_path(_filename), "w"){|_strm|
          _indent = "  " ;
          _sep = "\n" ;
          _strm << "[" ;
          _c = 0 ;
          _jsonList.each{|_json|
            _strm << "," if(_c > 0) ;
            _c += 1 ;
            _strm << _sep << _indent << JSON.generate(_json) ;
          }
          _strm << _sep << "]" << _sep ;
        }
      end
    end

    #--------------------------------------------------------------
    #++
    ## generate Json list of results.
    ## *return* :: an Array of Json Objects (Hash or Array).
    def prepareResultAsJsonList()
      _jsonList = [] ;
      @doneParamSetList.each{|_psStub|
        _jsonList.push(_psStub.toJson(:whole, :all)) ;
      }
      return _jsonList ;
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

  require "ItkOacis.rb" ;

  #--============================================================
  #++
  # :nodoc: all
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
    ## override runInitPrepareParamSetList().
    def runInitPrepareParamSetList()
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
      eachDoneInCycle(){|_psStub|
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
  # :nodoc: all
  ## unit test for this file.
  class ItkTest
    extend ItkOacis::ItkTestModule ;

    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## test data
    TestData = nil ;

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
