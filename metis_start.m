%% METIS: A code framework for constrained mechanical systems
% author: Philipp Kinon
% date  : 02.12.2020
clearvars;
addpath(genpath(fileparts(which(mfilename))));

%% METIS initialise
% Load configuration parameters from file
CONFIG = metis_load('config_input');

% Define System from Class
system = Pendulum(CONFIG);

% Define Integrator from Class
integrator = Ggl_gen_alpha(CONFIG);

% Initialise integrator for current system
integrator = integrator.initialise(CONFIG,system);

% Intialise System for current integrator
system = system.initialise(CONFIG,integrator);

%% METIS solver
% Define Solver from class
solver = Newton(CONFIG);

% Solve my System with my Solver and my Integration scheme
system = solver.solve(system,integrator);

%% METIS postprocessing
% Define Postprocessing from class
postprocess = Postprocess();

% Compute various postprocessing quantities
system = postprocess.compute(system);

% Animation of trajectory
postprocess.animation(system,integrator,CONFIG);

% Time-evolution of postprocessing quantites as plots
postprocess.plot(CONFIG,system,integrator);