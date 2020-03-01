#! /usr/bin/env ruby
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


