#! /usr/bin/env ../../,Work/oacis_current/bin/oacis_ruby
#! /usr/bin/env ../../oacis/bin/oacis_ruby
## -*- mode: ruby -*-
## = Itk Oacis Conductor for Simple GA.
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
  ##
  ## === Usage
  ##
  ##  ## add path for "Conductor.rb" to $LOAD_PATH.
  ##  require 'ConductorGaSimple.rb' ;
  ##  
  ##  class FooConductor < ItkOacis::ConductorGaSimple
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
  ##      :ratioSurvive => 0.3,
  ##      :ratioCrossOver => 0.3,
  ##      :ratioMutate => 0.3,
  ##      :mutateRange => { "x" => { :type => :uniform,
  ##                                 :min => -0.1, :max => 0.1 },
  ##                        "y" => { :type => :gaussian,
  ##                                 :ave => 0.0, :std => 0.1 } },
  ##      :logLevel => :debug,
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
  class ConductorGaSimple < ConductorRandom
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## default values of _conf_ in new method.
    ## It should be a Hash. It overrides Conductor::DefaultConf.
    ## See below for meaning of each key:
    ## (See also {ItkOacis::ConductorRandom::DefaultConf}[ConductorRandom.html#DefaultConf])
    ## - :population : the population of ParamSetStub in one generation.
    ##   (default: 100)
    ## - :nofAlternation : the number of alternation in GA.
    ##   (default: 10)
    ## - :ratioSurvive : the ratio of survivers of ParamSetStub.
    ##   in the evaluation.
    ##   Should be in the range [0,1].
    ##   (default: 0.1)
    ## - :ratioMutate : the ratio to population to generate a new generation
    ##   by mutation.
    ##   Should be in the range [0,1].
    ##   (default: 0.3)
    ## - :ratioCrossOver : the ratio to population to generate a new generation
    ##   by cross over.
    ##   Should be in the range [0,1].
    ##   (default: 0.5)
    ##   The remain ratio (1 - surviveRatio - crossOverRatio - mutateRatio)
    ##   is used to generate in random way.
    ## - :compareBy : the procedure to compare ParamSetStub for the sorting.
    ##   The procedure should receive two ParamSetStub and return -1, 0, or 1.
    ##   If nil, use the default (compare? ()) method.
    ##   If a Proc, call it with two ParamSetStub.
    ##   (default: nil)
    ## - :scoreBy : the procedure to calculate score of ParamSetStub
    ##   for the sorting.
    ##   The procedure should receive one ParamSetStub and return a Float.
    ##   If nil, use the default (scoreOf ()) method.
    ##   If a Proc, call it with one ParamSetStub.
    ##   (default: nil)
    ## - :mutateBy : the procedure to generate
    ##   a new _varied_ (_paramSeed_) argument for newParamSet () by mutation.
    ##   If nil, use the default (newSeedByMutate ()) method.
    ##   If a Proc, call it with one ParamSetStub.
    ##   (default: nil)
    ## - :crossOverBy : the procedure to generate
    ##   a new _varied_ (_paramSeed_) argument for newParamSet () by cross over.
    ##   If nil, use the default (newSeedByCrossOver ()) method.
    ##   If a Proc, call it with one ParamSetStub.
    ##   (default: nil)
    ## - :mutateRange : the range information for the mutation.
    ##   It specify amont to modify each parameter used in newSeedByMutate ().
    ##   The format is the same as :scatterPolicy in ConductorRandom.
    ##   (default: {})
    ##
    ## See below for syntax of each key:
    ##     <Conf> ::= { ...
    ##                  :population => Integer,
    ##                  :nofAlternation => Integer,
    ##                  :ratioSurvive => <Ratio>,
    ##                  :ratioMutate => <Ratio>,
    ##                  :ratioCrossOver => <Ratio>,
    ##                  :compareBy => <MethodSpec>,
    ##                  :scoreBy => <MethodSpec>,
    ##                  :scoreBy => <MethodSpec>,
    ##                  :mutateBy => <MethodSpec>,
    ##                  :crossOverBy => <MethodSpec>,
    ##                  :mutateRange => <ScatterPolicy>,
    ##                  ... }
    ##     <Ratio> ::= a Float in the range [0,1].
    ##     <MethodSpec> ::= nil | a Proc.
    ##     <ScatterPolicy> ::= the same as :scatterPolicy for ConductorRandom.
    ##
    DefaultConf = {
      :population => 100,
      :nofAlternation => 10,
      :ratioSurvive => 0.1,
      :ratioCrossOver => 0.5,
      :ratioMutate => 0.3,
      :compareBy => nil,
      :scoreBy => nil,
      :crossOverBy => nil,
      :mutateBy => nil,
      :murateRange => {},
      nil => nil } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## the population of ParamSetStub in one generation.
    ## It is specified in _conf_ in new method
    ## by key <tt>:population</tt>. 
    attr_reader :population ;

    ## the number of alternation in GA.
    ## It is specified in _conf_ in new method
    ## by key <tt>:nofAlternation</tt>. 
    attr_reader :nofAlternation ;
    
    ## the ratio of survivers of ParamSetStub.
    ## It is specified in _conf_ in new method
    ## by key <tt>:ratioSurvive</tt>. 
    attr_reader :ratioSurvive ;

    ## the ratio to population to generate a new generation by mutation.
    ## It is specified in _conf_ in new method
    ## by key <tt>:ratioMutate</tt>. 
    attr_reader :ratioMutate ;

    ## the ratio to population to generate a new generation by cross over.
    ## It is specified in _conf_ in new method
    ## by key <tt>:ratioCrossOver</tt>. 
    attr_reader :ratioCrossOver ;

    ## the procedure to compare ParamSetStub for the sorting.
    ## It is specified in _conf_ in new method
    ## by key <tt>:compareBy</tt>. 
    attr_reader :compareBy ;

    ## the procedure to cauculate ParamSetStub for the sorting.
    ## It is specified in _conf_ in new method
    ## by key <tt>:scoreBy</tt>. 
    attr_reader :scoreBy ;

    ## the procedure to generate a new _varied_ (_paramSeed_) argument
    ## for newParamSet () by mutation.
    ## It is specified in _conf_ in new method
    ## by key <tt>:mutateBy</tt>. 
    attr_reader :mutateBy ;

    ## the procedure to generate a new _varied_ (_paramSeed_) argument
    ## for newParamSet () by cross over.
    ## It is specified in _conf_ in new method
    ## by key <tt>:crossOverBy</tt>. 
    attr_reader :crossOverBy ;

    ## the range information to mutate.
    ## It is specified in _conf_ in new method
    ## by key <tt>:mutateRange</tt>. 
    attr_reader :mutateRange ;

    ## the counter of alternation of generations.
    attr_reader :alterCount ;

    ## a list of ParamSetStub in the current generation.
    attr_reader :generation ;
    
    ## a list of generations as a history.
    attr_reader :alterHistory ;

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to setup configulations.
    def setup()
      super() ;
      setupGaPolicy() ;
    end

    #--------------------------------------------------------------
    #++
    ## to set policies of genetic algorithm.
    def setupGaPolicy()
      @population = getConf(:population) ;
      @nofAlternation = getConf(:nofAlternation) ;
      
      @ratioSurvive = getConf(:ratioSurvive) ;
      @ratioCrossOver = getConf(:ratioCrossOver) ;
      @ratioMutate = getConf(:ratioMutate) ;
      
      @compareBy = prepareProc(getConf(:compareBy) || :compare?) ;
      @scoreBy = prepareProc(getConf(:scoreBy) || :scoreOf) ;

      @mutateBy = prepareProc(getConf(:mutateBy) || :newSeedByMutate) ;
      @crossOverBy = prepareProc(getConf(:crossOverBy) || :newSeedByCrossOver) ;

      @mutateRange = convertScatterPolicy(getConf(:mutateRange)) ;

      @alterCount = 0 ;
      @generation = [] ;
      @alterHistory = [] ;

    end

    #--------------------------------------------------------------
    #++
    ## to prepare procedure.
    ## _procSpec_ :: a Proc or a Symbol.
    ##               If a Symbol, it should be the name of an instance method.
    ## *return* :: a Proc instance.
    def prepareProc(_procSpec)
      if(_procSpec.is_a?(Symbol)) then
        return Proc.new(){|*_argv| self.send(_procSpec, *_argv)} ;
      elsif(_porcSpec.is_a?(Proc)) then
        return _procSpec ;
      else
        raise "illegal procedure specification: " + _procSpec.inspect ;
      end
    end
    

    #--------------------------------------------------------------
    #++
    ## to get the number of initial ParamSet.
    ## It just return @population.
    ## *return*:: the number of ParamSet.
    def getNofInitParamSet()
      return @population ;
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to check a generation is over and alternate generation.
    ## It can be overrided by expanded classes.
    def cycleBody()
      super() ;
      if((nofRunning() == 0)) then
        # do alternation.
        loggingInfo(:alter, @alterCount) ;
        @alterCount += 1 ;
        @alterHistory.push(@generation) ;
        if(!terminate?()) then
          alternateGeneration() ;          
        end
      end
    end

    #--------------------------------------------------------------
    #++
    ## to check the trigger condition of alter procedure.
    ## *return*:: true when the conditions of alternation are satisfied.
    def triggerAlter?()
      return (nofRunning() == 0) ;
    end

    #--------------------------------------------------------------
    #++
    ## to check the alter count reaches @nofAlternation.
    ## *return*:: true when the conditions to terminate are satisfied.
    def terminate?()
      return (@alterCount >= @nofAlternation) ;
    end

    #--------------------------------------------------------------
    #++
    ## to spawn a ParamSetStub and push to a running list.
    ## _paramSeed_:: a Hash of paramter set. Can be partial.
    ## *return*:: a ParamSetStub.
    def spawnParamSet(_paramSeed = nil)
      _psStub = super(_paramSeed) ;
      @generation.push(_psStub) ;
      return _psStub ;
    end
    
    #--------------------------------------------------------------
    #++
    ## generate Json list of results.
    ## *return* :: an Array of Json Objects (Hash or Array).
    def prepareResultAsJsonList()
      _jsonList = [] ;
      @alterHistory.each{|_generation|
        _genJson = _generation.map{|_psStub| _psStub.toJson(:whole, :all) ; } ;
        _jsonList.push(_genJson) ;
      }
      return _jsonList ;
    end
    
    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to alternate generation
    ## It can be overrided by expanded classes.
    def alternateGeneration()
      # sort.
      @generation.sort!(&@compareBy) ;

      # switch to new generation
      @oldGeneration = @generation ;
      @generation = [] ;

      # survive
      alternateGeneration_Survive()
      # mutate
      alternateGeneration_Mutate()
      # cross-over
      alternateGeneration_CrossOver()
      # fill by random seed.
      fillRunningParamSetList() ;
      
      loggingInfo(:newGeneration, @alterCount) ;
    end
    
    #--------------------------------------------------------------
    #++
    ## to alternate generation (survive)
    def alternateGeneration_Survive()
      @nofSurviver = (@population * @ratioSurvive).ceil ;
      loggingDebug(:survive, @nofSurviver) ;
      (0...@nofSurviver).each{|_i| 
        _surviver = @oldGeneration[_i] ;
        loggingDebug(:survive1, :pickup, [_i]) ;
        @runningParamSetList.push(_surviver) ;
        @generation.push(_surviver) ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## to alternate generation (mutate)
    def alternateGeneration_Mutate()
      _nofMutation = (@population * @ratioMutate).ceil ;
      loggingDebug(:mutate, _nofMutation) ;
      (0..._nofMutation).each{|_i|
        _j = rand(@nofSurviver) ;
        loggingDebug(:murate1, :pickup, [_j]) ;
        _mutantSeed = @mutateBy.call(@oldGeneration[_j]) ;
        spawnParamSet(_mutantSeed) ;
      }
    end

    #--------------------------------------------------------------
    #++
    ## to alternate generation (cross over)
    def alternateGeneration_CrossOver()
      _nofCrossOver = (@population * @ratioCrossOver).ceil ;
      loggingDebug(:crossOver, _nofCrossOver) ;
      (0..._nofCrossOver).each{|_i|
        begin
          _j = rand(@nofSurviver) ;
          _k = rand(@nofSurviver) ;
        end while(_j == _k) ;
        loggingDebug(:crossOver1, :pickup, [_j,_k]) ;
        _childSeed = @crossOverBy.call(@oldGeneration[_j],
                                       @oldGeneration[_k]) ;
        spawnParamSet(_childSeed) ;
      }
    end

    #--////////////////////////////////////////////////////////////
    #--------------------------------------------------------------
    #++
    ## to compare two ParamSetStub.
    ## _psStub0_, _psStub1_ :: ParamSetStub to compare.
    ## *return* :: -1 if scoreOf(_psStub0) > scoreOf(_psStub1),
    ##             1 if scoreOf(_psStub0) < scoreOf(_psStub1), and
    ##             0 otherwise.
    def compare?(_psStub0, _psStub1)
      return (@scoreBy.call(_psStub1) <=> @scoreBy.call(_psStub0)) ;
    end

    #--------------------------------------------------------------
    #++
    ## to calculate scalar score of a given ParamSetStub.
    ## By default everyone is the same.
    def scoreOf(_psStub)
      return 0 ;
    end

    #--------------------------------------------------------------
    #++
    ## to generate a new seed of ParamSet in mutation.
    ## It can be overrided in sub-classes.
    def newSeedByMutate(_parent)
      _childSeed = {} ;
      _parentInput = _parent.getInputTable() ;
      _parentInput.each{|_key, _value|
        _policy = @mutateRange[_key] ;
        if(_policy.nil?) then
          _childSeed[_key] = _value ;
        elsif(_policy[:type] == :list || _policy[:type] == :value) then
          _childSeed[_key] = getValueByPolicy(_policy) ;
        else
          _childSeed[_key] = _value + getValueByPolicy(_policy) ;
        end
      }
      loggingDebug(:newSeedByMutate, _childSeed, :from, _parentInput) ;
      return _childSeed ;
    end

    #--------------------------------------------------------------
    #++
    ## to generate a new seed of ParamSet in cross-over.
    ## It can be overrided in sub-classes.
    def newSeedByCrossOver(_parent0, _parent1)
      _childSeed = {} ;
      _parentInput0 = _parent0.getInputTable()
      _parentInput1 = _parent1.getInputTable()
      _parentInput0.each{|_key, _value0|
        _value1 = _parentInput1[_key] ;
        _r = rand() ;
        if(_value0.is_a?(Float)) then
          _value = (_r * _value0) + ((1.0 - _r) * _value1) ;
        else
          _value = ((_r < 0.5) ? _value0 : _value1) ;
        end
        _childSeed[_key] = _value ;
      }
      loggingDebug( :newSeedByCrossOver, _childSeed,
                    :from, [_parentInput0, _parentInput1]) ;
      return _childSeed ;
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
  class FooConductor < ItkOacis::ConductorGaSimple
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
      :ratioSurvive => 0.3,
      :ratioCrossOver => 0.3,
      :ratioMutate => 0.3,
      :mutateRange => { "x" => { :type => :gaussian,
                                 :ave => 0.0, :std => 0.1 },
                        "y" => { :type => :gaussian,
                                 :ave => 0.0, :std => 0.1 },
                        "z" => { :type => :gaussian,
                                 :ave => 0.0, :std => 0.1 },
                      },
      :logLevel => :debug,
    } ;
    
    DefaultConf0 = {
      :simulatorName => "foo00",
      :hostName => "localhost",
      :scatterPolicy => { "x" => { :type => :uniform,
                                   :min => -1.0, :max => 1.0 },
                          "y" => { :type => :gaussian,
                                   :ave => 10.0, :std => 1.0 },
                          "z" => { :type => :list,
                                   :list => [0, 1, 2, 3] } },
#      :population => 50,
      :population => 10,      
      :nofAlternation => 10,
      :ratioSurvive => 0.3,
      :ratioCrossOver => 0.3,
      :ratioMutate => 0.3,
      :mutateRange => { "x" => { :type => :uniform,
                                 :min => -0.1, :max => 0.1 },
                        "y" => { :type => :gaussian,
                                 :ave => 0.0, :std => 0.1 } },
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
#      _conductor = FooConductor.new({:population => 100,
#                                     :nofAlternation => 100}) ;
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
