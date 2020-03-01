#! /usr/bin/env ruby
# coding: utf-8
## -*- mode: ruby -*-
## = Itk Oacis Simulator stub
## Author:: Itsuki Noda
## Version:: 0.0 2019/12/11 I.Noda
##
## === History
## * [2019/12/11]: Create This File.
## * [2020/02/14]: copy from OacisStub to ItkOacis
## == Usage
## * ...

def $LOAD_PATH.addIfNeed(path)
  self.unshift(path) if(!self.include?(path)) ;
end

$LOAD_PATH.addIfNeed(File.dirname(__FILE__));
$LOAD_PATH.addIfNeed(File.dirname(__FILE__) + "/itkLib");

require 'WithConfParam.rb' ;


#--======================================================================
#++
## package module of Interactive Toolkit for Oacis.
module ItkOacis
  #--======================================================================
  #++
  ## to use Simulator in Oacis from ItkOacis Conductor
  class SimulatorStub < WithConfParam
    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get simulator name list.
    ## *return*:: an Array of names of registered simulators in String.
    def self.getSimulatorNameList()
      return ::Simulator.asc().all.as_json.map{|_sim| _sim["name"]} ;
    end
    
    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get simulator entry by name.
    ## _name_:: the name of simulator in String.
    ## _safeP_:: If false, it raises an exception when the named simulator
    ##           does not found.  If true, it just return nil when not found.
    ## *return*:: a Simulator object.
    def self.getSimulatorByName(_name, _safeP = false)
      if(_safeP) then
        begin
          return self.getSimulatorByName(_name, false) ;
        rescue => _ex
          return nil ;
        end
      else
        return ::Simulator.find_by_name(_name) ;
      end
    end
    
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## description of DefaultOptsions.
    DefaultConf = {
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## the name of Simulator
    attr_reader :name ;
    ## the entity of Simulator in Oacis.
    attr_reader :entity ;

    #--------------------------------------------------------------
    #++
    ## initialize.
    ## _name_:: name of Simulator in Oacis.
    def initialize(_name = nil)
      setEntityByName(_name) if(_name) ;
    end

    #--------------------------------------------------------------
    #++
    ## to get Simulator entity from Oacis.
    ## It raises an exception if the name is not found in the registory.
    ## _name_:: name of Simulator.
    ## *return*:: an Simulator engity.
    def setEntityByName(_name)
      @name = _name ;
      @entity = self.class.getSimulatorByName(_name, false) ;
      return @entity ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to get the list of parameter definitions.
    ## *return*:: an Array of ParameterDefinition.
    def getParamDefList()
      return @entity.parameter_definitions ;
    end

    #--------------------------------------------------------------
    #++
    ## to get the parameter definitions specified by _name_.
    ## If there are no _named_ parameter, raise an exception.
    ## _name_:: the name of parameter.
    ## *return*:: the ParameterDefinition.
    def getParamDef(_name)
      _nameStr = _name.to_s() ;
      getParamDefList().each{|_paramDef|
        return _paramDef if(_paramDef.key == _nameStr) ;
      }
      raise "unknown paramter definition with name: " + _name.inspect ;
    end
    
    #--------------------------------------------------------------
    #++
    ## generate param. set and run.
    ## _param_:: parameter set. should be instance of Hash.
    ## _worker_:: worker host to run.
    ## _hostParam_:: parameter for the worker host (xsub params)
    ## _numRan_:: the number of runs.
    ## *return*:: parameter set (Ps)
    def _createPsAndRun(_param,  _worker, _hostParam = nil, _numRun = 1)
      _ps = @entity.find_or_create_parameter_set(_param) ;
      _ps.find_or_create_runs_upto(1,
                                   submitted_to: _worker,
                                   host_param: _hostParam) ;
      return _ps ;
    end

    #--------------------------------------------------------------
    #++
    ## run body script for each parameter.
    ## _body_:: script to run.  Each param set is passed as an argument.
    def eachPs(&body)
      @entity.parameter_sets.each{|_ps|
        body.call(_ps) ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## run body script for each run.
    ## _body_:: script to run.  Each run is passed as an argument.
    def eachRun(&body)
      eachPs(){|_ps|
        _ps.runs.each{|_run|
          body.call(_run) ;
        }
      }
    end

    #--------------------------------------------------------------
    #++
    ## sync simulator to DB in Oacis.
    def sync()
      @entity.reload() ;
    end
    
    #--------------------------------------------------------------
    #++
    ## sync PSs to DB in Oacis.
    def syncAllPs()
      sync() ;
      eachPs(){|_ps|
        _ps.reload() ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## sync runs to DB in Oacis.
    def syncAllRun()
      syncAllPs() ;
      eachRun(){|_run|
        _run.reload() ;
      }
    end
    
    #--------------------------------------------------------------
    #++
    ## sync everything.
    def syncAll()
      syncAllRun() ;
    end

    #--============================================================
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #--------------------------------------------------------------
  end # class SimulatorStub
end # module ItkOacis

########################################################################
########################################################################
########################################################################


