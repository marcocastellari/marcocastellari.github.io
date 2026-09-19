---
title: "STM32 Inertial Platform"
date: 2026-03-28
draft: false
description: "A compact 4-layer inertial measurement platform built around STM32 MCU, an IMU sensor, and a CAN transceiver — designed for real-time motion sensing on motorsport and industrial applications."
tags: ["STM32", "IMU", "CAN Bus", "PCB", "Firmware", "C++"]
showToc: true
cover:
    image: "pcb-3D.png"
    alt: "3D rendering of the STM32 inertial platform PCB"
    caption: "3D render of the 4-layer inertial platform board"
    relative: true
params:
    tech_stack: ["STM32F103", "IMU", "CAN Transceiver", "KiCad", "C++", "HAL / LL drivers"]
    status: "completed"
---

## Overview

This project is a compact **inertial measurement platform** designed to provide accurate 6-DoF motion data over a CAN bus. The board is built around the **STM32F103** microcontroller paired with an **IMU** (accelerometer + gyroscope) and a **CAN transceiver**, making it a self-contained node that can be dropped into any vehicle or industrial system that speaks CAN.

The primary use case is motorsport telemetry, but the architecture is generic enough for industrial automation and robotics applications.

## Tech Stack

- **MCU**: STM32F103 (ARM Cortex-M3)
- **IMU**: 6-axis inertial sensor (accelerometer + gyroscope)
- **Connectivity**: CAN transceiver (NXP)
- **PCB**: 4-layer stackup - signal/VCC plane/GND plane/signal
- **Firmware**: C++ with STM32 HAL/LL driver

## Features

- Real-time 6-DoF inertial data acquisition at configurable ODR
- CAN bus output with configurable node ID and message layout
- 4-layer PCB with dedicated power and ground planes for low-impedance distribution and EMI control
- Compact form factor suitable for tight enclosure mounting
- Onboard decoupling and power filtering for clean analog and digital supply rails
- 3D-rendered mechanical envelope for enclosure and bracket design validation

## PCB Stack-up & Layout Strategy

The board uses a **4-layer stackup** with the following layer assignment:

| Layer | Function |
|-------|----------|
| Top | Signal routing — MCU, IMU, CAN trx, connectors |
| Inner 1 | VCC power plane |
| Inner 2 | GND reference plane |
| Bottom | Signal routing — bypass caps, secondary passives |

This arrangement keeps the two signal layers tightly sandwiched between continuous reference planes, which minimises loop inductance for high-frequency return currents and provides a clean ground reference under the IMU - critical for keeping accelerometer noise floors low. The CAN transceiver has its own local decoupling and a dedicated trace pair routed as a controlled-impedance differential line to the edge connector.

## Challenges & Solutions

**Design approach**: The layout was a deliberate learning exercise - grounded in application notes and reference designs, then tested and corrected on real hardware rather than assumed correct on the first pass.

**IMU placement**: The IMU was placed near the board's geometric centre, away from the switching regulators and the CAN transceiver, to minimise noise coupling from other components and to keep the sensor axis aligned with the board's mechanical mounting reference.

**CAN bus termination**: Rather than relying on external termination, a solder-jumper selectable 120 Ω termination resistor was included on the board, making it easy to configure the node as a bus endpoint without external hardware changes.

**Resilient firmware update strategy**: A near-production device cannot rely on JTAG for firmware updates. A two-path flashing strategy - serial flashing for the bootloader and CAN bus updates for the application firmware - has been implemented and tested, giving a resilient way to update the board once it leaves the development bench.

## What I Learned

- The importance of inner plane continuity - any slot or void in the GND plane directly under a high-speed trace introduces impedance discontinuities that are hard to fix post-fabrication.
- Validating the IMU orientation in firmware against the physical board axes early avoids sign-error surprises in the data pipeline.
- Test points, a visible power LED and accessible debug pads cost almost nothing at layout time and save hours the first time the board doesn't work.

## Resources
- [4 layer PCB stackup]( https://resources.altium.com/p/4-layer-pcb-stackup)