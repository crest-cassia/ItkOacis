#! /usr/bin/env ruby
## -*- mode: ruby -*-
## = ItkOacis utilities.
## Author:: Itsuki Noda
## Version:: 0.0 2020/02/15 I.Noda
##
## === History
## * [2020/03/15]: Create This File.
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

#--======================================================================
#++
#:doc:
## a collection of utilities for ItkOacis.
module ItkOacis
  extend ItkOacis ;
  #--============================================================
  #--------------------------------------------------------------
  #++
  ## convert String to Symbol of keys in Hash.
  ## _value_ :: any data includes Array and Hash.
  ## _reverseP_ :: if true, do reversed conversion.
  ## *return* :: converted value.
  def symbolizeKeys!(_value, _reverseP = false)
    if(_value.is_a?(Array)) then
      _value.each{|_val| symbolizeKeys!(_val, _reverseP) ; } ;
    elsif(_value.is_a?(Hash)) then
      _value.keys().each{|_key|
        _val = _value[_key] ;
        _newKey = _key ;
        if(_reverseP) then
          _newKey = _key.to_s() if(_key.is_a?(Symbol)) ;
        else
          _newKey = _key.intern() if(_key.is_a?(String)) ;
        end
        symbolizeKeys!(_val, _reverseP) ;
        if(_newKey != _key) then
          _value[_newKey] = _val ;
          _value.delete(_key) ;
        end
      }
    else
      # do nothing.
    end
    return _value ;
  end

  #--============================================================
  #--============================================================
  #++
  ## a module to extend ItkTest class.
  ## ==== Usage
  ##  require "ItkOacis.rb" ;
  ##
  ##  ## unit test for this file.
  ##  class ItkTest
  ##    extend ItkOacis::ItkTestModule ;
  ##
  ##    ## test data
  ##    TestData0 = { "foo" => 1,
  ##                  "bar" => { "x" => 1.0, "y" => 2.0, "z" => 3.0 },
  ##                  "baz" => [ { "a" => "abc", "b" => "def"}, 3, 4] };
  ##    TestData1 = { :foo => 1,
  ##                  :bar => { :x => 1.0, :y => 2.0, :z => 3.0 },
  ##                  :baz => [ { :a => "abc", :b => "def"}, 3, 4] };
  ##
  ##    ## 
  ##    def test_a
  ##      pp [:before, TestData0, TestData1] ;
  ##      ItkOacis::symbolizeKeys!(TestData0) ;
  ##      ItkOacis::symbolizeKeys!(TestData1, true) ;
  ##      pp [:after, TestData0, TestData1] ;
  ##    end
  ##
  ##  end
  ##
  ##  # call run with command line options.
  ##  ItkTest.run($*) ;
  ##
  module ItkTestModule
    #--========================================
    #------------------------------------------
    #++
    ## to do operations to be executed when _class_ extend this module.
    ## It sets constant Sigleton to be an instance of _class_.
    ## _class_:: a Class to extend this module.
    ## It overrids Module::extended.
    def self.extended(_class)
      _class.const_set(:Singleton, _class.new()) ;
    end

    #--==================================================
    #----------------------------------------------------
    #++
    ## list-up test methods.
    def listTestMethods()
      _r = [] ;
      self::Singleton.methods(true).each{|_method|
        _r.push(_method.to_s) if(_method.to_s =~ /^test_/) ;
      }
      return _r ;
    end

    #--==================================================
    #----------------------------------------------------
    #++
    ## run
    def run(_argv = [])
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
    def callTest(_method)
      if(self.listTestMethods.member?(_method)) then
        pp [:call, _method] ;
        self::Singleton.send(_method) ;
      else
        puts "Warning!!" ;
        pp [:no_test_method, _method] ;
      end
    end
    
  end
  
  #--////////////////////////////////////////////////////////////
  #--============================================================
  #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  #--------------------------------------------------------------
end # module ItkOacis

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  require "ItkOacis.rb" ;

  #--============================================================
  #++
  # :nodoc:
  ## unit test for this file.
  class ItkTest
    extend ItkOacis::ItkTestModule ;

    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## desc. for TestData
    TestData0 = { "foo" => 1,
                  "bar" => { "x" => 1.0, "y" => 2.0, "z" => 3.0 },
                  "baz" => [ { "a" => "abc", "b" => "def"}, 3, 4] };
    TestData1 = { :foo => 1,
                  :bar => { :x => 1.0, :y => 2.0, :z => 3.0 },
                  :baz => [ { :a => "abc", :b => "def"}, 3, 4] };

    #----------------------------------------------------
    #++
    ## about test_a
    def test_a
      pp [:before, TestData0, TestData1] ;
      ItkOacis::symbolizeKeys!(TestData0) ;
      ItkOacis::symbolizeKeys!(TestData1, true) ;
      pp [:after, TestData0, TestData1] ;
    end

  end # class ItkTest

  ##########################################
  ##########################################
  ##########################################
  
  ItkTest.run($*) ;
  
end # if($0 == __FILE__)
