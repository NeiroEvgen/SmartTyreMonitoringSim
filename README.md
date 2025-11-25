# Smart Tyre Monitoring Simulation (MATLAB)

![MATLAB](https://img.shields.io/badge/MATLAB-R2020a%2B-blue) ![License](https://img.shields.io/badge/License-MIT-green)

## Overview
This repository contains a physics-based simulation of a piezoelectric tyre monitoring system. The project demonstrates a method for indirect estimation of the tyre contact patch length and pressure distribution using **Frequency Division Multiplexing (FDM)**.

The simulation models the interaction between embedded piezoelectric sensors and the road surface under dynamic conditions, including variable RPM, camber angles, and structural impacts.

## Demo


https://github.com/user-attachments/assets/06243425-ddec-4700-9413-17723e9da9ab


*Figure 1: Real-time telemetry dashboard showing raw signal (top), spectrogram analysis (middle), and load distribution profile (bottom).*

## Technical Implementation

### 1. Physics Model
The simulation generates synthetic sensor data based on a non-linear tyre model:
* **Sensor Array:** Virtual piezoelectric elements positioned laterally across the tyre carcass.
* **Load Distribution:** Modeled as a Gaussian function, modified dynamically by the camber angle ( $\gamma$ ) and vertical load.
* **Centrifugal Stiffening:** Impact duration and amplitude are modulated by angular velocity ($\omega$) to simulate high-speed stiffening.

### 2. Signal Processing Pipeline
The system avoids complex wiring by simulating a single-wire transmission using FDM:
* **Modulation:** Each sensor zone modulates a specific carrier frequency ($f_c$) ranging from 25 kHz to 95 kHz.
* **Transmission:** Signals are summed into a single analog channel with added Gaussian white noise to simulate real-world interference.
* **Decoding:**
    * **FFT (Fast Fourier Transform):** Converts the time-domain signal into the frequency domain.
    * **Bandpass Filtering:** Isolates carrier frequencies.
    * **Envelope Detection:** Reconstructs the pressure profile for each zone.

## Features
* **Scalable Resolution:** Adjustable sensor count (3 to 20 zones) for R&D analysis.
* **Dual Visualization:** Switchable view between Frequency Domain (Spectrogram) and Spatial Domain (Heatmap).
* **Fault Injection:** Simulation of edge cases:
    * Kerb Strikes (High-amplitude edge impact).
    * Debris Impact (Broadband impulse response).
    * Wheel Lock-up (Signal loss and friction vibration).

## Getting Started

### Prerequisites
* MATLAB R2020a or newer.
* Signal Processing Toolbox (recommended but not strictly required for basic run).
