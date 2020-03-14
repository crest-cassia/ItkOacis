#! /usr/bin/env ../../,Work/oacis_current/bin/oacis_ruby
#! /usr/bin/env ../../oacis/bin/oacis_ruby
## -*- mode: ruby -*-
## = Itk Oacis Conductor for Random Search.
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
require 'Stat/Random.rb' ;

require 'ConductorRandom.rb' ;

#--======================================================================
module ItkOacis
  #--======================================================================
  #++
  ## Conductor that manages to ParamSet
  ## according to a simple GA (Genetic Algorithm) way.
  ##
  ## At the initialization,
  ## the Conductor create a population of ParamSet in the same way
  ## of ItkOacis::ConductorRandom.
  ## (See scatterPolicy setup in ItkOacis::ConductorRandom.)
  ##
  ## Then, the Conductor submits jobs and waits until all population are done.
  ## After all runs in the population of ParamSet complete,
  ## the Conductor evaluates them and create the next generation.
  ##
  ## This process is repeated until a certain alternation cycle.
  ## 
  ## Meta parameters of the GA are specified 
  ## in _conf_ parameter in new or DefaultConf constant defined in sub-classes
  ## as follow:
  ##     <Conf> ::= { ...
  ##                  :population => Integer,
  ##                  :compareBy => <ComparisonMethod>
  ##                  :alternateConf => {
  ##                    :surviveRate => <Rate>,
  ##                    :
  ##                  ... }
  ##     <ParamName> ::=  a string of the name of a parameter.
  ##     <RandPolicy> ::= { :type => :uniform, :min => min, :max => max }
  ##                    | { :type => :gaussian, :ave => ave, :std => std }
  ##                    | { :type => :value, :value => value }
  ##                    | { :type => :list, :list => [value, value, ...] }
  ##
  ## === Usage
  ##  # create a FooConductor and run.
  ##  conductor = FooConductor.new() ;
  ##  conductor.run() ;
  ##  
  class ConductorSimpleGa < ConductorRandom
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default values of _conf_ in new method.
    ## It should be a Hash. It overrides Conductor::DefaultConf.
    ## See below for meaning of each key:
    ## - :scatterPolicy : define a policy to scatter parameter values.
    ##   See description of ItkOacis::ConductorRandom. 
    ##   (default: {})
    DefaultConf = {
      :scatterPolicy => {},
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## scatter policy definition.
    ## The name is specified in _conf_ in new method
    ## by key <tt>:scatterPolicy</tt>. 
    attr_reader :scatterPolicy ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to setup configulations.
    def setup()
      super() ;
      setupScatterPolicy(getConf(:scatterPolicy)) ;
    end

    #--------------------------------------------------------------
    #++
    ## to set scatter policy.
    ## _policyTable_:: a Hash from param. name to scatter policy.
    def setupScatterPolicy(_policyTable)
      @scatterPolicySpec = _policyTable ;
      @scatterPolicy = {} ;
      @scatterPolicySpec.each{|_name, _policyOriginal|
        _policy = _policyOriginal.dup() ;
        case(_policy[:type])
        when :uniform ;
          _policy[:value] = Stat::Uniform.new(_policy[:min], _policy[:max]) ;
        when :gaussian ;
          _policy[:value] = Stat::Gaussian.new(_policy[:ave], _policy[:std]) ;
        end
        @scatterPolicy[_name] = _policy ;
      }
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to setup ParamSet setting for new one.
    ## It generate a partial _paramSet hash according to
    ## a specified policy in scatterPolicy.
    ## The value specified in _seed_ override the policy.
    ## _varied_:: a paried information to generate ParamSet.
    ## *return*:: a Hash of a partial ParamSet setting.
    def setupNewParam(_varied)
      _param = {} ;
      @scatterPolicy.each{|_paramName, _policy|
        _param[_paramName] = ( _varied.key?(_paramName) ?
                                 _varied[_paramName] :
                                 getValueByPolicy(_policy) ) ;
      }
      return _param ;
    end

    #--------------------------------------------------------------
    #++
    ## to generate a random value specifyed in _policy_.
    ## _policy_:: a Hash of overriding parameters. 
    ## *return*:: a random value.
    def getValueByPolicy(_policy)
      case(_policy[:type])
      when :uniform, :gaussian, :value ;
        return _policy[:value].value() ;
      when :list ;
        return _policy[:list].sample() ;
      else
        raise "Unknown policy type: " + _policy.inspect ;
      end
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
  class FooConductor < ItkOacis::ConductorRandom
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default configulation for initialization.
    DefaultConf = {
      :simulatorName => "foo00",
      :hostName => "localhost",
      :scatterPolicy => { "x" => { :type => :uniform,
                                   :min => -1.0, :max => 1.0 },
                          "y" => { :type => :gaussian,
                                   :ave => 10.0, :std => 1.0 },
                          "z" => { :type => :list,
                                   :list => [0.0, 1.0, 2.0, 3.0] } }
    } ;
    
    #--------------------------------------------------------------
    #++
    ## override cycleCheck().
    def cycleBody()
      super() ;
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
    ## test ConductorRandom.
    def test_a()
      _conductor = FooConductor.new() ;
      pp [:test_a, _conductor] ;
      _conductor.run() ;
    end

  end # class ItkTest

  ##########################################
  ##########################################
  ##########################################
  
  ItkTest.run($*) ;
  
end # if($0 == __FILE__)
