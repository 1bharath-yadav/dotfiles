#!/usr/bin/env bash

set -e

# ---------- TEMPLATE WRITER ----------
create_topic() {
    local subject="$1"
    local topic="$2"

    local file="${subject}/${topic}.md"

    mkdir -p "$subject"

    cat > "$file" <<EOF
---
subject: "${subject}"
topic: "${topic}"
tags: [anki,study]
---

TARGET DECK: ${subject}::${topic}

FILE TAGS: #${subject} #${topic}

EOF
}

# ---------- PHYSICS ONLY (NO SHARED MATH) ----------
declare -A SUBJECTS

# Mathematical Physics (only physics-specific leftovers)
SUBJECTS["Mathematical-Physics"]="\
Complex-Analysis \
Cauchy-Riemann \
Cauchy-Theorem \
Singularities \
Residue-Theorem \
Laplace-Transform \
Fourier-Analysis \
Tensors"

# Classical Mechanics
SUBJECTS["Classical-Mechanics"]="\
DAlemberts-Principle \
Euler-Lagrange-Equation \
Hamiltons-Principle \
Calculus-of-Variations \
Symmetry \
Conservation-Laws \
Central-Force-Motion \
Kepler-Problem \
Rutherford-Scattering \
Small-Oscillations \
Coupled-Oscillations \
Normal-Modes \
Rigid-Body-Dynamics \
Inertia-Tensor \
Orthogonal-Transformations \
Euler-Angles \
Symmetric-Top \
Hamiltonian \
Hamiltons-Equations \
Liouvilles-Theorem \
Canonical-Transformations \
Action-Angle-Variables \
Poisson-Brackets \
Hamilton-Jacobi \
Lorentz-Transformations \
Relativistic-Kinematics \
Mass-Energy-Equivalence"

# Electromagnetic Theory
SUBJECTS["Electromagnetic-Theory"]="\
Electrostatics \
Magnetostatics \
Boundary-Value-Problems \
Method-of-Images \
Separation-of-Variables \
Dielectrics \
Conductors \
Magnetic-Materials \
Multipole-Expansion \
Maxwells-Equations \
Scalar-Potential \
Vector-Potential \
Coulomb-Gauge \
Lorentz-Gauge \
EM-Waves-Free-Space \
EM-Waves-Media \
Reflection \
Transmission \
Polarization \
Poynting-Vector \
Poynting-Theorem \
EM-Energy-Momentum \
Radiation-Moving-Charge"

# Quantum Mechanics
SUBJECTS["Quantum-Mechanics"]="\
Postulates-of-QM \
Uncertainty-Principle \
Schrodinger-Equation \
Bra-Ket-Notation \
Hilbert-Space \
Step-Potential \
Finite-Well \
Quantum-Tunneling \
Particle-in-a-Box \
Harmonic-Oscillator \
Degeneracy \
Hydrogen-Atom \
Angular-Momentum \
Spin \
Addition-of-Angular-Momentum \
Variational-Method \
WKB-Approximation \
Perturbation-Theory \
Scattering-Theory \
Born-Approximation \
Quantum-Symmetry"

# Thermodynamics and Statistical Physics
SUBJECTS["Thermodynamics-Statistical-Physics"]="\
Laws-of-Thermodynamics \
Macrostates \
Microstates \
Phase-Space \
Ensembles \
Partition-Function \
Free-Energy \
Thermodynamic-Quantities \
Classical-Statistics \
Quantum-Statistics \
Degenerate-Fermi-Gas \
Blackbody-Radiation \
Plancks-Law \
Bose-Einstein-Condensation \
Phase-Transitions \
Phase-Equilibria \
Critical-Point"

# Atomic and Molecular Physics
SUBJECTS["Atomic-Molecular-Physics"]="\
Atomic-Spectra \
Many-Electron-Atoms \
Spin-Orbit-Interaction \
LS-Coupling \
jj-Coupling \
Fine-Structure \
Hyperfine-Structure \
Zeeman-Effect \
Stark-Effect \
Dipole-Transitions \
Selection-Rules \
Rotational-Spectra \
Vibrational-Spectra \
Electronic-Transitions \
Franck-Condon-Principle \
Raman-Effect \
EPR \
NMR \
ESR \
XRay-Spectra \
Einstein-Coefficients \
Population-Inversion \
Two-Level-System \
Three-Level-System \
Lasers"

# Solid State Physics
SUBJECTS["Solid-State-Physics"]="\
Crystallography \
Diffraction \
Bonding-in-Solids \
Lattice-Vibrations \
Thermal-Properties \
Free-Electron-Theory \
Band-Theory \
Nearly-Free-Electron \
Tight-Binding \
Metals \
Semiconductors \
Insulators \
Conductivity \
Mobility \
Effective-Mass \
Optical-Properties \
Kramers-Kronig \
Intraband-Transitions \
Interband-Transitions \
Dielectric-Properties \
Polarizability \
Ferroelectricity \
Diamagnetism \
Paramagnetism \
Ferromagnetism \
Antiferromagnetism \
Ferrimagnetism \
Domains \
Magnetic-Anisotropy \
Type-I-Superconductors \
Type-II-Superconductors \
Meissner-Effect \
London-Equation \
BCS-Theory \
Flux-Quantization"

# Electronics
SUBJECTS["Electronics"]="\
Intrinsic-Semiconductors \
Extrinsic-Semiconductors \
Electron-Hole-Statistics \
Metal-Semiconductor-Junction \
Ohmic-Contacts \
Rectifying-Contacts \
PN-Diodes \
BJT \
FET \
Negative-Feedback \
Positive-Feedback \
Oscillators \
Operational-Amplifiers \
Active-Filters \
Digital-Logic \
Combinational-Circuits \
Sequential-Circuits \
Flip-Flops \
Timers \
Counters \
Registers \
ADC \
DAC"

# Nuclear and Particle Physics
SUBJECTS["Nuclear-Particle-Physics"]="\
Nuclear-Radii \
Charge-Distribution \
Binding-Energy \
Nuclear-Magnetic-Moments \
Semi-Empirical-Mass-Formula \
Liquid-Drop-Model \
Shell-Model \
Nuclear-Force \
Two-Nucleon-Problem \
Alpha-Decay \
Beta-Decay \
EM-Transitions-in-Nuclei \
Nuclear-Reactions \
Conservation-Laws-Nuclear \
Fission \
Fusion \
Particle-Accelerators \
Detectors \
Photons \
Baryons \
Mesons \
Leptons \
Quark-Model \
Isospin \
Charge-Conjugation \
Parity \
Time-Reversal"

# ---------- CREATE ----------
for subject in "${!SUBJECTS[@]}"; do
    for topic in ${SUBJECTS[$subject]}; do
        create_topic "$subject" "$topic"
    done
done

echo "GATE Physics vault created."
