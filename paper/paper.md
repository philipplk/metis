---
title: "Metis: Matlab-based simulation of dynamical systems"
tags:
  - Matlab
  - mechanics
  - dynamics
  - numerical methods
authors:
  - name: Philipp Lothar Kinon^[corresponding author]
    orcid: 0000-0002-4128-5124
    affiliation: "1"
  - name: Julian Karl Bauer
    orcid: 0000-0002-4931-5869
    affiliation: "2" # (Multiple affiliations must be quoted)
  - name: José Luis Muñoz Reyes
    orcid: XXX
    affiliation: "1"
  - name: Peter Betsch
    orcid: 0000-0002-0596-2503
    affiliation: "1"
affiliations:
  - name: Institute of Mechanics, Karlsruhe Institute of Technology (KIT), Karlsruhe, Germany
    index: 1
  - name: Chair for Continuum Mechanics, Institute of Engineering Mechanics, Karlsruhe Institute of Technology (KIT), Karlsruhe, Germany
    index: 2
date: 28 August 2023
bibliography: paper.bib
---

# Summary

The Matlab code framework `metis` is ...

Structure of the summary:
- High-level functionality
  - Setting the scene: Mechanics and integration
    - Mechanical system
    - Differential equations
    - Initial-boundary-value-problem
    - Numerical solution based on discretization  
- Purpose of the software for a diverse, non-specialist audience.  
  - (Do not yet talk solely about content (integrators), but why you intent to distribute metis)
  - Support papers
  - Increase reproducibility
  - Basis for object oriented integration code in cooperations and teaching
  - Lower the barrier for students to contribute in the fields of ...
  - Share research view on ...
  - Close gap on state-of-the-art structure-preserving ....
- Decision for Matlab
  - Pros and cons
  - Alternatives


# Statement of need

- General introduction
- Classification of numerical time integrators:
  - *Geometric* or *structure-preserving* integration [@hairer_geometric_2006].
  - *Energy-momentum* (EM) methods using *discrete gradients* (see, e.g. [@gonzalez_time_1996]) or variational integrators [@lew2016brief], [@marsden_discrete_2001], which have been extended to DAEs in [@leyendecker_variational_2008].
- List alternative packages and highlight what they lack, i.e., which gap is closed by metis



## Applicability

- System classification:
  - Hamiltonian dynamics with or without constraints [@leimkuhler_simulating_2005], also systems governed by differential-algebraic equations (DAEs) [@kunkel_differential-algebraic_2006] are feasible.
  - Rigid body dynamics in terms of *directors* [@betsch2001constrained].
  - Simulation of *port-Hamiltonian* systems [@duindam_modeling_2009].


## Code structure

## Motivation by example

- Show major workflow.
  - See this image \autoref{fig:dummy_image}.
    ![ALT-text for dummy image: Random pixels \label{fig:dummy_image}](../logo.png){ width=80% }

## Usage so far

`metis` has been recently used in the authors works (among others [@kinon_ggl_2023] and [@kinon_structure_2023]), where numerical schemes based on a mixed extension due to Livens principle [@livens_hamiltons_1919] have been derived for systems with holonomic constraints.

# Acknowledgements

PLK and PB gratefully acknowledge financial support by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) – project numbers XX and YY.

# References