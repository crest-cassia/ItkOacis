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

require 'Conductor.rb' ;

#--======================================================================
module ItkOacis
  #--======================================================================
  #++
  ## Conductor that manages to create new ParamSetStub for random-search.
  ## A policy to scatter ParamSets can be specified
  ## in _conf_ parameter in new or DefaultConf constant defined in sub-classes.
  ## (See DefaultConf for the syntax of the specification.)
  ## === Usage
  ##  ## add path for "Conductor.rb" to $LOAD_PATH.
  ##  require 'ConductorRandom.rb' ;
  ##  
  ##  class FooConductor < ItkOacis::ConductorRandom
  ##    ## override DefaultConf.
  ##    DefaultConf = {
  ##      :simulatorName => "foo00",
  ##      :hostName => "localhost",
  ##      :scatterPolicy => { "x" => { :type => :uniform,
  ##                                   :min => -1.0, :max => 1.0 },
  ##                          "y" => { :type => :gaussian,
  ##                                   :ave => 10.0, :std => 1.0 },
  ##                          "z" => { :type => :list,
  ##                                   :list => [0.0, 1.0, 2.0, 3.0] } }
  ##    } ;
  ##    
  ##  end
  ## 
  ##  # create a FooConductor and run.
  ##  conductor = FooConductor.new() ;
  ##  conductor.run() ;
  ##  
  class ConductorRandom < Conductor
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default values of _conf_ in new method.
    ## It should be a Hash. It overrides Conductor::DefaultConf.
    ## See below for meaning of each key:
    ## (See also {ItkOacis::Conductor::DefaultConf}[Conductor.html#DefaultConf])
    ## - :scatterPolicy : define a policy to scatter parameter values.
    ##   (default: {})
    ##   Detailed syntax of the specification is as follows:
    ##     <Conf> ::= { ...
    ##                  :scatterPolicy => { <ParamName> => <RandPolicy>,
    ##                                      <ParamName> => <RandPolicy>,
    ##                                      ... },
    ##                  ... }
    ##     <ParamName> ::=  a string of the name of a parameter.
    ##     <RandPolicy> ::= { :type => :uniform, :min => min, :max => max }
    ##                    | { :type => :gaussian, :ave => ave, :std => std }
    ##                    | { :type => :value, :value => value }
    ##                    | { :type => :list, :list => [value, value, ...] }
    ##
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
      @scatterPolicy = convertScatterPolicy(_policyTable) ;
    end
      
    #--------------------------------------------------------------
    #++
    ## to convert scatter policy from _conf_ definition to random generator.
    ## _policyTable_:: a Hash from param. name to scatter policy.
      
    def convertScatterPolicy(_policyTable)
      _scatterPolicy = {} ;
      _policyTable.each{|_name, _policyOriginal|
        _policy = _policyOriginal.dup() ;
        case(_policy[:type])
        when :uniform ;
          _policy[:value] = Stat::Uniform.new(_policy[:min], _policy[:max]) ;
        when :gaussian ;
          _policy[:value] = Stat::Gaussian.new(_policy[:ave], _policy[:std]) ;
        end
        _scatterPolicy[_name] = _policy ;
      }
      return _scatterPolicy ;
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

  require "ItkOacis.rb" ;

  #--============================================================
  #++
  # :nodoc: all
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
