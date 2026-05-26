<div align="center">

# 🦖 T-Racks
**Facial Recognition Biometric Attendance System**

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](#)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](#)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](#)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](#)

*A Software Development 1 Project*

</div>

---

## 📖 About The Project

Traditional attendance methods—such as manual roll calls, paper-based logs, and swipe cards—are often inefficient, prone to errors, and vulnerable to fraudulent practices like buddy punching and proxy attendance

**T-Racks** is an intelligent, mobile-first Information System designed to solve these issues by integrating artificial intelligence. By utilizing advanced facial and voice recognition technologies, T-Racks provides a secure, accurate, and automated alternative to traditional attendance tracking. This system reduces human intervention, streamlines classroom management, and establishes a transparent, trustworthy attendance process for instructors and administrators

## ✨ Core Features

* [cite_start]📸 **Biometric Authentication:** Secure user verification utilizing advanced facial and voice recognition algorithms. Includes fallback mechanisms for manual check-ins if biometric matching fails.
* [cite_start]🏫 **Classroom Management:** Comprehensive dashboards allowing administrators and instructors to organize virtual classrooms, assign schedules, and manage student enrollment.
* [cite_start]✅ **Automated Attendance Tracking:** Automatically records arrival times and marks users as "Present," "Absent," or "Late" upon successful identification[cite: 28, 29]. 
* [cite_start]📊 **Reporting & Logs:** Generate detailed attendance summaries and logs for individuals, specific classes, or whole departments. [Export data in standard formats like PDF or Excel[cite: 168].
* [cite_start]📴 **Offline Capability:** Core functionalities are designed to work offline, with a provision for data synchronization once network access is restored.
* [cite_start]🔔 **Automated Alerts:** Built-in notification system to flag absences or irregular attendance to relevant stakeholders

## 🏗️ System Architecture

T-Racks is built with a modular architecture to ensure rapid, secure authentication
1.  **User Interface (UI):** Built for cross-platform mobile compatibility
2.  **Biometric Module:** Captures and processes facial and voice inputs
3.  **Authentication Module:** Verifies live inputs against stored biometric templates
4.  **Attendance Manager:** Logs the data into the system's database in real-time

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Before you begin, ensure you have the following installed:
* **Flutter SDK:** Install [Flutter](https://docs.flutter.dev/get-started/install) (ensure it's added to your PATH).
* **IDE:** Visual Studio Code (with Flutter/Dart extensions) or Android Studio.
* **Target Device:** An Android Emulator, iOS Simulator (macOS only), or a physical device connected via USB.

### Installation

**1. Clone the repository** Open your terminal and run:
```bash
git clone [https://github.com/Scorch879/t_racks_softdev_1.git](https://github.com/Scorch879/t_racks_softdev_1.git)
