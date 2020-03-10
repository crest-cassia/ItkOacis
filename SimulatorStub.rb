#! /usr/bin/env ../../oacis/bin/oacis_ruby
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
    ## to generate default ParamSet Hash.
    ## _param_ :: a partial Hash of ParamSet.
    ## *return*:: a Hash of ParamSet.
    def genParamSetHash(_param = {})
      _paramSetHash = {} ;
      getParamDefList().each{|_paramDef|
        _paramSetHash[_paramDef.key] = (_param.key?(_paramDef.key) ?
                                          _param[_paramDef.key] :
                                          _paramDef.default) ;
      }
      return _paramSetHash ;
    end
    
    #--------------------------------------------------------------
    #++
    ## generate param. set (Ps).
    ## _param_:: parameter set. Should be a Hash. Can be partial.
    ## *return*:: parameter set (Ps)
    def createPs(_param)
      return @entity.find_or_create_parameter_set(genParamSetHash(_param)) ;
    end
    
    #--------------------------------------------------------------
    #++
    ## generate param. set and run.
    ## _param_:: parameter set. should be a Hash.
    ## _host_:: a HostStub to run.
    ## _numRan_:: the number of runs.
    ## *return*:: parameter set (Ps)
    def createPsAndRun(_param,  _host, _numRun = 1)
      _ps = createPs(_param) ;
      _host.createRuns(_ps, _numRun) ;
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
if($0 ==  __FILE__) then

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
    ## simulator name list.
    def test_a()
      pp [:test_a, ItkOacis::SimulatorStub.getSimulatorNameList()] ;
    end

    #----------------------------------------------------
    #++
    ## get simulator by name.
    def test_b()
      _sim = ItkOacis::SimulatorStub.getSimulatorByName("foo00") ;
      pp [:foo00, _sim] ;
    end
    
    #----------------------------------------------------
    #++
    ## new
    def test_c()
      _sim = ItkOacis::SimulatorStub.new("foo00") ;
      pp [:foo00, _sim] ;
    end
    
    #----------------------------------------------------
    #++
    ## param def list.
    def test_d()
      _sim = ItkOacis::SimulatorStub.new("foo00") ;
      pp [:paramDef, _sim.getParamDefList()] ;
    end
    
    #----------------------------------------------------
    #++
    ## param def by name.
    def test_e()
      _sim = ItkOacis::SimulatorStub.new("foo00") ;
      pp [:paramDef, _sim.getParamDef("y")] ;
    end
    
    #----------------------------------------------------
    #++
    ## gen param set hash.
    def test_f()
      _sim = ItkOacis::SimulatorStub.new("foo00") ;
      pp [:defaultParamSet, _sim.genParamSetHash({"y" => 2.0}) ]
    end
    

  end # class ItkTest

  ##########################################
  ##########################################
  ##########################################
  
  ItkTest.run($*) ;
  
end



