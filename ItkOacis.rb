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
  def symbolizeKeys(_value, _reverseP = false)
    if(_value.is_a?(Array)) then
      _value.each{|_val| symbolizeKeys(_val, _reverseP) ; } ;
    elsif(_value.is_a?(Hash)) then
      _value.keys().each{|_key|
        _val = _value[_key] ;
        _newKey = _key ;
        if(_reverseP) then
          _newKey = _key.to_s() if(_key.is_a?(Symbol)) ;
        else
          _newKey = _key.intern() if(_key.is_a?(String)) ;
        end
        symbolizeKeys(_val, _reverseP) ;
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

  require 'test/unit'

  #--============================================================
  #++
  # :nodoc:
  ## unit test for this file.
  class TC_Foo < Test::Unit::TestCase
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## desc. for TestData
    TestData = nil ;

    #----------------------------------------------------
    #++
    ## show separator and title of the test.
    def setup
#      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      name = "#{(@method_name||@__name__)}(#{self.class.name})" ;
      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    #----------------------------------------------------
    #++
    ## about test_a
    def test_a
      pp [:test_a] ;
      assert_equal("foo-",:foo.to_s) ;
    end

  end # class TC_Foo < Test::Unit::TestCase
end # if($0 == __FILE__)
