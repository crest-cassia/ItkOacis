#! /usr/bin/env ../../,Work/oacis_current/bin/oacis_ruby
#! /usr/bin/env ../../oacis/bin/oacis_ruby
## -*- mode: ruby -*-
## = Multi-Objection Genetic Algorithm
## Author:: Itsuki Noda
## Version:: 0.0 2019/12/11 I.Noda
##
## === History
## * [2019/12/11]: Create This File.
## * [YYYY/MM/DD]: add more
## == Usage
## * ...

def $LOAD_PATH.addIfNeed(path)
  self.unshift(path) if(!self.include?(path)) ;
end

# $LOAD_PATH.addIfNeed("~/lib/ruby");
$LOAD_PATH.addIfNeed(File.dirname(__FILE__));
$LOAD_PATH.addIfNeed(File.dirname(__FILE__) + "/itkLib");

require 'pp' ;
require 'json' ;

require 'WithConfParam.rb' ;
require 'Stat/Random.rb' ;
require 'Stat/StatInfo.rb' ;

# require 'SimulatorStub.rb' ;
# require 'Conductor.rb' ;

#--======================================================================
module ItkOacis
  #--======================================================================
  #++
  ## Stub of ParameterSet
  class ParamSetStub
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## counter for max id
    @@maxId = 0 ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## ID
    attr_reader :id ;
    ## seed parameter in a Hash.
    attr_reader :seedParam ;
    ## parameter set in OACIS
    attr_reader :entity ;
    ## list of run
    attr_reader :runList ;

    #--------------------------------------------------------------
    #++
    ## initialize
    ## _seedParam_:: seed of parameters in a Hash.
    ## _conductor_:: a Conductor.
    ## _nofRun_:: a number of runs.
    def initialize(_seedParam, _conductor, _nofRun)
      @id = @@maxId ;
      @@maxId += 1 ;
      
      createAndRun(_seedParam, _conductor, _nofRun) ;
    end

    #--------------------------------------------------------------
    #++
    ## create PS and Run
    ## _seedParam_:: parameters in a Hash.
    ## _conductor_:: a Conductor.
    ## _nofRun_:: a number of runs.
    def createAndRun(_seedParam, _conductor, _nofRun)
      @seedParam = _seedParam ;
      @entity = _conductor.createPs(@seedParam) ;
      _conductor.runParamSet(self, _nofRun) ;
      
      @runList = [] ;
      @entity.runs.each{|_run|
        @runList.push(_run) ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## get number of runs.
    ## *return* :: a number of runs.
    def nofRuns()
      return @runList.size() ;
    end

    #--------------------------------------------------------------
    #++
    ## get number of runs specified by _nth ;
    ## *return* :: a number of runs.
    def nofRunsInNth(_nth)
      return (_nth == :all ? nofRuns() : 1) ;
    end

    #--------------------------------------------------------------
    #++
    ## get Nth run.
    ## _nth_ :: an Integer or :first or :last or a Run.
    ## *return* :: a Run.
    def nthRun(_nth)
      case(_nth)
      when Run ; return _nth ;
      when Integer ; return @runList[_nth] ;
      when :first ; return @runList.first ;
      when :last ; return @runList.last ;
      else
        raise "unknown _nth index type for @runList: " + _nth.inspect ;
      end
    end
    
    #--------------------------------------------------------------
    #++
    ## call block for each run.
    ## _block_:: a block to call.
    def eachRun(&_block)
      @runList.each{|_run|
        _block.call(_run) ;
      }
    end
    
    #--------------------------------------------------------------
    #++
    ## call block for the nth run.
    ## _nth_ :: an Integer or :first or :last or :all.
    ## _block_:: a block to call.
    def doWithNthRun(_nth, &_block)
      if(_nth == :all) then
        return eachRun(&_block) ;
      else
        return _block.call(nthRun(_nth)) ;
      end
    end
    
    #--------------------------------------------------------------
    #++
    ## sync status.
    ## _nth_ :: an Integer or :first or :last or :all.
    def sync(_nthRun = :all)
      doWithNthRun(_nthRun){|_run|
        _run.reload() ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## check run status
    ## _syncP_:: if true, sync to Oacis DB.
    ## _nth_ :: an Integer or :first or :last or :all.
    ## *return*:: an Array of the status if _nth_ == :all.
    def collectRunStatus(_syncP = false, _nth = :all)
      _statusList = [] ;
      doWithNthRun(_nth){|_run|
        sync(_run) if(_syncP) ;
        _statusList.push(_run.status) ;
      }
      return _statusList ;
    end
    
    #--------------------------------------------------------------
    #++
    ## check run status to be a _status_.
    ## _targettype_:: one of :finished, :failed, :running...
    ## _syncP_:: if true, sync to Oacis DB.
    ## _nth_ :: an Integer or :first or :last or :all.
    ## _mode_ :: :and or :or.
    ## *return*:: run status 
    def countRunStatus(_reference, _syncP = false, _nth = :all)
      _count = 0 ;
      doWithNthRun(_nth){|_run|
        sync(_run) if(_syncP) ;
        if(_reference.is_a?(Array)) then
          _count += 1 if(_reference.member?(_run.status)) ;
        else
          _count += 1 if(_reference == _run.status) ;
        end
      }
      return _count ;
    end
    
    #--------------------------------------------------------------
    #++
    ## check all runs specified by _nth_ are in a certain status.
    ## _syncP_:: if true, sync to Oacis DB.
    ## _nth_ :: an Integer or :first or :last or :all.
    ## _mode_ :: :and or :or.
    ## *return*:: run status 
    def checkRunStatus(_reference, _syncP = false, _nth = :all, _mode = :and)
      _threshold = nofRunsInNth(_nth) ;
      _count = countRunStatus(_reference, _syncP, _nth) ;
      return ((_mode == :and) ? (_count >= _threshold) : _count > 0) ;
    end
      
    #--------------------------------------------------------------
    #++
    ## check all runs specified by _nth_ are finished.
    ## _syncP_:: if true, sync to Oacis DB.
    ## _nth_ :: an Integer or :first or :last or :all.
    ## _mode_ :: :and or :or.
    ## *return*:: run status 
    def finished?(_syncP = false, _nth = :all, _mode = :and)
      return checkRunStatus(:finished, _syncP, _nth, _mode) ;
    end

    #--------------------------------------------------------------
    #++
    ## check run status
    ## _syncP_:: if true, sync to Oacis DB.
    ## _mode_ :: :and or :or.
    ## *return*:: run status 
    def failed?(_syncP = false, _nth = :all, _mode = :and)
      return checkRunStatus(:failed, _syncP, _nth, _mode) ;
    end

    #--------------------------------------------------------------
    #++
    ## check run status
    ## _syncP_:: if true, sync to Oacis DB.
    ## *return*:: run status 
    def done?(_syncP = false, _nth = :all, _mode = :and)
      return checkRunStatus([:finished, :failed], _syncP, _nth, _mode) ;
    end

    #--------------------------------------------------------------
    #++
    ## get input table in hash.
    ## *return*:: input hash.
    def getInputTable()
      return @entity.v ;
    end
    
    #--------------------------------------------------------------
    #++
    ## get input value by name in hash.
    ## *return*:: result value
    def getInput(_name)
      return getInputTable()[_name] ;
    end

    #--------------------------------------------------------------
    #++
    ## get result table in hash.
    ## _nth_ :: an Integer or :first or :last or :all or :average or :stat.
    ## _syncP_:: if true, sync to Oacis DB.
    ## *return*:: result hash.
    def getResultTable(_nth = :all, _sync = false)
      _nthForLoop = ((_nth == :average || _nth == :stat) ? :all : _nth) ;
      if(done?(_sync, _nthForLoop)) then
        _resultList = [] ;
        doWithNthRun(_nthForLoop){|_run|
          _resultList.push(_run.result) ;
        }
        if(_nth == :all) then
          return _resultList ;
        elsif(_nth == :average || _nth == :stat) then
          _stat = {} ;
          _resultList.each{|_result|
            _result.each{|_key, _value|
              _stat[_key] = Stat::StatInfo.new() if(_stat[_key].nil?) ;
              _stat[_key].put(_value) ;
            }
          }
          if(_nth == :average) then
            _ave = {} ;
            _stat.each{|_key, _value| _ave[_key] = _value.average() ;}
            return _ave ;
          else
            return _stat ;
          end
        else
          return _resultList.first ;
        end
      else
        return nil ;
      end
    end
    
    #--------------------------------------------------------------
    #++
    ## get result by name in hash.
    ## _name_:: the name of result data.
    ## _nth_ :: an Integer or :first or :last or :all or :average or :stat.
    ## _syncP_:: if true, sync to Oacis DB.
    ## *return*:: result value
    def getResult(_name, _nth = :all, _sync = false)
      _resultTab = getResultTable(_nth, _sync) ;
      if(_resultTab.is_a?(Array)) then
        return _resultTab.map{|_tab| _tab[_name]} ;
      elsif(_resultTab) then
        return _resultTab[_name] ;
      else
        return nil ;
      end
    end

    #--------------------------------------------------------------
    #++
    ## generate JSON object for log.
    ## _mode_:: mode of the conversion.
    ## _runs_:: specify which runs include.
    ##          If :all, return Array of information of runs inside JSON.
    ##          If :average, return average table of result.
    ##          If :first or :last, return ones of the first or last run.
    ##          If an Integer, return ones of the nth run.
    ## *return*:: json object (Hash)
    def toJson(_mode = nil, _runs = :all)
      _mode = :whole if(_mode.nil?) ;
      
      _json = nil ;
      case(_mode)
      when(:whole)
        _json = { :id => @id,
                  :seedParam => @seedParam,
                  :input => getInputTable(),
                  :result => getResultTable(_runs),
                } ;
      when(:result)
        _json = { :id => @id,
                  :result => getResultTable(_runs),
                } ;
      when(:input)
        _json = { :id => @id,
                  :input => getInputTable(),
                } ;
      else
        raise "unknown conversion mode:" + _mode.inspect ;
      end
      
      return _json ;
    end
    
    #--============================================================
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #--------------------------------------------------------------
  end # class ParamSetStub
end # module ItkOacis


######################################################################
######################################################################
######################################################################
if($0 == __FILE__) then

  #--============================================================
  #++
  # :nodoc: all
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
      pp [:test_a] ;
    end

  end # class ItkTest

  ##########################################
  ##########################################
  ##########################################
  
  ItkTest.run($*) ;
  
end # if($0 == __FILE__)
  
