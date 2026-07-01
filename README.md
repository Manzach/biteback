# BiteBack: A Food Rescue App

BiteBack is a mobile food rescue application designed to reduce food waste and improve food accessibility within the university campus community, especially in IIUM.

The application connects **students, staff, food sellers, donors, and administrators** in one digital platform. Sellers can list near-expiry food at discounted prices, donors can publish food donation advertisements, and buyers can browse, order, and collect food using QR code verification.

## Project Overview

Food waste is a serious issue, while some students still face difficulty accessing affordable food. In many campus environments, food donation and food-sharing activities are still managed manually through word of mouth, social media posts, or informal announcements.

BiteBack solves this problem by providing a centralized mobile platform for:

- Near-expiry food sales
- Food donation advertisements
- Food bank announcements
- QR code-based pickup verification
- Admin monitoring

## Objectives

The main objectives of BiteBack are:

- To reduce food waste within the university campus
- To help sellers clear near-expiry food at discounted prices
- To help students and staff find affordable food
- To support food donation and food bank visibility
- To provide a secure pickup process using QR code verification
- To encourage sustainable food consumption

## Target Users

BiteBack has four main user roles:

### Buyer

Students and staff who want to buy discounted near-expiry food or view donation advertisements.

### Seller

Campus merchants or cooperatives that want to sell near-expiry food before it is wasted.

### Donor

Individuals or organizations that want to share food donation announcements or food bank updates.

### Administrator

Admin users who monitor users, food listings, donation advertisements, and system activity.

## Tech Stack

### Mobile Application

- Flutter
- Android platform

### Backend and Database

- Supabase
- PostgreSQL
- Supabase Authentication

### Other Features

- QR code generation
- Role-based access
- Real-time data update
- Admin monitoring dashboard

## Main Features

### User Registration and Login

Users can register and log in based on their role, such as buyer, seller, donor, or admin.

### Near-Expiry Food Listing

Sellers can add, update, and manage food listings. Each listing includes food name, description, price, expiry date, quantity, image, and availability status.

### Food Purchase

Buyers can browse available near-expiry food, place orders, and receive a QR code for pickup.

### QR Code Pickup Verification

Each successful order generates a QR code. This helps verify that the correct buyer collects the correct food item.

### Donation Advertisement

Donors can publish food donation advertisements or food bank announcements for buyers to view.

### Admin Monitoring

Admins can monitor users, food listings, orders, donations, and system activities.

## Database Design

The system uses a relational database structure with several main tables:

- User
- Food_Listing
- Order
- Donation
- Admin_Log
- Issue_Report

The database is designed to support traceability between users, food listings, orders, donations, and admin actions.

## System Modules

### Buyer Module

- Register and login
- View near-expiry food
- Purchase discounted food
- Receive QR code
- View donation advertisements

### Seller Module

- Register and login
- Add food listing
- Update food listing
- Manage food availability

### Donor Module

- Register and login
- Publish donation advertisement
- Update donation information

### Admin Module

- Admin login
- Monitor users
- Monitor food listings
- Monitor donation advertisements
- Manage inappropriate content

## Development Methodology

This project uses the Agile development methodology. Agile was chosen because it supports continuous improvement, user feedback, and iterative development.

The project development stages include:

1. Requirement gathering
2. Requirement analysis
3. System design
4. Database and UML design
5. Prototype design
6. Development
7. User testing
8. Module and system testing
9. User acceptance testing
10. Deployment
11. Documentation and presentation

## Project Scope

BiteBack focuses on a university campus environment. The system is mainly designed for IIUM students, staff, sellers, donors, and administrators.

The current version focuses on Android mobile usage and requires internet access for real-time updates and QR code verification.

## Expected Impact

BiteBack helps:

- Reduce edible food waste
- Support students with affordable food options
- Improve food donation visibility
- Encourage responsible consumption
- Support campus sustainability goals
- Improve coordination between sellers, donors, buyers, and administrators

## Future Enhancements

Possible future improvements include:

- iOS version
- Online payment gateway integration
- Push notification system
- Merchant inventory system integration
- Advanced reporting dashboard
- Food safety rating or review system
- Wider expansion beyond IIUM campus

## Project Status

This project was developed as a Final Year Project prototype for the Bachelor of Information Technology programme.

## Authors

- Aiman Zaqwan Bin Yahya
- Iskandar Zulqarnaen Bin Mohammed

## Supervisor

Ts. Abdul Rahman Bin Ahmad Dahlan

## Institution

Kulliyyah of Information and Communication Technology  
International Islamic University Malaysia  
Semester 2, 2025/2026
