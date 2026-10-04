# 🖥️ MyFuture Admin Dashboard

The **MyFuture Admin Dashboard** is a web-based administration platform developed alongside the MyFuture mobile application.

It allows administrators to manage the educational information and scholarship content displayed in the MyFuture application through a centralized dashboard.

The dashboard shares the same **Firebase backend** as the MyFuture mobile application, allowing updates made by administrators to be reflected in the application.

---

## ✨ Features

### 🔐 Admin Authentication

The dashboard provides a dedicated login system for administrators.

* Admin login
* Firebase Authentication
* Restricted access to administrative features

### 📊 Dashboard Overview

The dashboard provides an overview of the application's data and usage.

Administrators can view information such as:

* Number of registered users
* Scholarship information
* Education pathway information
* Application usage statistics

### 🎓 Scholarship Management

Administrators can manage scholarship information displayed to students.

This includes:

* Add new scholarships
* Edit existing scholarship information
* Remove scholarships
* Update eligibility requirements
* Update scholarship descriptions
* Set application closing dates
* Monitor scholarship status

Scholarships can be displayed as **OPEN** or **CLOSED** based on their application closing dates.

### 🧭 Education Pathway Management

Administrators can manage information about education pathways available to students after SPM.

The dashboard allows administrators to:

* Add education pathways
* Edit pathway information
* Update pathway descriptions
* Remove outdated information

### 👥 User & Usage Monitoring

The dashboard provides administrators with an overview of application usage.

This allows administrators to understand how the MyFuture application is being used and monitor the number of registered users.

### ☁️ Firebase Integration

The admin dashboard uses Firebase as its backend and shares the same Firebase project with the MyFuture mobile application.

Firebase is used for:

* Authentication
* Cloud Firestore
* User data
* Scholarship data
* Education pathway data

Changes made through the dashboard are stored in Firestore and can subsequently be accessed by the MyFuture mobile application.

---

## 🛠️ Technologies Used

| Technology              | Purpose                   |
| ----------------------- | ------------------------- |
| Flutter                 | Web dashboard development |
| Dart                    | Programming language      |
| Firebase Authentication | Admin authentication      |
| Cloud Firestore         | NoSQL database            |
| Firebase                | Backend services          |

---

## 🔄 How It Works

```text
             ADMIN
               │
               ▼
       Admin Dashboard
               │
               ▼
        Firebase Backend
               │
        ┌──────┴──────┐
        ▼             ▼
   Firestore      Authentication
        │
        ▼
   MyFuture App
        │
        ▼
     Students
```

Administrators manage content through the dashboard, while students access the updated information through the MyFuture mobile application.

---

## 📱 Relationship with MyFuture

The Admin Dashboard was developed as a companion system to the **MyFuture mobile application**.

### MyFuture Mobile Application

Designed for students to:

* Explore education pathways
* Complete career and personality assessments
* Receive rule-based career recommendations
* Browse scholarships
* Manage their profile and SPM results

### MyFuture Admin Dashboard

Designed for administrators to:

* Manage scholarship information
* Manage education pathway information
* Monitor application usage
* Maintain the content displayed in the mobile application

Both systems are connected through the same Firebase backend.

---

## 👩🏻‍💻 My Role

I was responsible for developing the admin dashboard as part of the MyFuture project.

My work included:

* Designing the dashboard interface
* Developing the dashboard using Flutter
* Implementing Firebase Authentication
* Connecting the dashboard to Cloud Firestore
* Developing scholarship management functionality
* Developing education pathway management functionality
* Implementing application usage statistics
* Testing the dashboard and its connection with the mobile application

---

## 📚 What I Learned

Through developing the admin dashboard, I gained practical experience in:

* Web application development using Flutter
* Firebase integration
* NoSQL database management
* CRUD operations
* Authentication
* Designing admin interfaces
* Connecting multiple applications to a shared backend
* Managing data that needs to be consumed by another application

---


## 🚀 Future Improvements

Potential improvements include:

* More detailed analytics
* Improved user activity tracking
* Role-based administrator access
* Search and filtering for larger datasets
* More advanced dashboard visualizations
* Automated notifications for scholarship deadlines

---

## 🔗 Related Project

**MyFuture — Educational Path & Scholarship Planner**

The student-facing mobile application that uses the information managed through this dashboard.

---

## 🏆 Project Recognition

MyFuture was awarded **Best of the Best** at faculty level for my Final Year Project.

The project gave me the opportunity to develop both a student-facing mobile application and an administrative web dashboard connected through a shared Firebase backend.

