#! /usr/bin/env ../../oacis/bin/oacis_ruby
## -*- mode: ruby -*-
## = Itk Oacis ParamSet Factory (Random Search)
## Author:: Itsuki Noda
## Version:: 0.0 2020/03/10 I.Noda
##
## === History
## * [2020/03/10]: Create This File.
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

require 'ParamSetFactory.rb' ;

#--======================================================================
module ItkOacis
  #--======================================================================
  #++
  ## to manage to create new ParamSetStub for random-search.
  ## A policy to scatter ParamSets can be specified
  ## in _conf_ parameter in new as follow:
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
  class ParamSetFactoryRandom < ParamSetFactory
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default configulation for initialization.
    DefaultConf = {
      :scatterPolicy => {},
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## default seed to create new ParamSet.
    attr_reader :scatterPolicy ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## initialize an instance.
    ## _conf_:: configulation for the initialization.
    def initialize(_conductor, _conf = {})
      super(_conductor, _conf) ;
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
    ## _seed_:: a Hash of overriding parameters. 
    ## *return*:: a Hash of a partial ParamSet setting.
    def setupNewParam(_seed)
      _param = {} ;
      @scatterPolicy.each{|_paramName, _policy|
        _param[_paramName] = ( _seed.key?(_paramName) ?
                                 _seed[_paramName] :
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
  end # class ParamSetFactoryRandom
end # module ItkOacis

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  require 'Conductor.rb' ;
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
      :paramSetFactoryClass => ItkOacis::ParamSetFactoryRandom,
      :paramSetFactoryConf => {
        :scatterPolicy => { "x" => { :type => :uniform,
                                     :min => -1.0, :max => 1.0 },
                            "y" => { :type => :gaussian,
                                     :ave => 10.0, :std => 1.0 },
                            "z" => { :type => :list,
                                     :list => [0.0, 1.0, 2.0, 3.0] } }
      },
    } ;
    
    #----------------------------------------------------
    #++
    ## override runInit().
    def runInit()
      fillRunningParamSetList() ;
    end
    
    #--------------------------------------------------------------
    #++
    ## override cycleCheck().
    def cycleBody()
      super() ;
      p [:cycle, @cycleCount, nRunning(), nDone()] ;
    end
    
    #----------------------------------------------------
    #++
    ## override terminated().
    def terminate?()
      return nRunning() == 0 ;
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
    ## my conductor.
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
