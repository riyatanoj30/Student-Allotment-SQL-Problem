-- ========================================
-- COMPLETE MYSQL SOLUTION FOR OPEN ELECTIVE ALLOCATION SYSTEM
-- ========================================

-- Step 1: Create Database
CREATE DATABASE IF NOT EXISTS OpenElectiveSystem;
USE OpenElectiveSystem;

-- Step 2: Create Tables
-- Table 1: Student Preferences
CREATE TABLE StudentPreference (
    StudentId VARCHAR(10) NOT NULL,
    SubjectId VARCHAR(10) NOT NULL,
    Preference INT NOT NULL CHECK (Preference BETWEEN 1 AND 5),
    PRIMARY KEY (StudentId, SubjectId),
    INDEX idx_student_pref (StudentId, Preference),
    INDEX idx_subject_pref (SubjectId, Preference)
);

-- Table 2: Subject Details
CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(100) NOT NULL,
    MaxSeats INT NOT NULL CHECK (MaxSeats > 0),
    RemainingSeats INT NOT NULL CHECK (RemainingSeats >= 0),
    INDEX idx_remaining_seats (RemainingSeats)
);

-- Table 3: Student Details
CREATE TABLE StudentDetails (
    StudentId VARCHAR(10) PRIMARY KEY,
    StudentName VARCHAR(100) NOT NULL,
    GPA DECIMAL(3,2) NOT NULL CHECK (GPA BETWEEN 0.00 AND 10.00),
    Branch VARCHAR(10) NOT NULL,
    Section VARCHAR(1) NOT NULL,
    INDEX idx_gpa (GPA DESC),
    INDEX idx_branch_section (Branch, Section)
);

-- Table 4: Allotments (Final allocation results)
CREATE TABLE Allotments (
    StudentId VARCHAR(10) NOT NULL,
    SubjectId VARCHAR(10) NOT NULL,
    AllotmentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (StudentId),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    INDEX idx_subject_allotment (SubjectId)
);

-- Table 5: Unallotted Students (Students who couldn't get any subject)
CREATE TABLE UnallottedStudents (
    StudentId VARCHAR(10) PRIMARY KEY,
    Reason VARCHAR(200),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

-- Step 3: Insert Sample Data
-- Insert Student Preferences
INSERT INTO StudentPreference (StudentId, SubjectId, Preference) VALUES
('159103036', 'PO1491', 1),
('159103036', 'PO1492', 2),
('159103036', 'PO1493', 3),
('159103036', 'PO1494', 4),
('159103036', 'PO1495', 5),
('159103037', 'PO1491', 1),
('159103038', 'PO1492', 1),
('159103039', 'PO1493', 1),
('159103040', 'PO1494', 1),
('159103041', 'PO1495', 1);

-- Insert Subject Details
INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats) VALUES
('PO1491', 'Basics of Political Science', 60, 60),
('PO1492', 'Basics of Accounting', 120, 120),
('PO1493', 'Emerging Trends in Markets', 100, 100),
('PO1494', 'Eco philosophy', 60, 60),
('PO1495', 'Automotive Trends', 60, 60);

-- Insert Student Details
INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section) VALUES
('159103036', 'Abhishek Jain', 8.9, 'CCE', 'A'),
('159103037', 'Rohit Agarwal', 5.5, 'CCE', 'A'),
('159103038', 'Sneha Garg', 7.1, 'CCE', 'A'),
('159103039', 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
('159103040', 'Mehneet Singh', 5.6, 'CCE', 'A'),
('159103041', 'Arjun Tandan', 9.2, 'CCE', 'A');

-- Step 4: Create Views for Analysis
-- View 1: Student Preferences with Subject Names
CREATE VIEW StudentPreferenceView AS
SELECT 
    sp.StudentId,
    sd.StudentName,
    sd.GPA,
    sp.SubjectId,
    sub.SubjectName,
    sp.Preference,
    sub.RemainingSeats
FROM StudentPreference sp
JOIN StudentDetails sd ON sp.StudentId = sd.StudentId
JOIN SubjectDetails sub ON sp.SubjectId = sub.SubjectId
ORDER BY sp.StudentId, sp.Preference;

-- View 2: Available Subjects
CREATE VIEW AvailableSubjects AS
SELECT SubjectId, SubjectName, MaxSeats, RemainingSeats
FROM SubjectDetails
WHERE RemainingSeats > 0;

-- Step 5: Stored Procedure for Subject Allocation
DELIMITER //

CREATE PROCEDURE AllocateSubjects()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_student_id VARCHAR(10);
    DECLARE v_subject_id VARCHAR(10);
    DECLARE v_preference INT;
    DECLARE v_remaining_seats INT;
    DECLARE v_allocated BOOLEAN DEFAULT FALSE;
    
    -- Cursor to iterate through students by GPA (highest first)
    DECLARE student_cursor CURSOR FOR
        SELECT StudentId FROM StudentDetails ORDER BY GPA DESC;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Clear previous allocations
    DELETE FROM Allotments;
    DELETE FROM UnallottedStudents;
    
    -- Reset remaining seats
    UPDATE SubjectDetails SET RemainingSeats = MaxSeats;
    
    OPEN student_cursor;
    
    student_loop: LOOP
        FETCH student_cursor INTO v_student_id;
        IF done THEN
            LEAVE student_loop;
        END IF;
        
        SET v_allocated = FALSE;
        
        -- Try to allocate based on preference order (1 to 5)
        preference_loop: BEGIN
            DECLARE pref_done INT DEFAULT FALSE;
            DECLARE pref_cursor CURSOR FOR
                SELECT sp.SubjectId, sp.Preference, sd.RemainingSeats
                FROM StudentPreference sp
                JOIN SubjectDetails sd ON sp.SubjectId = sd.SubjectId
                WHERE sp.StudentId = v_student_id 
                AND sd.RemainingSeats > 0
                ORDER BY sp.Preference ASC;
            
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET pref_done = TRUE;
            
            OPEN pref_cursor;
            
            pref_loop: LOOP
                FETCH pref_cursor INTO v_subject_id, v_preference, v_remaining_seats;
                IF pref_done THEN
                    LEAVE pref_loop;
                END IF;
                
                -- Allocate if seats available
                IF v_remaining_seats > 0 THEN
                    INSERT INTO Allotments (StudentId, SubjectId) 
                    VALUES (v_student_id, v_subject_id);
                    
                    UPDATE SubjectDetails 
                    SET RemainingSeats = RemainingSeats - 1 
                    WHERE SubjectId = v_subject_id;
                    
                    SET v_allocated = TRUE;
                    LEAVE pref_loop;
                END IF;
            END LOOP;
            
            CLOSE pref_cursor;
        END preference_loop;
        
        -- If not allocated, add to unallotted list
        IF NOT v_allocated THEN
            INSERT INTO UnallottedStudents (StudentId, Reason) 
            VALUES (v_student_id, 'No seats available in preferred subjects');
        END IF;
        
    END LOOP;
    
    CLOSE student_cursor;
    
END//

DELIMITER ;

-- Step 6: Execute the Allocation
CALL AllocateSubjects();

-- Step 7: Verification and Result Queries

-- Query 1: View all allocations with student and subject details
SELECT 
    a.StudentId,
    sd.StudentName,
    sd.GPA,
    sd.Branch,
    sd.Section,
    a.SubjectId,
    sub.SubjectName,
    sp.Preference as AllocatedPreference,
    a.AllotmentDate
FROM Allotments a
JOIN StudentDetails sd ON a.StudentId = sd.StudentId
JOIN SubjectDetails sub ON a.SubjectId = sub.SubjectId
LEFT JOIN StudentPreference sp ON a.StudentId = sp.StudentId AND a.SubjectId = sp.SubjectId
ORDER BY sd.GPA DESC;

-- Query 2: View unallotted students
SELECT 
    u.StudentId,
    sd.StudentName,
    sd.GPA,
    sd.Branch,
    u.Reason
FROM UnallottedStudents u
JOIN StudentDetails sd ON u.StudentId = sd.StudentId
ORDER BY sd.GPA DESC;

-- Query 3: Subject-wise allocation summary
SELECT 
    sub.SubjectId,
    sub.SubjectName,
    sub.MaxSeats,
    sub.MaxSeats - sub.RemainingSeats as AllocatedSeats,
    sub.RemainingSeats,
    ROUND(((sub.MaxSeats - sub.RemainingSeats) / sub.MaxSeats) * 100, 2) as UtilizationPercent
FROM SubjectDetails sub
ORDER BY AllocatedSeats DESC;

-- Query 4: Preference-wise allocation analysis
SELECT 
    sp.Preference,
    COUNT(*) as TotalAllocations,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Allotments)), 2) as Percentage
FROM Allotments a
JOIN StudentPreference sp ON a.StudentId = sp.StudentId AND a.SubjectId = sp.SubjectId
GROUP BY sp.Preference
ORDER BY sp.Preference;

-- Query 5: Branch-wise allocation summary
SELECT 
    sd.Branch,
    COUNT(a.StudentId) as AllocatedStudents,
    COUNT(u.StudentId) as UnallottedStudents,
    COUNT(a.StudentId) + COUNT(u.StudentId) as TotalStudents
FROM StudentDetails sd
LEFT JOIN Allotments a ON sd.StudentId = a.StudentId
LEFT JOIN UnallottedStudents u ON sd.StudentId = u.StudentId
GROUP BY sd.Branch
ORDER BY sd.Branch;

-- Step 8: Additional Utility Queries

-- Query to check if a specific student got their preferred subject
SELECT 
    sd.StudentName,
    a.SubjectId,
    sub.SubjectName,
    sp.Preference,
    CASE 
        WHEN sp.Preference = 1 THEN 'First Choice'
        WHEN sp.Preference = 2 THEN 'Second Choice'
        WHEN sp.Preference = 3 THEN 'Third Choice'
        WHEN sp.Preference = 4 THEN 'Fourth Choice'
        WHEN sp.Preference = 5 THEN 'Fifth Choice'
        ELSE 'Unknown'
    END as PreferenceLevel
FROM Allotments a
JOIN StudentDetails sd ON a.StudentId = sd.StudentId
JOIN SubjectDetails sub ON a.SubjectId = sub.SubjectId
JOIN StudentPreference sp ON a.StudentId = sp.StudentId AND a.SubjectId = sp.SubjectId
WHERE a.StudentId = '159103036';

-- Query to find students who didn't get their first choice
SELECT 
    a.StudentId,
    sd.StudentName,
    sd.GPA,
    a.SubjectId as AllocatedSubject,
    sub.SubjectName as AllocatedSubjectName,
    sp.Preference as AllocatedPreference,
    first_choice.SubjectId as FirstChoiceSubject,
    first_sub.SubjectName as FirstChoiceSubjectName
FROM Allotments a
JOIN StudentDetails sd ON a.StudentId = sd.StudentId
JOIN SubjectDetails sub ON a.SubjectId = sub.SubjectId
JOIN StudentPreference sp ON a.StudentId = sp.StudentId AND a.SubjectId = sp.SubjectId
JOIN StudentPreference first_choice ON a.StudentId = first_choice.StudentId AND first_choice.Preference = 1
JOIN SubjectDetails first_sub ON first_choice.SubjectId = first_sub.SubjectId
WHERE sp.Preference > 1
ORDER BY sd.GPA DESC;

-- Step 9: Performance Optimization Queries
-- Add indexes for better performance
CREATE INDEX idx_student_gpa_desc ON StudentDetails(GPA DESC);
CREATE INDEX idx_allotment_date ON Allotments(AllotmentDate);
CREATE INDEX idx_preference_order ON StudentPreference(StudentId, Preference);

-- Step 10: Data Validation Queries
-- Check for data consistency
SELECT 'Data Validation Results' as Status;

-- Check if all students have 5 preferences
SELECT 
    StudentId,
    COUNT(*) as PreferenceCount,
    CASE WHEN COUNT(*) = 5 THEN 'Complete' ELSE 'Incomplete' END as Status
FROM StudentPreference
GROUP BY StudentId
HAVING COUNT(*) != 5;

-- Check for duplicate preferences
SELECT StudentId, SubjectId, COUNT(*) as DuplicateCount
FROM StudentPreference
GROUP BY StudentId, SubjectId
HAVING COUNT(*) > 1;

-- Final summary query
SELECT 
    'ALLOCATION SUMMARY' as Summary,
    (SELECT COUNT(*) FROM Allotments) as TotalAllocated,
    (SELECT COUNT(*) FROM UnallottedStudents) as TotalUnallotted,
    (SELECT COUNT(*) FROM StudentDetails) as TotalStudents,
    ROUND((SELECT COUNT(*) FROM Allotments) * 100.0 / (SELECT COUNT(*) FROM StudentDetails), 2) as AllocationPercentage;