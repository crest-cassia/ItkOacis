#! /usr/bin/env ../../oacis/bin/oacis_ruby
# coding: utf-8
## -*- mode: ruby -*-
## = Itk Oacis Host stub
## Author:: Itsuki Noda
## Version:: 0.0 2020/02/14 I.Noda
##
## === History
## * [2020/02/14]: Create This File.
## == Usage
## * ...

def $LOAD_PATH.addIfNeed(path)
  self.unshift(path) if(!self.include?(path)) ;
end

$LOAD_PATH.addIfNeed(File.dirname(__FILE__));
$LOAD_PATH.addIfNeed(File.dirname(__FILE__) + "/itkLib");

require "WithConfParam.rb" ;

#--======================================================================
#++
## package module of Interactive Toolkit for Oacis.
module ItkOacis
  #--======================================================================
  #++
  ## to provide interface for Host and HostGroup in Oacis from ItkOacis
  class HostStub < WithConfParam
    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get Host name list.
    ## *return*:: an Array of names of registered Host in String.
    def self.getHostNameList()
      return ::Host.asc().all.as_json.map{|_host| _host["name"]} ;
    end
    
    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get Host entry by name.
    ## _name_:: the name of Host in String.
    ## _safeP_:: If false, it raises an exception when the named Host
    ##           does not found.  If true, it just return nil when not found.
    ## *return*:: a Host object.
    def self.getHostByName(_name, _safeP = false)
      if(_safeP) then
        begin
          return self.getHostByName(_name, false) ;
        rescue => _ex
          return nil ;
        end
      else
        return ::Host.find_by_name(_name) ;
      end
    end

    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get HostGroup name list.
    ## *return*:: an Array of names of registered HostGroup in String.
    def self.getHostGroupNameList()
      return ::HostGroup.asc().all.as_json.map{|_group| _group["name"]} ;
    end
    
    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get HostGroup entry by name.
    ## _name_:: the name of HostGroup in String.
    ## _safeP_:: If false, it raises an exception when the named HostGroup
    ##           does not found.  If true, it just return nil when not found.
    ## *return*:: a HostGroup object.
    def self.getHostGroupByName(_name, _safeP = false)
      if(_safeP) then
        begin
          return self.getHostGroupByName(_name, false) ;
        rescue => _ex
          return nil ;
        end
      else
        return ::HostGroup.find_by_name(_name) ;
      end
    end

    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get Host list in HostGroup by name.
    ## _name_:: the name of HostGroup in String.
    ## _safeP_:: If false, it raises an exception when the named HostGroup
    ##           does not found.  If true, it just return nil when not found.
    ## *return*:: an Array of Host object.
    def self.getHostListInGroup(_name, _safeP = false)
      _group = self.getHostGroupByName(_name, _safeP) ;
      if(_group) then
        return _group.host_ids.map{|_objId|
          ::Host.where(id: _objId.to_s).first ;
        }
      else
        return nil ;
      end
    end

    #--------------------------------------------------------------
    #++
    ## to get Host name list in HostGroup by name.
    ## _name_:: the name of HostGroup in String.
    ## _safeP_:: If false, it raises an exception when the named HostGroup
    ##           does not found.  If true, it just return nil when not found.
    ## *return*:: an Array of Host object.
    def self.getHostNameListInGroup(_name, _safeP = false)
      _hostList = self.getHostListInGroup(_name, _safeP) ;
      if(_hostList) then
        return _hostList.map{|_host| _host.name} ;
      else
        return nil ;
      end
    end

    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get Host and HostGroup name list.
    ## *return*:: an Array of names of registered Host and HostGroup in String.
    def self.getHostAndGroupNameList()
      _list = [] ;
      
      _list.concat(self.getHostNameList()) ;
      _list.concat(self.getHostGroupNameList()) ;
      
      return _list ;
    end
    
    #--============================================================
    #--------------------------------------------------------------
    #++
    ## to get Host or HostGroup entry by name.
    ## _name_:: the name of Host or HostGroup in String.
    ## _safeP_:: If false, it raises an exception when the named one
    ##           does not found.  If true, it just return nil when not found.
    ## *return*:: a Host or HostGroup object.
    def self.getHostAndGroupByName(_name, _safeP = false)
      if(_safeP) then
        begin
          return self.getHostAndGroupByName(_name, false) ;
        rescue => _ex
          return nil ;
        end
      else
        return (self.getHostByName(_name, true) ||
                self.getHostGroupByName(_name, false)) ;
      end
    end
    
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default configulation.
    DefaultConf = {
      :hostParam => nil,
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## the name of Host or HostGroup.
    attr_reader :name ;
    ## the entity of Host or HostGroup in Oacis.
    attr_reader :entity ;
    ## the entity of Host or HostGroup in Oacis.
    attr_reader :hostParam ;

    #--------------------------------------------------------------
    #++
    ## initialize.
    ## _name_:: name of Simulator in Oacis.
    def initialize(_name = nil, _conf = {})
      super(_conf)
      setEntityByName(_name) if(_name) ;
    end

    #--------------------------------------------------------------
    #++
    ## to get Simulator entity from Oacis.
    ## _name_:: name of Simulator.
    ## _safeP_:: If false, it raises an exception when the named one
    ##           does not found.  If true, it just return nil when not found.
    def setEntityByName(_name = @name, _safeP = false)
      @name = _name ;
      @entity = self.class.getHostAndGroupByName(_name, _safeP) ;
      @hostParam = getConf(:hostParam) ;
    end

    #--------------------------------------------------------------
    #++
    ## to check the entity is a Host.
    ## *return*:: true if the entity is a Host.
    def isHost()
      return @entity.is_a?(Host) ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to check the entity is a HostGroup.
    ## *return*:: true if the entity is a HostGroup.
    def isHostGroup()
      return @entity.is_a?(HostGroup) ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to retrieve Host's default parameters.
    ## *return*:: the default parameters if this is a Host.
    ##            If HostGroup, return nil ;
    def getHostParamTable()
      if(isHost()) then
        return @entity.default_host_parameters() ;
      elsif(isHostGroup()) then
        return nil ;
      else
        raise "@entity is not a Host or a HostGroup:" + @entity.inspect ;
      end
    end

    #--------------------------------------------------------------
    #++
    ## to call _block_ for each Host entity.
    ## If +self+ is Host, just call _block_ with the +entity+.
    ## If +self+ is HostGroup, call _block_ for each Host entity
    ## belong to the HostGroup.
    ## _block_:: a procedure to be executed with a Host entity argument.
    ## *return*:: the default parameters if this is a Host.
    ##            If HostGroup, return nil ;
    def eachHost(&_block)
      if(isHost()) then
        _block.call(@entity) ;
      elsif(isHostGroup()) then
        @entity.hosts.each{|_host|
          _block.call(_host) ;
        }
      else
        raise "The @entity is not Host or HostGroup:" + @entity.inspect ;
      end
    end

    #--------------------------------------------------------------
    #++
    ## to get the maximum number of jobs that can be executed in parallel.
    ## *return*:: the maximum number of parallel jobs.
    def maxJobN()
      _jobN = 0 ;
      eachHost(){|_host|
        _jobN += _host.max_num_jobs ;
      }
      return _jobN ;
    end

    #--------------------------------------------------------------
    #++
    ## to (find or) create runs with param.
    ## _paramSet_ :: a Ps or ParamSetStub.
    ## _nRun_ :: total number of runs.
    def createRuns(_paramSet, _nRun = 1)
      if(_paramSet.is_a?(ParamSetStub)) then
        createRuns(_paramSet.entity, _nRun) ;
      else
        if(isHost()) then
          _paramSet.find_or_create_runs_upto(_nRun,
                                             submitted_to: @entity,
                                             host_param: @hostParam) ;
        else
          _paramSet.find_or_create_runs_upto(_nRun,
                                             host_group: @entity) ;
        end
      end
    end
      
    #--////////////////////////////////////////////////////////////
    #--============================================================
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #--------------------------------------------------------------
  end # class HostStub
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
    ## host name list.
    def test_a()
      pp [:test_a, ItkOacis::HostStub.getHostNameList()] ;
    end

    #----------------------------------------------------
    #++
    ## host by name.
    def test_b()
      pp [:test_b, ItkOacis::HostStub.getHostByName("calamus")] ;
    end

    #----------------------------------------------------
    #++
    ## host group name list.
    def test_c()
      pp [:test_c, ItkOacis::HostStub.getHostGroupNameList()] ;
    end

    #----------------------------------------------------
    #++
    ## host group by name.
    def test_d()
      pp [:test_d, ItkOacis::HostStub.getHostGroupByName("local_group")] ;
    end

    #----------------------------------------------------
    #++
    ## host list in group.
    def test_e()
      pp [:test_e, ItkOacis::HostStub.getHostListInGroup("local_group")] ;
    end

    #----------------------------------------------------
    #++
    ## host name list group.
    def test_f()
      pp [:test_f, ItkOacis::HostStub.getHostNameListInGroup("local_group")] ;
    end

    #----------------------------------------------------
    #++
    ## host and group name.
    def test_g()
      pp [:test_g, ItkOacis::HostStub.getHostAndGroupNameList()] ;
    end

    #----------------------------------------------------
    #++
    ## new
    def test_h()
      pp [:test_h, ItkOacis::HostStub.new("localhost")] ;
    end

    #----------------------------------------------------
    #++
    ## new group
    def test_h2()
      _host = ItkOacis::HostStub.new("local_group") ;
      pp [:test_h2, _host] ;
      _host.eachHost(){|_h| pp _h} ;
    end


  end # class ItkTest

  ##########################################
  ##########################################
  ##########################################
  
  ItkTest.run($*) ;
  
end





