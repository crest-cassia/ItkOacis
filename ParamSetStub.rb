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

require 'pp' ;
require 'json' ;

require 'WithConfParam.rb' ;
require 'Stat/Random.rb' ;

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
    ## last run
    attr_reader :run ;

    #--------------------------------------------------------------
    #++
    ## initialize
    ## _seedParam_:: seed of parameters in a Hash.
    ## _factory_:: a ParamSetFactory.
    ## _nRun_:: a number of runs.
    def initialize(_seedParam, _factory, _nRun)
      @id = @@maxId ;
      @@maxId += 1 ;
      
      createAndRun(_seedParam, _factory, _nRun) ;
    end

    #--------------------------------------------------------------
    #++
    ## create PS and Run
    ## _seedParam_:: parameters in a Hash.
    ## _factory_:: a ParamSetFactory.
    ## _nRun_:: a number of runs.
    def createAndRun(_seedParam, _factory, _nRun)
      @seedParam = _seedParam ;
      @entity = _factory.createPs(@seedParam) ;
      _factory.runParamSet(self, _nRun) ;
      
      @runList = [] ;
      @entity.runs.each{|_run|
        @runList.push(_run) ;
      }
      @run = @runList.last ;
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
    ## sync status.
    def sync()
      eachRun(){|_run|
        _run.reload() ;
      }
    end
    
    #--------------------------------------------------------------
    #++
    ## check run status
    ## _syncP_:: if true, sync to Oacis DB.
    ## *return*:: run status 
    def checkRunStatus(_syncP = false)
      sync() if(_syncP) ;
      return @run.status ;
    end
    
    #--------------------------------------------------------------
    #++
    ## check run status
    ## _syncP_:: if true, sync to Oacis DB.
    ## *return*:: run status 
    def finished?(_syncP = false)
      sync() if(_syncP) ;
      return (checkRunStatus() == :finished) ;
    end

    #--------------------------------------------------------------
    #++
    ## check run status
    ## _syncP_:: if true, sync to Oacis DB.
    ## *return*:: run status 
    def failed?(_syncP = false)
      sync() if(_syncP) ;
      return (checkRunStatus() == :failed) ;
    end

    #--------------------------------------------------------------
    #++
    ## check run status
    ## _syncP_:: if true, sync to Oacis DB.
    ## *return*:: run status 
    def done?(_syncP = false)
      sync() if(_syncP) ;
      return (finished?(false) || failed?(false)) ;
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
    ## *return*:: result hash.
    def getResultTable()
      if(done?()) then
        return @run.result ;
      else
        return nil ;
      end
    end
    
    #--------------------------------------------------------------
    #++
    ## get result by name in hash.
    ## *return*:: result value
    def getResult(_name)
      _resultTab = getResultTable() ;
      if(_resultTab) then
        return _resultTab[_name] ;
      else
        return nil ;
      end
    end

    #--------------------------------------------------------------
    #++
    ## generate JSON object for log.
    ## _mode_:: mode of the conversion.
    ## *return*:: json object (Hash)
    def toJson(_mode = nil)
      _mode = :whole if(_mode.nil?)
      
      _json = nil ;
      case(_mode)
      when(:whole)
        _json = { :id => @id,
                  :seedParam => @seedParam,
                  :input => getInputTable(),
                  :result => getResultTable(),
                } ;
      when(:result)
        _json = { :id => @id,
                  :result => getResultTable(),
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
  
