#! /usr/bin/env ../../oacis/bin/oacis_ruby
## -*- mode: ruby -*-
## = Itk Oacis ParamSet Factory (explore whole combination of lists).
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
  ## to manage to create new ParamSetStub by exploring whole combination.
  ## Lists of values for each parameter can be specified
  ## in _conf_ parameter in new as follow:
  ##     <Conf> ::= { ...
  ##                  :paramList => { <ParamName> => [value, value, ...],
  ##                                  <ParamName> => [value, value, ...],
  ##                                      ... },
  ##                  ... }
  ##     <ParamName> ::=  a string of the name of a parameter.
  ## 
  class ParamSetFactoryCombine < ParamSetFactory
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default configulation for initialization.
    DefaultConf = {
      :paramList => {},
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## a Hash of the parameter and the list of values.
    attr_reader :paramListTable ;
    ## the current index of parameter in the list.
    attr_reader :paramListIndex ;
    ## maximum number of combination.
    attr_reader :maxCombination ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## initialize an instance.
    ## _conf_:: configulation for the initialization.
    def initialize(_conductor, _conf = {})
      super(_conductor, _conf) ;
      setupParamListTable(getConf(:paramList)) ;
    end

    #--------------------------------------------------------------
    #++
    ## to set palameter list policy.
    ## _policyTable_:: a Hash from param. name to scatter policy.
    def setupParamListTable(_paramListTable)
      @paramListTable = _paramListTable ;
      @paramListIndex = [] ;
      @maxCombination = 1 ;
      @paramListTable.each{|_name, _paramList|
        @paramListIndex.push({:name => _name, :index => 0}) ;
        @maxCombination *= _paramList.size ;
      }
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to setup ParamSet setting for new one.
    ## It generates a partial _paramSet hash by picking up
    ## each combination of parameter values.
    ## _seed_:: a Hash of overriding parameters. 
    ## *return*:: a Hash of a partial ParamSet setting.
    def setupNewParam(_seed)
      _param = {} ;
      @paramListIndex.each{|_entry|
        _name = _entry[:name] ;
        _param[_name] = ( _seed.key?(_name) ?
                            _seed[_name] :
                            @paramListTable[_name][_entry[:index]] ) ;
      }
      shiftIndex(@paramListIndex,0) ;
      return _param ;
    end

    #--------------------------------------------------------------
    #++
    ## to shift indexes in _paramListIndex_.
    ## _paramListIndex_:: an Array of name-index tables.
    ## _k_:: to focus _k_-th entry.
    ## *return*:: true if the index rewinded.
    def shiftIndex(_paramListIndex, _k)
      if(_k >= _paramListIndex.size) then
        return true ;
      else
        _rewindP = shiftIndex(_paramListIndex, _k + 1) ;
        if(_rewindP) then
          _paramListIndex[_k][:index] += 1;
          _name = _paramListIndex[_k][:name] ;
          if(_paramListIndex[_k][:index] >= @paramListTable[_name].size) then
            _paramListIndex[_k][:index] = 0 ;
            return true ;
          else
            return false ;
          end
        else
          return false ;
        end
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
      :paramSetFactoryClass => ItkOacis::ParamSetFactoryCombine,
      :paramSetFactoryConf => {
        :paramList => { "x" => [0.1, 0.2, 0.3],
                        "y" => [4.0, 5.0, 6.0],
                        "z" => [0.7, 0.8, 0.9] },
      },
    } ;
    
    #----------------------------------------------------
    #++
    ## override runInit().
    def runInit()
      spawnParamSetN(@paramSetFactory.maxCombination, {}) ;
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
