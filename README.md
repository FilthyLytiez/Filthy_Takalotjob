🚚 TAKEALOT Delivery System
A professional package delivery system for FiveM servers featuring realistic gameplay mechanics, multiple delivery routes, and full framework compatibility.
Show Image
📋 Overview
Transform your FiveM server with an immersive delivery experience! Players can work as delivery drivers for TAKEALOT, South Africa's leading e-commerce platform. From collecting packages at the depot to delivering them across the map, this script provides hours of engaging roleplay opportunities.
✨ Features
🎯 Core Gameplay

5 Unique Delivery Routes with varying difficulty levels
Dynamic Package System with randomized quantities
Realistic NPC Interactions with South African dialogue
Progressive Payment System based on route difficulty
Cooldown System to prevent route farming
Vehicle Spawning with automatic fuel and key management

🎭 Immersive Experience

Interactive NPCs that face players during deliveries
Authentic South African Dialogue with local expressions
Professional UI with ox_lib context menus
Delivery Animations for package handover
Real-time Job Progress Tracking

🛠️ Technical Features

Framework Compatibility: QBCore & QBox
Target System Support: ox_target & qb-target
Fuel Script Integration: Multiple fuel systems supported
Vehicle Key Systems: Automatic key distribution
Performance Optimized: Clean, efficient code

🔧 Installation
Prerequisites

ox_lib (Required)
QBCore or QBox framework
ox_target or qb-target
One of the supported fuel/key scripts (optional)

📦 Installation Steps

Download all three components:
filthy_takealot (main script)
filthy_takealotreskin (depot MLO reskin)
fltakealotcaddy (delivery vehicle)

Extract to your resources folder:

 
filthy_takealot

filthy_takealotreskin

fltakealotcaddy

Add to your server.cfg:
cfg# TAKEALOT Delivery System
ensure filthy_takealotreskin

ensure fltakealotcaddy

ensure filthy_takealot

Configure the script:

Edit filthy_takealot/config.lua
Set your framework, target system, and scripts
Customize routes and payments as needed


Restart your server

⚙️ Configuration
Framework Setup
luaConfig.Framework = 'qbox' -- 'qbcore', 'qbox', or 'auto'
Config.Target = 'ox_target' -- 'ox_target' or 'qb-target'
Supported Scripts
🚗 Vehicle Key Systems

qb-vehiclekeys
wasabi_carlock
cd_garage

⛽ Fuel Systems

lc_fuel
ox_fuel
ps-fuel
cdn-fuel

🎯 Target Systems

ox_target (Recommended)
qb-target

Example Configuration
luaConfig.VehicleSettings = {
    FuelScript = 'lc_fuel',
    KeysScript = 'qb-vehiclekeys',
    SpawnInVehicle = false,
    DirtLevel = 0.0,
    EngineOn = true
}
🗺️ Delivery Routes
🟢 Easy Route - Paleto Bay Residential

Difficulty: Easy
Payment: $7,500 - $15,000
Time: 15-20 minutes
Deliveries: 5 locations around Paleto Bay

🔵 Medium Routes

Grapeseed Express: Rural farming community ($10,500 - $25,000)
Sandy Shores Circuit: Desert town deliveries ($15,500 - $35,000)

🔴 Hard Route - Highway Express

Difficulty: Hard
Payment: $35,500 - $60,000
Time: 35-45 minutes
Deliveries: 8 locations across the map

🟣 VIP Route - Premium Deliveries

Difficulty: VIP
Payment: $48,500 - $75,500
Time: 20-30 minutes
Deliveries: Exclusive high-end locations

🎮 How to Play

Visit the TAKEALOT Depot in Paleto Bay
Talk to Marcus (Depot Manager) to see available routes
Choose your route based on difficulty and payment
Collect packages from the depot warehouse
Load packages into your delivery vehicle
Follow GPS waypoints to delivery locations
Deliver packages to customers with authentic interactions
Return to depot to complete the job and receive payment

📍 Depot Location
TAKEALOT Paleto Depot

Location: Paleto Bay Industrial Area
Coordinates: -407.04, 6149.18, 31.68
Features: Custom MLO reskin with professional branding

🚐 Vehicle Information
TAKEALOT Delivery Van

Model: Custom VW Caddy with TAKEALOT livery
Features: Realistic branding and professional appearance
Spawning: Automatic with fuel and keys


