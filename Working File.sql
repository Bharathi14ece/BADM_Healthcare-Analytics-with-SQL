use healthcaredb;
-- Defining Primary Keys
ALTER TABLE Patients ADD PRIMARY KEY (PatientID);
ALTER TABLE Doctors ADD PRIMARY KEY (DoctorID);
ALTER TABLE Appointments ADD PRIMARY KEY (AppointmentID);
ALTER TABLE Diagnoses ADD PRIMARY KEY (DiagnosisID);
ALTER TABLE Medications ADD PRIMARY KEY (MedicationID);
-- Defining Foreign Keys
-- Appointments Table
ALTER TABLE Appointments
ADD FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
ADD FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID);
-- Diagnoses Table
ALTER TABLE Diagnoses
ADD FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
ADD FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID);
-- Medications Table
ALTER TABLE Medications
ADD FOREIGN KEY (DiagnosisID) REFERENCES Diagnoses(DiagnosisID);
-- Patient demographics with total appointments
SELECT 
    p.PatientID,
    p.Name,
    p.Gender,
    p.Age,
    COUNT(a.AppointmentID) AS TotalAppointments
FROM Patients p
LEFT JOIN Appointments a ON p.PatientID = a.PatientID
GROUP BY p.PatientID, p.Name, p.Gender, p.Age
ORDER BY TotalAppointments DESC;
-- Track number of diagnoses and treatments per doctor.
SELECT 
    d.DoctorID,
    d.Name,
    d.Specialization,
    COUNT(DISTINCT diag.DiagnosisID) AS TotalDiagnoses,
    COUNT(DISTINCT diag.Treatment) AS UniqueTreatments
FROM Doctors d
LEFT JOIN Diagnoses diag ON d.DoctorID = diag.DoctorID
GROUP BY d.DoctorID, d.Name, d.Specialization
ORDER BY TotalDiagnoses DESC;
-- Appointment Scheduling & Completion
SELECT 
    Status,
    COUNT(*) AS Count
FROM Appointments
GROUP BY Status;
-- Medication Analysis
SELECT 
    MedicationName,
    COUNT(*) AS PrescriptionCount
FROM Medications
GROUP BY MedicationName
ORDER BY PrescriptionCount DESC
LIMIT 5;
-- Revenue and Billing Analysis
SELECT 
    d.Name AS DoctorName,
    d.Specialization,
    COUNT(DISTINCT a.AppointmentID) AS CompletedAppointments,
    SUM(t.Cost) AS TotalRevenue
FROM appointments a
JOIN treatments t ON a.AppointmentID = t.AppointmentID
JOIN doctors d ON a.DoctorID = d.DoctorID
WHERE a.Status = 'Completed'
GROUP BY d.DoctorID, d.Name, d.Specialization;

-- Fetch all completed appointments with patient and doctor details - Inner Join
SELECT 
    a.AppointmentID,
    p.Name AS PatientName,
    d.Name AS DoctorName,
    d.Specialization,
    a.AppointmentDate
FROM Appointments a
INNER JOIN Patients p ON a.PatientID = p.PatientID
INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
WHERE a.Status = 'Completed';
-- Patients Without Appointments - Left Join + NULL Handling 
SELECT 
    p.PatientID,
    p.Name,
    p.ContactNumber,
    p.Address
FROM Patients p
LEFT JOIN Appointments a ON p.PatientID = a.PatientID
WHERE a.AppointmentID IS NULL;
-- Diagnoses per Doctor - Right Join + Aggregates
SELECT 
    d.DoctorID,
    d.Name,
    d.Specialization,
    COUNT(DISTINCT diag.DiagnosisID) AS TotalDiagnoses
FROM Diagnoses diag
RIGHT JOIN Doctors d ON diag.DoctorID = d.DoctorID
GROUP BY d.DoctorID, d.Name, d.Specialization;
-- Mismatched Records - Full Outer Join 
-- Appointments without matching Diagnoses
SELECT 
    a.AppointmentID,
    p.Name AS PatientName,
    d.Name AS DoctorName,
    NULL AS Diagnosis
FROM appointments a
LEFT JOIN diagnoses diag ON a.AppointmentID = diag.AppointmentID
LEFT JOIN patients p ON a.PatientID = p.PatientID
LEFT JOIN doctors d ON a.DoctorID = d.DoctorID
WHERE diag.AppointmentID IS NULL

UNION

-- Diagnoses without matching Appointments
SELECT 
    diag.AppointmentID,
    p.Name AS PatientName,
    d.Name AS DoctorName,
    diag.Diagnosis
FROM diagnoses diag
LEFT JOIN appointments a ON diag.AppointmentID = a.AppointmentID

-- Diagnoses not matched with Appointments
SELECT 
    a.AppointmentID,
    a.PatientID,
    a.DoctorID,
    diag.DiagnosisID
FROM Diagnoses diag
LEFT JOIN Appointments a ON a.AppointmentID = diag.AppointmentID
WHERE a.AppointmentID IS NULL;
-- Ranking Patients per Doctor - Window Function
SELECT 
    a.DoctorID,
    d.Name AS DoctorName,
    a.PatientID,
    p.Name AS PatientName,
    COUNT(*) AS TotalAppointments,
    RANK() OVER (PARTITION BY a.DoctorID ORDER BY COUNT(*) DESC) AS RankPerDoctor
FROM Appointments a
JOIN Doctors d ON a.DoctorID = d.DoctorID
JOIN Patients p ON a.PatientID = p.PatientID
GROUP BY a.DoctorID, d.Name, a.PatientID, p.Name;
-- Age Grouping - Conditional Expression
SELECT 
    CASE 
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '51+'
    END AS AgeGroup,
    COUNT(*) AS PatientCount
FROM Patients
GROUP BY AgeGroup;
-- Contacts ending with 1234 - String + Numeric Function
SELECT 
    UPPER(Name) AS PatientName,
    ContactNumber
FROM Patients
WHERE ContactNumber LIKE '%1234';
-- Only Insulin Prescribed Patients - Subquery 
SELECT DISTINCT PatientID
FROM Diagnoses
WHERE DiagnosisID IN (
    SELECT DiagnosisID
    FROM Medications
    GROUP BY DiagnosisID
    HAVING SUM(CASE WHEN MedicationName <> 'Insulin' THEN 1 ELSE 0 END) = 0
);
-- Average Prescription Duration - Date Function 
SELECT 
    DiagnosisID,
    AVG(DATEDIFF(EndDate, StartDate)) AS AvgPrescriptionDuration
FROM Medications
GROUP BY DiagnosisID;
-- Doctor with Most Unique Patients - Complex Join + Aggregation 
SELECT 
    d.DoctorID,
    d.Name AS DoctorName,
    d.Specialization,
    COUNT(DISTINCT a.PatientID) AS UniquePatients
FROM Appointments a
JOIN Doctors d ON a.DoctorID = d.DoctorID
GROUP BY d.DoctorID, d.Name, d.Specialization
ORDER BY UniquePatients DESC
LIMIT 1;



