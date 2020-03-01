#! /usr/bin/env ruby
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
require 'SimulatorStub.rb' ;
require 'Stat/Random.rb' ;
require 'Conductor.rb' ;

#--======================================================================
#++
## package module of Interactive Toolkit for Oacis.
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
    ## ItkOacis::Conductor
    attr_reader :conductor ;
    ## parameter in a Hash.
    attr_reader :param ;
    ## parameter set in OACIS
    attr_reader :entity ;
    ## list of run
    attr_reader :runList ;
    ## last run
    attr_reader :run ;

    #--------------------------------------------------------------
    #++
    ## initialize
    ## _conductor_:: a Conductor
    ## _param_:: parameters in a Hash.
    ## _runP_:: if true, submit run.
    def initialize(_conductor, _param, _runP = true)
      @id = @@maxId ;
      @@maxId += 1 ;
      
      @conductor = _conductor ;
      @param = _param ;
      createPsAndRun() if(_runP) ;
    end

    #--------------------------------------------------------------
    #++
    ## create PS and Run
    ## _nRun_:: number of run
    ## *return*:: about return value
    def createPsAndRun(_nRun = 1)
      @entity = @conductor.simStub.createPsAndRun(@param, @conductor.worker,
                                            @conductor.getWorkerHostParam(),
                                            _nRun) ;
      @runList = [] ;
      @entity.runs.each{|_run|
        @runList.push(_run) ;
      }
      @run = @runList.last ;
      return self ;
    end

    #--------------------------------------------------------------
    #++
    ## check run status
    ## *return*:: run status 
    def checkRunStatus()
      @run.reload() ;
      return @run.status ;
    end
    
    #--------------------------------------------------------------
    #++
    ## check run status
    ## *return*:: run status 
    def done?()
      _status = checkRunStatus() ;
      return (_status == :finished || _status == :failed) ;
    end

    #--------------------------------------------------------------
    #++
    ## check run status
    ## *return*:: run status 
    def finished?()
      _status = checkRunStatus() ;
      return (_status == :finished) ;
    end

    #--------------------------------------------------------------
    #++
    ## check run status
    ## *return*:: run status 
    def failed?()
      _status = checkRunStatus() ;
      return (_status == :failed) ;
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
                  :param => @param,
                  :result => getResultTable(),
                } ;
      when(:result)
        _json = { :id => @id,
                  :result => getResultTable(),
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

