#! /usr/bin/env ../../,Work/oacis_current/bin/oacis_ruby
#! /usr/bin/env ../../oacis/bin/oacis_ruby
## -*- mode: ruby -*-
## = Itk Oacis Conductor for progressive GA using tounament 4.
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

require 'ConductorGaSimple.rb' ;

#--======================================================================
module ItkOacis
  #--======================================================================
  #++
  ## Conductor that manages to ParamSet
  ## according to a progressive GA (Genetic Algorithm) way.
  ##
  ## Compared with ConductorGaSimple, 
  ## ConductorGaProgressive alternate the next generation
  ## when a part of generation have done the calculation.
  ## In default, it use tounament4 () to alter the partial generation.
  ##
  ## In the tounament4 (), the trigger to start the next generation
  ## when 4 ParamSet are completed.
  ## The 4 ParamSet are sorted and generate the next 4 ParamSet and submit them.
  ## (See tournament4 () for more detail.)
  ## 
  ## === Usage
  ##
  ##  class FooConductor < ItkOacis::ConductorGaProgressive
  ##    ## default configulation for initialization.
  ##    DefaultConf = {
  ##      :simulatorName => "foo00",
  ##      :hostName => "localhost",
  ##      :scatterPolicy => { "x" => { :type => :uniform,
  ##                                   :min => -1.0, :max => 1.0 },
  ##                          "y" => { :type => :gaussian,
  ##                                   :ave => 10.0, :std => 1.0 },
  ##                          "z" => { :type => :list,
  ##                                   :list => [0, 1, 2, 3] } },
  ##      :population => 10,      
  ##      :nofAlternation => 10,
  ##      :mutateRange => { "x" => { :type => :uniform,
  ##                                 :min => -0.1, :max => 0.1 },
  ##                        "y" => { :type => :gaussian,
  ##                                 :ave => 0.0, :std => 0.1 } },
  ##      :logLevel => :info,
  ##    } ;
  ##    
  ##    ## to compare two ParamSetStub.
  ##    def scoreOf(_psStub)
  ##      _r = _psStub.getResultTable(:average) ;
  ##      _v = _r["u"] + _r["v"] + _r["w"] ; 
  ##      
  ##      return _v ;
  ##    end
  ##    
  ##  end 
  ##
  ##  # create a FooConductor and run.
  ##  conductor = FooConductor.new({:nofAlternation => 100}) ;
  ##  conductor.run() ;
  ##  
  class ConductorGaProgressive < ConductorGaSimple
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default values of _conf_ in new method.
    ## It should be a Hash. It overrides Conductor::DefaultConf.
    ## See below for meaning of each key:
    ## (See also {ItkOacis::ConductorGaSimple::DefaultConf}[ConductorGaSimple.html#DefaultConf])
    ## - :tounamentBy : the procedure to partial tournament.
    ##   If nil, use the default (tounament4 ()) method.
    ##   If a Proc, call it with 4 ParamSetStub.
    ##   (default: nil)
    ##
    ## See below for syntax of each key:
    ##     <Conf> ::= { ...
    ##                  :tounamentBy => <MethodSpec>,
    ##                  :nofPlayer => 4,
    ##                  ... }
    ##     <MethodSpec> ::= nil | a Proc.
    ##
    DefaultConf = {
      :tounamentBy => nil,
      :nofPlayer => 4,
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## the procedure to do tournament of ParamSetStub to create
    ## new generation.
    ## It is specified in _conf_ in new method
    ## by key <tt>:tournamentBy</tt>. 
    attr_reader :tournamentBy

    ## the number of tournament player.
    ## It is specified in _conf_ in new method
    ## by key <tt>:nofPlayer</tt>. 
    attr_reader :nofPlayer ;

    ## the number of tournament player.
    ## It is specified in _conf_ in new method
    ## by key <tt>:nofPlayer</tt>. 
    attr_reader :nofPlayer ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to set policies of genetic algorithm.
    def setupGaPolicy()
      super() ;

      @tournamentBy = prepareProc(getConf(:tournamentBy) || :tournament4) ;
      @nofPlayer = getConf(:nofPlayer) ;

      @pendingPool = {} ;
      @readyPool = [] ;
      @waitTable = {} ;

    end

    #--------------------------------------------------------------
    #++
    ## to get the number of initial ParamSet.
    ## It just return @population.
    ## *return*:: the number of ParamSet.
    def getNofInitParamSet()
      return @population - @pendingPool.size ;
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to check a generation is over and alternate generation.
    ## It can be overrided by expanded classes.
    def cycleBody()
      # update @readyPool, @pendingPool, and @waitTable.
      @doneInCycleList.each{|_psStub|
        @readyPool.push(_psStub) ;
        _waitStub = @waitTable[_psStub] ;
        if(_waitStub) then
          _pendingInfo = @pendingPool[_waitStub] ;
          _pendingInfo[:wait].delete(_psStub) ;
          _pendingInfo[:done].push(_psStub) ;
          @waitTable.delete(_psStub) ;
        end
      }

      # add unwaiting psStub in @pendingPool to @readyPool.
      @pendingPool.keys.each{|_waitStub|
        _pendingInfo = @pendingPool[_waitStub] ;
        if(_pendingInfo[:wait].empty?) then
          if((_pendingInfo[:done] & @readyPool).empty?) then
            @pendingPool.delete(_waitStub) ;
            @readyPool.push(_waitStub) ;
          end
        end
      }

      logging(:info, :cycle, @cycleCount,
              [getNofInitParamSet(), nofRunning(),
               nofDoneInCycle(), nofDone()].inspect,
              [@readyPool.size(), @pendingPool.size,
               @waitTable.size, @alterHistory.size].inspect) ;

      # do tournament if necessary.
      while(@readyPool.size >= @nofPlayer)
        _playerList = [] ;
        (0...@nofPlayer).each{|_i|
          _player = @readyPool.sample() ;
          _playerList.push(_player) ;
          @readyPool.delete(_player) ;
        }
        
        @alterCount += 1 ;
        @alterHistory.push(_playerList) ;
        
        if(@alterCount < @nofAlternation) then
          alternateByTournament(_playerList) ;
        end
      end
    end

    #--------------------------------------------------------------
    #++
    ## to check the alter count reaches @nofAlternation.
    ## *return*:: true when the conditions to terminate are satisfied.
    def terminate?()
      return ((@alterCount >= @nofAlternation) && (nofRunning() == 0)) ;
    end

    #--------------------------------------------------------------
    #++
    ## to finalize run process.
    def runFinal()
      @alterHistory.push(@readyPool) if(!@readyPool.empty?) ;
      super() ;
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to alternate generation by tournament.
    ## It can be overrided by expanded classes.
    def alternateByTournament(_playerList)
      _newList = @tournamentBy.call(_playerList) ;
      logging(:info, :alterByTournament, @alterCount) ;
      return _newList ;
    end

    #--------------------------------------------------------------
    #++
    ## to alternate generation by tournament4.
    ## It can be overrided by expanded classes.
    def tournament4(_playerList)
      # sort.
      _playerList.sort!(&@compareBy) ;

      # survive
      _surviver = _playerList.first() ;
      @runningParamSetList.push(_surviver) ;

      # mutate
      _mutantSeed = @mutateBy.call(_surviver) ;
      _mutant = spawnParamSet(_mutantSeed) ;

      # crossOver
      _second = _playerList[1] ;
      _crossSeed = @crossOverBy.call(_surviver, _second) ;
      _cross = spawnParamSet(_crossSeed) ;

      # rest, random.
      _restList = fillRunningParamSetList() ;

      # prepare pending and waiting.
      @runningParamSetList.delete(_surviver) ;
      _waitList = [_mutant, _cross] + _restList ;
      _pendingInfo = { :wait => _waitList, 
                       :done => [] } ;
      @pendingPool[_surviver] = _pendingInfo ;
      _waitList.each{|_wait|
        @waitTable[_wait] = _surviver ;
      }
      
    end
    
    #--////////////////////////////////////////////////////////////
    #--============================================================
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #--------------------------------------------------------------
  end # class ConductorGaProgressive
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
  class FooConductor < ItkOacis::ConductorGaProgressive
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default configulation for initialization.
    DefaultConf = {
      :simulatorName => "foo01",
      :hostName => "localhost",
      :scatterPolicy => { "x" => { :type => :uniform,
                                   :min => -1.0, :max => 1.0 },
                          "y" => { :type => :gaussian,
                                   :ave => 1.0, :std => 1.0 },
                          "z" => { :type => :uniform,
                                   :min => -0.01, :max => 0.01 },
                        },

#      :population => 50,
      :population => 10,      
      :nofAlternation => 10,
      :mutateRange => { "x" => { :type => :gaussian,
                                 :ave => 0.0, :std => 0.1 },
                        "y" => { :type => :gaussian,
                                 :ave => 0.0, :std => 0.1 },
                        "z" => { :type => :gaussian,
                                 :ave => 0.0, :std => 0.1 },
                      },
      :logLevel => :debug,
    } ;
    
    #--------------------------------------------------------------
    #++
    ## to compare two ParamSetStub.
    ## by default everyone is the same.
    def scoreOf(_psStub)
      _r = _psStub.getResultTable(:average) ;
      _v = _r["u"] + _r["v"] + _r["w"] ; 
      
      return _v ;
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
      _conductor = FooConductor.new({:population => 10,
                                     :nofAlternation => 10}) ;
      pp [:test_a, _conductor] ;
      _conductor.run() ;
    end

  end # class ItkTest

  ##########################################
  ##########################################
  ##########################################
  
  ItkTest.run($*) ;
  
end # if($0 == __FILE__)
