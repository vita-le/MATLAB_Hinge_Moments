# Aircraft Aileron Hinge Moment Estimation

## Overview

This repository contains the MATLAB framework developed during my Master's thesis for the estimation of aircraft aileron hinge moments.

The project combines semi-empirical estimation methods based on Roskam's methodology with aerodynamic computations performed using the Tornado Vortex Lattice Method (VLM).

The repository includes two main code versions:

- **Thesis Version:** the baseline implementation developed as part of the Master's thesis.
- **Supersonic Extension:** an updated implementation introducing an additional correction to extend the methodology towards supersonic flight conditions.

## Repository Structure

```text
.
├── MAIN_SCRIPT_LOOP.m
├── Functions/
├── Inputs/
├── Roskam_Models/
├── CPACS_in/
├── TORNADO/
├── VALIDATION/
└── Supersonic_Correction/
```

### Thesis Version – Baseline

The main implementation is located in the repository root.

It includes:

- `MAIN_SCRIPT_LOOP.m`: main execution script.
- `Functions/`: MATLAB functions for geometry, flight conditions and hinge moment calculations.
- `Inputs/`: configuration and input parameters.
- `Roskam_Models/`: semi-empirical models and correction functions based on Roskam's methodology.
- `CPACS_in/`: aircraft geometry input files and CPACS-related utilities.
- `TORNADO/`: aerodynamic solver and supporting routines.
- `VALIDATION/`: scripts and datasets used for comparison and validation against reference data.

### Supersonic Extension – Updated Version

The `Supersonic_Correction/` directory contains the updated implementation.

It preserves the general structure of the baseline framework while introducing an additional correction intended to extend the hinge moment estimation methodology to supersonic flight conditions.

This version represents a further development of the original thesis work.

## Methodology

The framework combines two complementary approaches:

- **Semi-empirical approach:** estimation of hinge moment coefficients using Roskam-based models and associated correction functions.
- **Aerodynamic approach:** aerodynamic computations using Tornado VLM to support the estimation of control surface aerodynamic characteristics.

The resulting framework is intended to provide a computational approach for preliminary aileron hinge moment estimation across different flight conditions.

## Validation

The repository includes dedicated validation scripts and reference datasets.

The validation activities include comparisons with available NASA F/A-18 flight-test data, as well as comparisons between the semi-empirical and VLM-based approaches.

Relevant scripts and datasets are located in `VALIDATION/`.

## Requirements

- MATLAB
- Tornado VLM (included in the repository)

Additional configuration and input files are provided within the respective directories.

## Notes

The repository contains both the original thesis implementation and a subsequent development introducing a supersonic correction.

The two versions are kept separate to preserve the original implementation and allow comparison with the updated methodology.
