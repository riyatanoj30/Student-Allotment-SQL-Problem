# Open Elective Allocation System – MySQL Complete Solution

## 📌 Project Overview

This project provides a comprehensive **MySQL-based solution** for automating the allocation of open elective subjects to students based on their preferences and academic performance. It covers the complete backend logic using **SQL schema design, views, stored procedures**, and **data validation queries**.

---

## 📂 Contents

- ✅ Database Schema Creation
- 📋 Sample Data Insertion
- 🔍 Views for Analysis
- ⚙️ Stored Procedure for Allocation Logic
- 📈 Analytical & Verification Queries
- 🧠 Performance Optimization
- ✅ Data Validation Checks

---

## 🔧 Setup Instructions

1. **Create Database and Tables**
   - Run the SQL script to create the `OpenElectiveSystem` database and all required tables.

2. **Insert Sample Data**
   - Populate the tables with sample students, subjects, and preferences.

3. **Create Views**
   - Analytical views like `StudentPreferenceView` and `AvailableSubjects` are created for easier querying.

4. **Execute Allocation Logic**
   - Call the stored procedure `AllocateSubjects()` to perform the subject allocation based on GPA and preferences.

---

## 🗃️ Tables Overview

| Table Name          | Description |
|---------------------|-------------|
| `StudentDetails`     | Stores student personal details and GPA. |
| `SubjectDetails`     | Contains subject information including max and remaining seats. |
| `StudentPreference`  | Student-submitted subject preferences (1 to 5). |
| `Allotments`         | Final allocation results. |
| `UnallottedStudents` | Records students who could not be allotted any subject. |

---

## 🔎 Key Features

- ✅ **Preference-Based Allocation:** Honors student preferences from 1 to 5.
- 📊 **GPA-Based Priority:** Higher GPA students are given preference during allocation.
- 💾 **Stored Procedure Logic:** Automates allocation in a procedural manner.
- 📉 **Unallotted Tracking:** Clearly tracks and logs unallotted students.
- 🔍 **Multiple Insights:** Includes analysis by branch, subject, preference, etc.

---

## 🧪 Analytical Queries

| Query | Purpose |
|-------|---------|
| View All Allocations | Displays student-subject mappings with preference info |
| Unallotted Students | Lists students who didn't get any subject |
| Subject-wise Summary | Seats utilization stats |
| Preference Analysis | Allocation based on preference number |
| Branch Summary | Branch-wise allocation performance |
| First Choice Check | Who got their top choice and who didn’t |

---

## 🚀 Stored Procedure Logic

The stored procedure `AllocateSubjects()`:
- Iterates students in descending GPA order
- Tries to allocate the highest available preferred subject
- Updates remaining seats
- Logs unallotted students with reason

---

## ⚡ Performance Enhancements

Indexes used:
- GPA-based sorting
- Subject preference order
- Allotment timestamps
- Remaining seats

---

## ✅ Data Validation

Includes SQL checks for:
- Students without 5 preferences
- Duplicate preference entries
- Allocation success rate

---

## 📌 Final Summary Query

Provides:
- Total students
- Total allocations
- Total unallotted
- Allocation percentage

---

## 📚 Technologies Used

- **MySQL**
- **SQL Views & Indexes**
- **Stored Procedures**
- **Data Validation & Optimization**

---

## 🧠 Ideal Use Cases

- University subject allocation systems
- Preference-based resource allocation
- GPA-based seat distribution logic

---

## 👨‍💻 Author

Developed as a backend SQL solution for academic allocation systems. Customizable for different institutions and scalable to large datasets.

---

