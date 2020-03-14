#  -*- coding: utf-8 -*-
=begin rdoc
:markup: markdown
:title: ItkOacis

(Top Page)[index.html]

# Itk's Oacis Utilities

* Author:: Itsuki Noda <noda50@gmail.com>
* Copyright:: Copyright (c) 2020 AIST & I.Noda
* License::   Distributes under the same terms as Oacis
* Version:: 0.0 2020/03/10 I.Noda

#### History
* [2020/03/10] Create This File.

## Overview

ItkOacis is a Ruby Module
that consists of classes to handle Oacis process
via Oacis Watcher facility.

ItkOacis::Conductor and its sub-classes are top-level class
for this facility.
An instance of these classes handles Simulator and Host
registered in a running Oacis by name,
and manages PSs (parameter sets).
The Conductor's main routeine is <tt>run()</tt>,
in which, after create new PSs, it submits the PSs
and watches job executions until termination condition satisfied.
Each method in the <tt>run()</tt> procedure can be overrided in
sub-classes.

ItkOacis::HostStub, ItkOacis::SimulatorStub, and
ItkOacis::ParamSetStub are wrapper classes to link to
Host, Simulator and PS (parameter set) classes in Oacis, respectively.
They also provide easy-to-use interfaces to handle instances/data
in the running Oacis.

For the detailed usage and functions, please see
each class secion.

## Sea Also
To see samples to use ItkOacis,
please check followings:

* class ItkOacis::Conductor
* class ItkOacis::ConductorCombine
* class ItkOacis::ConductorRandom

=end

module ItkOacis
end
