USE [FDITS-BE]
GO
/****** Object:  StoredProcedure [web].[spHumanResource]    Script Date: 01/11/2022 1:00:58 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================   
-- Author: Farhan
-- Create date: 28-Apr-2021
-- Create by: M.Jahanzaib
-- last alteration date: 30-Mar-2022
-- last altered by: M.Jahanzaib
-- Description: Added Type 5 for turnover
-- =============================================   
ALTER PROCEDURE [web].[spHumanResource]
@Type INT=NULL,
@UserId INT=NULL,
@FromDate DATETIME = NULL,
@ToDate DATETIME = NULL,
@CompanyBranchIds NVARCHAR(MAX) = '',
@DepartmentIds VARCHAR(MAX)='',
@BudgetDate DATETIME = NULL,
@DesignationIds NVARCHAR(MAX)='',
@CompanyBranchIds_To NVARCHAR(MAX)='',
@JobStatusIds NVARCHAR(MAX)='',
@EmployeeInformationIds NVARCHAR(MAX)='',
@EmployeeInformationId INT=NULL,
@TimeBoundConfig NVARCHAR='1',
@GenderTypeIds NVARCHAR(MAX)='',
@GetEmployees INT=0,
@EmployementStatus NVARCHAR(20)='',
@GetKeysFromName INT=0,
@IsDayWise INT=0
AS
SET NOCOUNT ON

IF(@Type=1)
--Reference: ['TSBE.Manager.Dashboard.HRManager.HRAnalysis']
BEGIN
--DECLARE @FromDate AS DATETIME='2022-02-01';
--DECLARE @ToDate DATETIME=GETDATE()
--DECLARE @CompanyBranchIds VARCHAR(MAX)='';
--DECLARE @DepartmentIds VARCHAR(MAX)='';


SELECT CompanyBranchId,LongName,ShortName
INTO #tmpCompanyBranch
FROM CompanyBranch
WHERE CASE WHEN @CompanyBranchIds = '' THEN 0 ELSE CompanyBranchId END IN (SELECT Ids FROM dbo.SetTempHashValues(@CompanyBranchIds) AS sthv);

SELECT DepartmentId,[Name],ShortName
INTO #tmpDepartment
FROM Department
WHERE CASE WHEN @DepartmentIds = '' THEN 0 ELSE DepartmentId END IN (SELECT Ids FROM dbo.SetTempHashValues(@DepartmentIds) AS sthv);

--BEGIN: Job Status History
;WITH cteEJSHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, JobStatusId AS DimId, DENSE_RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC,DataEntryDate DESC) AS SortOrder 
FROM EmployeeJobStatus H WHERE DataEntryStatus=1

)

SELECT a.EmployeeInformationId, a.DimId,d.ShortName AS DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, ISNULL(b.AssignDate,'2999-12-31 23:59:59') AS EndDate,a.SortOrder
INTO #EmpJobStatusHist
FROM cteEJSHistSrc AS a
LEFT JOIN cteEJSHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder= b.SortOrder+1
INNER JOIN JobStatus AS d ON a.DimId=d.JobStatusId;
--END: Job Status History

--BEGIN: Branch History
;WITH cteEBHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, CompanyBranchId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeBranch H WHERE DataEntryStatus=1)
SELECT	a.EmployeeInformationId,a.DimId,d.ShortName AS DimShortName,d.[LongName] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpBranchHist
FROM cteEBHistSrc AS a
LEFT JOIN cteEBHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN #tmpCompanyBranch AS d ON a.DimId=d.CompanyBranchId
--END: Branch History

--BEGIN: Department History
;WITH cteEDHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, DepartmentId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeDepartment H WHERE DataEntryStatus=1)
SELECT	a.EmployeeInformationId, a.DimId, d.ShortName AS DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpDepartmentHist
FROM cteEDHistSrc AS a
LEFT JOIN cteEDHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN #tmpDepartment AS d ON a.DimId=d.DepartmentId
--END: Department History

--BEGIN: Designation History
;WITH cteEDesHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, DesignationId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeDesignation H WHERE DataEntryStatus=1)
SELECT	a.EmployeeInformationId, a.DimId,d.ShortName DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpDesignationHist
FROM cteEDesHistSrc AS a
LEFT JOIN cteEDesHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN Designation AS d ON a.DimId=d.DesignationId
--END: Designation History

--BEGIN: Education History
;WITH cteEEduHistSrc(EmployeeInformationId, AssignDate,DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, QualificationId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeQualification H WHERE DataEntryStatus=1)
SELECT	a.EmployeeInformationId, a.DimId,d.ShortName DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpEducationHist
FROM cteEEduHistSrc AS a
LEFT JOIN cteEEduHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN Qualification AS d ON a.DimId=d.QualificationId
--END: Qualification History

--BEGIN: Salary History
;WITH cteESalHistSrc(EmployeeInformationId, AssignDate,CalcBase,DimId,DimShortName,DimName,Amount,SortOrder) AS (
--Patch not updated: SELECT H.EmployeeInformationId, H.AssignDate,(CASE WHEN SS.SalaryTypeId=1 THEN 'Basic' ELSE (CASE WHEN ST.CalculationCriteria BETWEEN 11 AND 20 THEN 'Addition' WHEN ST.CalculationCriteria BETWEEN 31 AND 40 THEN 'Deduction' END) END) AS CalcBase, 
SELECT H.EmployeeInformationId, H.AssignDate,(CASE WHEN SS.SalaryTypeId=1 THEN 'Basic' WHEN SS.SalaryTypeId IN (2,6,9,26,27,11,13,16,20,22,24) THEN 'Addition' WHEN SS.SalaryTypeId IN (3,7,8,10,25,4,5,12,17,18,19,21,23,28) THEN 'Deduction'  END) AS CalcBase, 
SS.SalaryTypeId AS DimId,ST.ShortName AS DimShortName,ST.[Name] AS DimName,H.Amount, RANK() OVER (PARTITION BY H.EmployeeInformationId,H.SalaryStructureId ORDER BY H.AssignDate DESC, H.DataEntryDate DESC) AS SortOrder 
FROM EmployeeSalaryStructure H 
LEFT JOIN SalaryStructure SS ON ss.SalaryStructureId = H.SalaryStructureId
LEFT JOIN SalaryType ST ON st.SalaryTypeId = ss.SalaryTypeId
WHERE H.DataEntryStatus=1)
SELECT	a.EmployeeInformationId,a.CalcBase, a.DimId,a.DimShortName,a.DimName,a.Amount,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpSalaryHist
FROM cteESalHistSrc AS a
LEFT JOIN cteESalHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
--END: Salary History

--active
SELECT
EI.EmployeeInformationId,
EI.EmployeeCode,
EI.MachineCode,
RTRIM(LTRIM(RTRIM(LTRIM(RTRIM(LTRIM(ISNULL(EI.FirstName,''))) + ' ' + RTRIM(LTRIM(ISNULL(EI.MiddleName,''))))) + ' ' + RTRIM(LTRIM(ISNULL(EI.LastName,''))))) AS EmployeeName,
EI.FatherName,
EI.MotherName,
EI.HusbandName,
EI.GenderTypeId,
ISNULL(GT.GenderShortName,'M') AS GenderShortName,ISNULL(GT.GenderLongName,'Male') AS Gender,
EE.DimId AS EducationId,EE.DimShortName AS EducationSN,ISNULL(EE.DimName,'Matric') AS Education,
EI.MeritalStatusId,ISNULL(MS.StatusShortName,'S') AS MaritalStausSN,ISNULL(MS.StatusLongName,'Single') AS MaritalStatus,
ISNULL(R.ReligionName,'Muslim') AS Religion,
EI.CNIC,EI.NICExpiryDate,EI.NTN,EI.EOBINumber,
EI.DateOfBirth,
DATEDIFF(YEAR,ISNULL(EI.DateOfBirth, DATEADD(YEAR,-18,@ToDate)),@ToDate) AS Age,
DBO.Age(EI.DateOfBirth,@ToDate) AS Age2,
EI.PlaceOfBirth AS PlaceOfBirthId, C.CityShortName PlaceOfBirthSN,C.CityLongName AS PlaceOfBirth,
EI.MotherTongueId, ISNULL(L.ShortName,'Urdu') AS MotherTongueSN,ISNULL(L.Name,'Urdu') AS MotherTongue,
EI.BloodGroupId,BG.[Name] AS BloodGroup,
EJS.DimId AS JobStatusId,EJS.DimShortName AS JobSTatusSN,EJS.DimName AS JobStatus,
EJS.StartDate AS JoinDate,
--DBO.Time_GetDateDiff('D','YEAR',EJS.StartDate,@ToDate) AS ServiceLength,Miscalcl
DATEDIFF(DAY,EJS.StartDate,@ToDate)/364.25 AS ServiceLength,
DBO.Age(EmployeeJoiningDateTable.AssignDate,@ToDate) AS ServiceLength2,
EB.DimId AS CompanyBranchId,EB.DimShortName AS CompanyBranchSN, EB.DimName AS CompanyBranch,
ED.DimId AS DepartmentId,ED.DimShortName AS DepartmentSN,ED.DimName AS Department,
EDes.DimId AS DesignationId,EDes.DimShortName AS DesignationSN,EDes.DimName AS Designation,
ESal.Amount AS GrossSalary
--Adress and Contact
--Expericence History
--Training History
,eimg.ImageBlock
--,EI.*
FROM EmployeeInformation EI
LEFT JOIN GenderType AS GT ON EI.GenderTypeId=GT.GenderTypeId
LEFT JOIN MeritalStatus AS MS ON EI.MeritalStatusId=MS.MeritalStatusId
LEFT JOIN Religion AS R ON EI.ReligionId=R.ReligionId
LEFT JOIN [Language] AS L ON EI.MotherTongueId=L.LanguageId
LEFT JOIN BloodGroup AS BG ON EI.BloodGroupId=BG.BloodGroupId
LEFT JOIN City AS C ON EI.PlaceOfBirth=C.CityId
LEFT JOIN EmployeeImage AS eimg ON ei.EmployeeInformationId=eimg.EmployeeInformationId AND eimg.DataEntryStatus=1
INNER JOIN #EmpJobStatusHist AS EJS ON EI.EmployeeInformationId=EJS.EmployeeInformationId AND EJS.SortOrder=1
LEFT JOIN #tmpEmpBranchHist AS EB ON EI.EmployeeInformationId=EB.EmployeeInformationId AND EB.SortOrder=1
LEFT JOIN #tmpEmpDepartmentHist AS ED ON EI.EmployeeInformationId=ED.EmployeeInformationId AND ED.SortOrder=1
LEFT JOIN #tmpEmpDesignationHist AS EDes ON EI.EmployeeInformationId=EDes.EmployeeInformationId AND EDes.SortOrder=1
LEFT JOIN #tmpEmpSalaryHist AS ESal ON EI.EmployeeInformationId=ESal.EmployeeInformationId AND ESal.SortOrder=1 AND ESal.DimId=1
LEFT JOIN #tmpEmpEducationHist AS EE ON EI.EmployeeInformationId=EE.EmployeeInformationId AND EE.SortOrder=1

LEFT JOIN (
				SELECT * FROM (
					SELECT	ejs.EmployeeJobStatusId, ejs.EmployeeInformationId, ejs.JobStatusId, ejs.AssignDate, ejs.UserId, ejs.DataEntryDate, ejs.DataEntryStatus, 
							RANK() OVER (PARTITION BY ejs.EmployeeInformationId ORDER BY ISNULL(R.AssignDate, CAST('1900-01-01' AS DATETIME)) DESC, ejs.AssignDate, ejs.EmployeeJobStatusId) AS SortOrder
					FROM	EmployeeJobStatus ejs 
							LEFT OUTER JOIN (
								SELECT	Rs.EmployeeInformationId, Rs.AssignDate 
								FROM	(
									SELECT	ejs.EmployeeInformationId, ejs.AssignDate, 
											RANK() OVER (PARTITION BY ejs.EmployeeInformationId ORDER BY ejs.AssignDate, ejs.EmployeeJobStatusId) AS SortOrder
									FROM	EmployeeJobStatus ejs
									WHERE	ejs.DataEntryStatus = 1 AND ejs.JobStatusId IN (3, 4)
								) Rs 
								WHERE	Rs.SortOrder = 1
							) R ON R.EmployeeInformationId = ejs.EmployeeInformationId AND ejs.AssignDate >= ISNULL(R.AssignDate, CAST('1900-01-01' AS DATETIME))
					WHERE	ejs.DataEntryStatus = 1 AND ejs.JobStatusId IN (1, 2, 5, 6)
				) JobStats
				WHERE	JobStats.SortOrder = 1
			) AS EmployeeJoiningDateTable ON ei.EmployeeInformationId = EmployeeJoiningDateTable.EmployeeInformationId
WHERE EJS.DimId IN(1,2,5,6,7)--Active Employees

--SELECT EmployeeInformationId, AssignDate, YEAR(AssignDate) AS AssignYear, JobStatusId AS DimId FROM EmployeejobStatus--ToDo: Year to be handle in code
SELECT h.*
,ed.DimId AS DepartmentId,ed.DimName AS Department,ed.DimshortName AS DepartmentSN
,eb.DimId AS CompanyBranchId,eb.DimName AS CompanyBranch,eb.DimshortName AS CompanyBranchSN
,edes.DimId AS DesignationIdId,edes.DimName AS Designation,edes.DimshortName AS DesignationSN
,EI.GenderTypeId,ISNULL(GT.GenderLongName,'Male') AS Gender,ISNULL(GT.GenderShortName,'M') AS GenderShortName
,NULL AS [Status]
FROM #EmpJobStatusHist AS h
LEFT JOIN #tmpEmpDepartmentHist AS ED ON h.EmployeeInformationId=ED.EmployeeInformationId AND ED.SortOrder=1
LEFT JOIN #tmpEmpDesignationHist AS EDes ON h.EmployeeInformationId=EDes.EmployeeInformationId AND EDes.SortOrder=1
LEFT JOIN #tmpEmpBranchHist AS EB ON h.EmployeeInformationId=EB.EmployeeInformationId AND EB.SortOrder=1
LEFT JOIN EmployeeInformation AS ei ON h.EmployeeInformationId=ei.EmployeeInformationId
LEFT JOIN GenderType AS GT ON EI.GenderTypeId=GT.GenderTypeId
 
SELECT t.ComapnyBranchId, t.DepartmentId, t.DesignationId, t.HeadCount AS Headcount, t.BudgetAmount AS Salary, t.ApplyDate
,cb.LongName AS CompanyBranch,cb.ShortName AS CompanyBranchSN
,d.Name AS Department,d.ShortName AS DepartmentSN
,de.Name AS Designation,de.ShortName AS DesignationSN
FROM DepartmentSalaryBudget t 
	LEFT JOIN CompanyBranch cb ON t.ComapnyBranchId=cb.CompanyBranchId
	LEFT JOIN Department d ON t.DepartmentId=d.DepartmentId
	LEFT JOIN Designation de ON t.DesignationId=de.DesignationId
WHERE t.DataEntryStatus=1
--WHERE t.ApplyDate=ISNULL(@BudgetDate,'2021-01-01')

IF OBJECT_ID('tempdb..#EmpJobStatusHist') IS NOT NULL DROP TABLE #EmpJobStatusHist
IF OBJECT_ID('tempdb..#tmpCompanyBranch') IS NOT NULL DROP TABLE #tmpCompanyBranch
IF OBJECT_ID('tempdb..#tmpDepartment') IS NOT NULL DROP TABLE #tmpDepartment
IF OBJECT_ID('tempdb..#tmpEmpBranchHist') IS NOT NULL DROP TABLE #tmpEmpBranchHist
IF OBJECT_ID('tempdb..#tmpEmpDepartmentHist') IS NOT NULL DROP TABLE #tmpEmpDepartmentHist
IF OBJECT_ID('tempdb..#tmpEmpDesignationHist') IS NOT NULL DROP TABLE #tmpEmpDesignationHist
IF OBJECT_ID('tempdb..#tmpEmpSalaryHist') IS NOT NULL DROP TABLE #tmpEmpSalaryHist
IF OBJECT_ID('tempdb..#tmpEmpEducationHist') IS NOT NULL DROP TABLE #tmpEmpEducationHist
END

IF (@Type=2)
BEGIN
--Reference: ['TSBE.Manager.Dashboard.HRManager.HRAnalysis_Attendance']
--DECLARE @Type INT=NULL
--DECLARE @FromDate DATETIME =  '2021-10-01 00:00:00:000'
--DECLARE @ToDate DATETIME = '2021-10-31 23:59:59:998'
--DECLARE @CompanyBranchIds NVARCHAR(MAX) = ''
--DECLARE @DepartmentIds VARCHAR(MAX)=''
--DECLARE @BudgetDate DATETIME = NULL
--DECLARE @DesignationIds NVARCHAR(MAX)=''
--DECLARE @CompanyBranchIds_To NVARCHAR(MAX)=''
--DECLARE @JobStatusIds NVARCHAR(MAX)=''
--SET @EmployeeInformationIds=''
--SET @FromDate= '2021-10-01 00:00:00:000'
--SET @ToDate='2021-10-31 23:59:59:998'
--DECLARE @IsDayWise INT=0
DECLARE @IsRestDay INT = 1

IF OBJECT_ID('tempdb..#EMPDR1') IS NOT NULL	DROP TABLE #EMPDR1
	IF OBJECT_ID('tempdb..#tmpCompanyBranch2') IS NOT NULL		DROP TABLE #tmpCompanyBranch2
	IF OBJECT_ID('tempdb..#tmpDepartment2') IS NOT NULL		DROP TABLE #tmpDepartment2
	IF OBJECT_ID('tempdb..#TmpAttData01') IS NOT NULL		DROP TABLE #TmpAttData01
	IF OBJECT_ID('tempdb..#TmpAttData01_2') IS NOT NULL		DROP TABLE #TmpAttData01_2
	IF OBJECT_ID('tempdb..#Employee') IS NOT NULL	DROP TABLE #Employee
--Config
SET @TimeBoundConfig=ISNULL((SELECT sc.ConfigurationData FROM SoftwareConfiguration AS sc WHERE sc.ConfigurationName='AllowDateControlWorkOnSaleStartTime'),'1')
	
SELECT CompanyBranchId,LongName,ShortName
INTO #tmpCompanyBranch2
FROM CompanyBranch
WHERE CASE WHEN @CompanyBranchIds = '' THEN 0 ELSE CompanyBranchId END IN (SELECT Ids FROM dbo.SetTempHashValues(@CompanyBranchIds) AS sthv)

SELECT DepartmentId,[Name],ShortName
INTO #tmpDepartment2
FROM Department
WHERE CASE WHEN @DepartmentIds = '' THEN 0 ELSE DepartmentId END IN (SELECT Ids FROM dbo.SetTempHashValues(@DepartmentIds) AS sthv)

	DECLARE @IsRestDayDeduction INT = 0
	IF EXISTS(SELECT * FROM SoftwareConfiguration sc WHERE sc.ConfigurationName = 'IsRestDayDeduction')
	BEGIN
		SELECT @IsRestDayDeduction = ISNULL(sc.ConfigurationData,0) FROM SoftwareConfiguration sc WHERE sc.ConfigurationName = 'IsRestDayDeduction'
	END 

	PRINT ''
	PRINT ''
	PRINT 'Start of SP [GetAttendanceSummary]										' + CONVERT(VARCHAR, GETDATE(), 113)
	PRINT '-------------------------------------------------------------------------------------------------'
	PRINT ''
	
	CREATE TABLE #TmpAttData01(EmployeeInformationId INT, MachineCode NVARCHAR(50), EmployeeCode VARCHAR(100), EmpName VARCHAR(200),
								BranchName VARCHAR(100), DepartmentId INT, Department VARCHAR(100), DesignationId INT, Designation VARCHAR(100),
								WeekDay VARCHAR(100), DayTypeId INT, DayTypeName VARCHAR(100), DayTypeShortName VARCHAR(100),
								AttendanceDate DATETIME, DateTimeIn DATETIME, DateTimeOut DATETIME, [Status] VARCHAR(100),
								TWorkHours VARCHAR(100), TWorkHouseAsPerRoster VARCHAR(100), TShortExcess VARCHAR(100), PDayWorkRate NUMERIC(18,6), 
								IsOnTime BIT, IsLateIn BIT, IsLateInApproved BIT, LateInMinutes INT, IsHalfDay BIT, IsRoster BIT, IsAbsent BIT, 
								IsLeave BIT, IsShortLeave BIT, IsPaidLeave BIT, IsSuspend BIT, AttStatus VARCHAR(100),
								EarlyOut BIT, EarlyOutApproved BIT, EarlyOutMinutes INT, PaidLeaveMinutes INT, UnPaidLeaveMinutes INT,
								GraceMinutes INT, TMissPunchIN INT, TMissPunchOut INT,
								IsOverTime BIT, OverTimeRate DECIMAL(12,4), OverTime VARCHAR(100), OverTimeMinutes INT,EmployeeOverTimeId INT,
								IsApprovedOverTime BIT, TOverTimeRate DECIMAL(12,4), TOverTime VARCHAR(100), TOverTimeMinutes INT,
								CompanyBranchId INT, HolidayTypeId INT, HolidayTypeName VARCHAR(100), LeaveTypeId INT, LeaveType VARCHAR(20),
								WorkShiftId INT, Remarks VARCHAR(1000), IsPosted INT, BreakTimeMinutes INT,
								IsShortWorkingHour INT, IsShortWorkingHourApproved INT, ShortWorkingHourMinutes INT,
								TimeInCurrentLocation  VARCHAR(5000),TimeInLatitude  VARCHAR(100), TimeInLongitude   VARCHAR(100),
								TimeOutCurrentLocation VARCHAR(5000), TimeOutLatitude VARCHAR(100), TimeOutLongitude VARCHAR(100),
								InEdit int,OutEdit int,InEditBy int,OutEditBy int)

	DECLARE @CurrentDate DATETIME
	DECLARE @AttTableName NVARCHAR(200)
	DECLARE @Query NVARCHAR(MAX)		

	SET @CurrentDate = GETDATE()
	SET @AttTableName = 'AttDataTable' + CAST(YEAR(@CurrentDate) AS VARCHAR) + CAST(MONTH(@CurrentDate) AS VARCHAR) + CAST(DAY(@CurrentDate) AS VARCHAR) + CAST(DATEPART(hour,@CurrentDate) AS VARCHAR) + CAST(DATEPART(minute,@CurrentDate) AS VARCHAR) + CAST(DATEPART(second,@CurrentDate) AS VARCHAR) + CAST(DATEPART(ms,@CurrentDate) AS VARCHAR)

	WHILE ((SELECT COUNT(*) FROM sys.tables t WHERE t.name = @AttTableName) > 0)
	BEGIN
		SET @CurrentDate = GETDATE()
		SET @AttTableName = 'AttDataTable' + CAST(YEAR(@CurrentDate) AS VARCHAR) + CAST(MONTH(@CurrentDate) AS VARCHAR) + CAST(DAY(@CurrentDate) AS VARCHAR) + CAST(DATEPART(hour,@CurrentDate) AS VARCHAR) + CAST(DATEPART(minute,@CurrentDate) AS VARCHAR) + CAST(DATEPART(second,@CurrentDate) AS VARCHAR) + CAST(DATEPART(ms,@CurrentDate) AS VARCHAR)
	END

	DECLARE @IsCalculateonDailyWages int=0

	SET @Query = 'EXEC GetAttendanceData 
	@FromDate = ''' + CONVERT(VARCHAR,@FromDate,121) + ''', 
	@ToDate = ''' + CONVERT(VARCHAR,@ToDate,121) + ''', 
	@EmployeeInformationId = ''' + @EmployeeInformationIds + ''',
	@DepartmentIds = ''' + @DepartmentIds + ''',
	@WithRestDayDeduction = ' + CAST(@IsRestDayDeduction AS VARCHAR) + ',
	@IsCalculateonDailyWages ='+cast(@IsCalculateonDailyWages as varchar)+',
	@IsInsertAttData = 1, 
	@AttDataTableName = ''' + @AttTableName + ''''
	--	@CompanyBranchIds = ''' + @CompanyBranchIds + ''', param not available
	PRINT @Query
	EXECUTE(@Query)

		SET @Query = '	INSERT INTO #TmpAttData01
					SELECT	EmployeeInformationId, MachineCode, EmployeeCode, EmpName, BranchName,
							DepartmentId, Department, DesignationId, Designation, WeekDay, DayTypeId, DayTypeName, DayTypeShortName,
							AttendanceDate, DateTimeIN, DateTimeOut, [Status], TWorkHours, TWorkHouseAsPerRoster, TShortExcess, PDayWorkRate,
							IsOnTime, IsLateIn, IsLateInApproved, LateInMinutes, IsHalfDay, IsRoster, IsAbsent,
							IsLeave, IsShortLeave, IsPaidLeave, IsSuspend, AttStatus, EarlyOut, EarlyOutApproved, EarlyOutMinutes,
							PaidLeaveMinutes, UnPaidLeaveMinutes, GraceMinutes, TMissPunchIN, TMissPunchOut,
							IsOverTime, OverTimeRate, OverTime, OverTimeMinutes,EmployeeOverTimeId, IsApprovedOverTime, TOverTimeRate, TOverTime, TOverTimeMinutes,
							CompanyBranchId, HolidayTypeId, HolidayTypeName, LeaveTypeId, LeaveType,
							WorkShiftId, Remarks, IsPosted, BreakTimeMinutes,
							IsShortWorkingHour, IsShortWorkingHourApproved, ShortWorkingHourMinutes, TimeInCurrentLocation, TimeInLatitude, TimeInLongitude,
				TimeOutCurrentLocation, TimeOutLatitude, TimeOutLongitude,InEdit,OutEdit,InEditBy,OutEditBy FROM ' + @AttTableName + '

	DROP TABLE ' + @AttTableName

	PRINT @Query
	EXECUTE(@Query)
	--SELECT * from #TmpAttData01
	PRINT '-------------------------------------------------------------------------------------------------'
	PRINT ''
		CREATE TABLE #EMPDR1(EmployeeInformationId INT,AttendanceDate DATETIME,WeekDay NVARCHAR(100),DayTypeId INT,DeductionRate DECIMAL)		
		IF EXISTS(SELECT TOP 1 adc.AbsentDeductionConfigurationId FROM AbsentDeductionConfiguration adc WHERE adc.DataEntryStatus = 1)
		BEGIN
			IF EXISTS(SELECT TOP 1 adc.AbsentDeductionConfigurationId FROM AbsentDeductionConfiguration adc WHERE adc.DataEntryStatus = 1
						AND adc.EmployeeInformationId IN (SELECT DISTINCT EmployeeInformationId FROM #TmpAttData01))
			BEGIN
				INSERT INTO #EMPDR1
				EXEC spGetEmployeeDeductionRate @Type = 1, @FromDate = @FromDate, @ToDate = @ToDate, @EmployeeInformationIds = @EmployeeInformationIds
			END
		END
		
		--Detail
		
					SELECT vei.EmployeeInformationId,vei.GenderTypeId--*
					INTO #Employee
					FROM EmployeeInformation AS vei --ViewEmployeeInformation vei
					WHERE vei.EmployeeInformationId IN (SELECT DISTINCT EmployeeInformationId FROM #TmpAttData01)
						  --AND CASE WHEN @JobStatusIds = '' THEN 0 ELSE vei.JobStatusId END IN (SELECT Ids FROM dbo.SetTempHashValues(@JobStatusIds) sthv)
						  --AND CASE WHEN @DepartmentIds ='' THEN 0 ELSE vei.DepartmentId END IN(SELECT Ids FROM dbo.SetTempHashValues(@DepartmentIds) sthv)
					
					SELECT a.BranchName AS CompanyBranch,ISNULL(cb2.ShortName,a.BranchName) AS CompanyBranchSN, CAST(CONVERT(VARCHAR, a.AttendanceDate, 111) AS DATETIME) AttendanceDate, 
						   a.EmployeeInformationId,
						   a.EmployeeCode, a.MachineCode, a.EmpName AS EmployeeName, a.Department, ISNULL(d2.ShortName,a.Department) AS DepartmentSN,
						   a.Designation, CASE WHEN LEN(ISNULL(d.ShortName,''))=0 THEN a.Designation ELSE d.ShortName END AS DesignationSN,	vei.GenderTypeId, gt.GenderLongName AS Gender, ISNULL(gt.GenderShortName,gt.GenderLongName) AS GenderSN
						   ,a.DateTimeIn, a.DateTimeOut,			       
						   CASE WHEN(@IsRestDay = 0 AND a.[Status] = 'Rest Day' AND a.DateTimeIN IS NULL) THEN ''
								WHEN a.[Status] = 'Absent' AND ISNULL(edr.DeductionRate,1) > 1 THEN 'Absent2'
								WHEN a.IsHalfDay = 1 THEN  'Half Day'
						   ELSE a.[Status] END AS [Status],				   
						   CASE		WHEN a.[Status] = 'Absent' AND ISNULL(edr.DeductionRate,1) > 1 THEN 'A2'
									WHEN a.[Status] = 'Absent' THEN 'A'
									--WHEN a.DayTypeId = 1 AND a.IsAbsent = 1 THEN 'A'
									WHEN a.DayTypeId = 1 AND a.DateTimeIN IS NOT NULL THEN 'P'
									WHEN a.DayTypeId = 2 AND a.DateTimeIN IS NULL AND a.IsLeave = 0 THEN 'R'
									WHEN a.DayTypeId = 2 AND a.DateTimeIN IS NULL AND a.IsLeave = 1 AND a.IsPaidLeave = 1 THEN 'R-' + a.LeaveType + '-P'
									WHEN a.DayTypeId = 2 AND a.DateTimeIN IS NULL AND a.IsLeave = 1 AND a.IsPaidLeave = 0 THEN 'R-' + a.LeaveType + '-UP'
									WHEN a.DayTypeId = 2 AND a.DateTimeIN IS NOT NULL AND a.IsApprovedOverTime = 1 THEN 'R-OT'
									WHEN a.DayTypeId = 2 AND a.DateTimeIN IS NOT NULL THEN 'R-P'
									WHEN a.DayTypeId = 3 AND a.DateTimeIN IS NULL AND a.IsLeave = 0 THEN 'H-' + CASE WHEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) <> '' THEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) ELSE RTRIM(LTRIM(ISNULL(ht.Name,''))) END
									WHEN a.DayTypeId = 3 AND a.DateTimeIN IS NULL AND a.IsLeave = 1 AND a.IsPaidLeave = 1 THEN 'H-' + CASE WHEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) <> '' THEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) ELSE RTRIM(LTRIM(ISNULL(ht.Name,''))) END + '-' + a.LeaveType + '-P'
									WHEN a.DayTypeId = 3 AND a.DateTimeIN IS NULL AND a.IsLeave = 1 AND a.IsPaidLeave = 0 THEN 'H-' + CASE WHEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) <> '' THEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) ELSE RTRIM(LTRIM(ISNULL(ht.Name,''))) END + '-' + a.LeaveType + '-UP'
									WHEN a.DayTypeId = 3 AND a.DateTimeIN IS NOT NULL AND a.IsApprovedOverTime = 1 THEN 'H-' + CASE WHEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) <> '' THEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) ELSE RTRIM(LTRIM(ISNULL(ht.Name,''))) END + '-OT'
									WHEN a.DayTypeId = 3 AND a.DateTimeIN IS NOT NULL AND a.IsApprovedOverTime = 0 THEN 'H-' + CASE WHEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) <> '' THEN RTRIM(LTRIM(ISNULL(ht.ShortName,''))) ELSE RTRIM(LTRIM(ISNULL(ht.Name,''))) END
									WHEN a.DayTypeId = 1 AND a.DateTimeIN IS NULL AND a.IsLeave = 1 AND a.IsPaidLeave = 1 THEN a.LeaveType + '-P'
									WHEN a.DayTypeId = 1 AND a.DateTimeIN IS NULL AND a.IsLeave = 1 AND a.IsPaidLeave = 0 THEN a.LeaveType + '-UP'
									ELSE ''
							END + 
						   CASE		WHEN a.DateTimeIN IS NOT NULL AND a.IsLateIn = 1 THEN '-LI'
									WHEN a.DateTimeIN IS NOT NULL AND a.IsLateInApproved = 1 THEN '-ALI'
									ELSE ''
							END + 
						   CASE		WHEN a.DateTimeIN IS NOT NULL AND a.EarlyOut = 1 THEN '-EO'
									WHEN a.DateTimeIN IS NOT NULL AND a.EarlyOutApproved = 1 THEN '-AEO'
									ELSE ''
							END + 
						   CASE		WHEN a.DateTimeIN IS NOT NULL AND a.IsShortLeave = 1 AND a.IsPaidLeave = 1 THEN '-SL-P'
									WHEN a.DateTimeIN IS NOT NULL AND a.IsShortLeave = 1 AND a.IsPaidLeave = 0 THEN '-SL-UP'
									ELSE ''
							END +
							CASE	WHEN a.IsHalfDay = 1 THEN '-HD' ELSE '' END StatusDetail,		   
						   a.WeekDay,a.DayTypeName,ISNULL(a.HolidayTypeName,'') HolidayTypeName,
						   ISNULL(a.TWorkHouseAsPerRoster,'') TWorkHouseAsPerRoster2 ,
						   ISNULL(a.TWorkHours,'') TWorkHours2, ISNULL(a.TShortExcess,'') TShortExcess2,
						    a.PDayWorkRate,				   
						  CASE	WHEN a.IsHalfDay =1 then 'Half Day'
								WHEN a.IsOnTime = 1 then 'On Time' 
								WHEN a.IsLateIn =1 then 'Late In'
								WHEN a.IsLateInApproved = 1 THEN 'App L.I'
								WHEN a.IsAbsent =1 and Status = 'Work Day' AND ISNULL(edr.DeductionRate,1) > 1 then 'Absent2'
								WHEN a.IsAbsent =1 and Status = 'Work Day' then 'Absent'
								WHEN a.IsLeave =1 then 'Leave'
								WHEN a.IsRoster =0 then 'No Roster'
								WHEN a.[Status] = 'Absent' AND ISNULL(edr.DeductionRate,1) > 1 THEN 'Absent2' 
								else Status 
						  END as [In Status],						
						  CASE  WHEN a.EarlyOut = 1 then 'Early Out' 
								WHEN a.EarlyOutApproved = 1 THEN 'App E.O'
								WHEN a.IsAbsent =1 and Status = 'Work Day' AND ISNULL(edr.DeductionRate,1) > 1 then 'Absent2'
								WHEN a.IsAbsent =1 and Status = 'Work Day' then 'Absent'
								WHEN a.IsRoster =0 then 'No Roster'
								WHEN a.[Status] = 'Absent' AND ISNULL(edr.DeductionRate,1) > 1 THEN 'Absent2' 
								else Status 
						  END as [Out Status],				   
						   a.TMissPunchIN,
						   a.TMissPunchOut,				   				   
						   CASE  WHEN  a.DateTimeOut IS  NOT NULL THEN  'Office Left'
						   WHEN a.DateTimeIN IS NOT NULL AND a.DateTimeOut IS NULL  THEN  'Company'
						   WHEN  a.DateTimeIN IS NULL AND  a.DateTimeOut IS NULL  THEN ''
						   ELSE  '' END AS  [Current Status],
						   a.IsAbsent,
						   CASE WHEN a.[Status] = 'Absent' AND ISNULL(edr.DeductionRate,1) > 1 THEN 'Deduction Rate: ' + CAST(edr.DeductionRate AS NVARCHAR)+ ' ' + a.Remarks ELSE a.Remarks END Remarks,
						   ISNULL(a.WorkShiftId,0) WorkShiftId,
						   ISNULL (ws.[Name],'No Roster') WSLongName, ISNULL(ISNULL(ws.ShortName,ws.[Name]),'No Roster') WSShortName,
						   a.DayTypeShortName, a.IsOnTime, a.IsLateIn,
						   a.IsHalfDay, a.IsRoster, a.IsLeave, a.IsShortLeave, a.AttStatus,
						   a.EarlyOut, a.IsOverTime, a.OverTime, a.OverTimeMinutes,
						   a.TOverTime, a.TOverTimeMinutes, a.CompanyBranchId,
						   ISNULL(a.LeaveType,'') LeaveType
						   /*,ISNULL(vei.DepartmentId,0) DepartmentId, ISNULL(vei.JobStatusId, 0) JobStatusId, vei.JobStatus,,vei.FatherName, 
						   vei.MotherName, vei.CNIC, vei.DateOfBirth,
						   vei.JoiningDate, vei.JobStatusShortName,
						   vei.JobStatusAssignDate, ISNULL(vei.ImageItemId,0)ImageItemId, NULL ImageBlock, NULL [Signature]*/
						   ,CONVERT(INT, ISNULL(dbo.FnConvertHoursInMinutes(a.TWorkHours),0)) TWorkMinutes,
						   CONVERT(INT,ISNULL(dbo.FnConvertHoursInMinutes(a.TShortExcess),0)) TShortExcessMinutes,
						   CONVERT(INT,ISNULL(dbo.FnConvertHoursInMinutes(a.TWorkHouseAsPerRoster),0)) TWorkAsPerRosterMinutes
						   ,CASE WHEN a.IsOnTime =1  THEN 'On Time'  END AS OnTimeStatus,
						   CASE WHEN a.IsLateIn = 1 THEN 'Late In'  END AS LateInStatus,			    			    			     
						   CASE	WHEN a.IsHalfDay = 1 THEN 'HalfDay' END AS HalfDayStatus,
						   CASE WHEN a.EarlyOut = 1 THEN 'Early Out' END AS EarlyOutStatus
						   ,a.IsLateInApproved, 
						   ISNULL(a.EmployeeOverTimeId,0) EmployeeOverTimeId, 
						   ISNULL(a.IsApprovedOverTime,0) IsApprovedOverTime,
						   a.EarlyOutApproved, 
						   a.LateInMinutes, a.EarlyOutMinutes,a.PaidLeaveMinutes, a.UnPaidLeaveMinutes,
						   (a.LateInMinutes + a.EarlyOutMinutes + a.UnPaidLeaveMinutes) DeductionTotalMinutes,
						   ISNULL(a.BreakTimeMinutes,0) BreakTimeMinutes, 
						   dbo.FnMinutsInHours(a.BreakTimeMinutes) BreakTime,
						   ws.StartTime WorkShiftStartTime, ws.EndTime WorkShiftEndTime, 
						   ISNULL(ad.OutStationBranchId,0) OutStationBranchId, 
						   cb.LongName OutStationBranch,
						   ISNULL(ad.ClientInformationId,0) ClientInformationId, 
						   ci.ClientName, CASE WHEN ad.AttendanceDetailId > 0 THEN 'Active' ELSE 'Not Active' END OutStationStatus, 
						   a.IsShortWorkingHour, a.IsShortWorkingHourApproved, a.ShortWorkingHourMinutes, TimeInCurrentLocation, TimeInLatitude, TimeInLongitude,
						  TimeOutCurrentLocation, TimeOutLatitude, TimeOutLongitude,  dbo.ReturnEmployeeFullName(Eot.ApprovedBy) ApprovedBy,InEdit,OutEdit,Eud.EmployeeName EditBy
						,CAST(RIGHT('00'+ CAST(MONTH(a.AttendanceDate) AS VARCHAR(2)),2) + '/'  + '01/' +  CAST(YEAR(a.AttendanceDate) AS VARCHAR(4)) AS DATETIME) AttMonth			
						,a.DayTypeId
					INTO #tmpAttData01_2
					FROM #TmpAttData01 a
					INNER JOIN #Employee vei ON vei.EmployeeInformationId = a.EmployeeInformationId
					LEFT OUTER JOIN WorkShift ws ON ws.WorkShiftId = a.WorkShiftId
					LEFT JOIN Designation d ON d.DesignationId = a.DesignationId
					LEFT JOIN Department d2 ON d2.DepartmentId =a.DepartmentId-- vei.DepartmentId
					LEFT OUTER JOIN AttendanceDetail ad ON ad.EmployeeInformationId = a.EmployeeInformationId 
														 AND CAST(ad.AttendanceDate AS Date) = CAST(a.AttendanceDate AS Date) AND ad.DataEntryStatus = 1 AND ad.AttendanceActionTypeId = 4
					LEFT OUTER JOIN CompanyBranch cb ON cb.CompanyBranchId = ad.OutStationBranchId
					LEFT JOIN CompanyBranch cb2 ON a.CompanyBranchId = cb2.CompanyBranchId
					LEFT OUTER JOIN ClientInformation ci ON ci.ClientInformationId = ad.ClientInformationId
					LEFT OUTER JOIN HolidayType ht ON ht.HolidayTypeId = a.HolidayTypeId
					LEFT JOIN #EMPDR1 edr ON edr.EmployeeInformationId = a.EmployeeInformationId AND edr.AttendanceDate = a.AttendanceDate AND edr.WeekDay = a.WeekDay AND edr.DayTypeId = a.DayTypeId
					LEFT JOIN EmployeeOverTime Eot ON a.EmployeeOverTimeId = Eot.EmployeeOverTimeId
					LEFT JOIN (SELECT Distinct UserId,EmployeeInformationId FROM [User] ) AS u ON ISNULL(InEditBy,a.OutEditBy)=u.UserId
					LEFT JOIN (SELECT EmployeeInformationId,EmployeeName FROM ViewEmployeeInformation) eud ON eud.EmployeeInformationId = u.EmployeeInformationId
					LEFT JOIN GenderType AS gt ON vei.GenderTypeId=gt.GenderTypeId
					WHERE CASE WHEN @CompanyBranchIds = '' THEN 0 ELSE ISNULL(a.CompanyBranchId,-1) END IN (SELECT Ids FROM dbo.SetTempHashValues(@CompanyBranchIds) sthv)
		
		IF @IsDayWise=1
		BEGIN
			--ToDo: Add more params with csv
			SELECT a.*,EJS.AssignDate AS JoinDate,DATEDIFF(DAY,EJS.AssignDate,@ToDate)/364.25 AS ServiceLength,DBO.Age(EJS.AssignDate,@ToDate) AS ServiceLength2
			,TWorkMinutes/60 AS TWorkHours,TWorkAsPerRosterMinutes/60 AS TWorkAsPerRosterHours,TShortExcessMinutes/60 AS TShortExcessHours,TOverTimeMinutes/60 AS TOverTimeHours
			FROM #tmpAttData01_2 AS a 
			LEFT JOIN (SELECT * FROM 
								(SELECT EmployeeInformationId, AssignDate, DENSE_RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC,DataEntryDate DESC) AS SortOrder 
								FROM EmployeeJobStatus H WHERE DataEntryStatus=1 AND h.JobStatusId NOT IN(3,4) AND h.EmployeeInformationId=@EmployeeInformationId) AS q 
						WHERE q.SortOrder=1) AS EJS ON ejs.EmployeeInformationId=a.EmployeeInformationId
			WHERE a.EmployeeInformationId=@EmployeeInformationId
			ORDER BY a.AttendanceDate

			SELECT ImageBlock
			FROM EmployeeImage AS ei 
			WHERE ei.DataEntryStatus=1 AND ei.EmployeeInformationId=@EmployeeInformationId
		END
		ELSE
		BEGIN
			SELECT AttMonth,FORMAT(AttMonth,'yyyy') AS cYear, FORMAT(AttMonth,'MMM') AS cMonth,
			CompanyBranch,CompanyBranchSN,Department,DepartmentSN,Designation,DesignationSN,
			EmployeeInformationId, EmployeeCode, MachineCode,EmployeeName,
			GenderTypeId,Gender,GenderSN,
			(CASE WHEN YEAR(AttMonth)=YEAR(@ToDate) AND MONTH(AttMonth)=MONTH(@ToDate) THEN DATEDIFF(D,@FromDate,@ToDate)+(CASE WHEN @TimeBoundConfig='2' THEN 0 ELSE 1 END) ELSE DAY(EOMONTH(AttMonth)) END) AS TotalAttendance
			,SUM(CASE WHEN [Status]='Present' THEN 1 ELSE 0 END) Present,SUM(CASE WHEN [Status]='Absent' THEN 1 WHEN [Status]='Absent2' THEN 1 ELSE 0 END) AS [Absent]
			,SUM(CAST(IsShortLeave AS INT)) ShortLeave,SUM(CAST(IsLeave AS INT)) Leave
			,SUM(CASE WHEN [Status]='Rest Day' THEN 1 ELSE 0 END) RestDay,SUM(CASE WHEN [Status]='Holiday' THEN 1 ELSE 0 END) Holiday
			,SUM(CAST(IsOnTime AS INT)) OnTime, SUM(CAST(IsLateIn AS INT)) LateIn, SUM(CAST(IsHalfDay AS INT)) HalfDay,SUM(CAST(EarlyOut AS INT)) EarlyOut
			,SUM(InEdit) AS InEdit,SUM(OutEdit) AS OutEdit
			,SUM(TWorkMinutes) TWorkMinutes,SUM(TWorkAsPerRosterMinutes) TWorkAsPerRosterMinutes,SUM(TShortExcessMinutes) TShortExcessMinutes,SUM(LateInMinutes) AS LateInMinutes,SUM(DeductionTotalMinutes) AS DeductionMinutes 
			,SUM(ShortWorkingHourMinutes) ShortWorkingMinutes,SUM(TOverTimeMinutes) AS TOverTimeMinutes,SUM(LateInMinutes) AS LateInMinutes,SUM(DeductionTotalMinutes) AS DeductionMinutes
			,SUM(TWorkMinutes)/60 AS TWorkHours,SUM(TWorkAsPerRosterMinutes)/60 AS TWorkAsPerRosterHours,SUM(TShortExcessMinutes)/60 AS TShortExcessHours,SUM(TOverTimeMinutes)/60 AS TOverTimeHours
			FROM #tmpAttData01_2 a
			GROUP BY AttMonth,FORMAT(AttMonth,'yyyy'), FORMAT(AttMonth,'MMM'),
			CompanyBranch,CompanyBranchSN,Department,DepartmentSN,Designation,DesignationSN,
			EmployeeInformationId, EmployeeCode, MachineCode,EmployeeName,
			GenderTypeId,Gender,GenderSN,
			(CASE WHEN YEAR(AttMonth)=YEAR(@ToDate) AND MONTH(AttMonth)=MONTH(@ToDate) THEN DATEDIFF(D,@FromDate,@ToDate)+(CASE WHEN @TimeBoundConfig='2' THEN 0 ELSE 1 END) ELSE DAY(EOMONTH(AttMonth)) END)
		
			SELECT * FROM #tmpAttData01_2 WHERE InEdit=1 OR OutEdit=1	
		END		


	IF OBJECT_ID('tempdb..#EMPDR1') IS NOT NULL	DROP TABLE #EMPDR1
	IF OBJECT_ID('tempdb..#tmpCompanyBranch2') IS NOT NULL		DROP TABLE #tmpCompanyBranch2
	IF OBJECT_ID('tempdb..#tmpDepartment2') IS NOT NULL		DROP TABLE #tmpDepartment2
	IF OBJECT_ID('tempdb..#TmpAttData01') IS NOT NULL		DROP TABLE #TmpAttData01
	IF OBJECT_ID('tempdb..#TmpAttData01_2') IS NOT NULL		DROP TABLE #TmpAttData01_2
	IF OBJECT_ID('tempdb..#Employee') IS NOT NULL	DROP TABLE #Employee

END

IF @Type=3--Transfer Analysis
BEGIN
--References: ['TSBE.Manager.Dashboard.HRManager.HRAnalysis_Transfer']	
--DECLARE @FromDate DATETIME='2021-01-01'
--DECLARE @ToDate DATETIME='2021-08-17'
--DECLARE @DepartmentIds NVARCHAR(MAX)=''
--DECLARE @DesignationIds NVARCHAR(MAX)=''
--DECLARE @CompanyBranchIds NVARCHAR(MAX)=''
--DECLARE @CompanyBranchIds_To NVARCHAR(MAX)=''
--DECLARE @JobStatusIds NVARCHAR(MAX)=''
--DECLARE @EmployeeInformationIds NVARCHAR(MAX)='15400022,68'

IF OBJECT_ID('tempdb..#BranchHistory') IS NOT NULL DROP TABLE #BranchHistory
IF OBJECT_ID('tempdb..#EmpBranchData') IS NOT NULL DROP TABLE #EmpBranchData
IF OBJECT_ID('tempdb..#EmpHistory') IS NOT NULL DROP TABLE #EmpHistory
IF OBJECT_ID('tempdb..#EmpHistory2') IS NOT NULL DROP TABLE #EmpHistory2
IF OBJECT_ID('tempdb..#joinDated') IS NOT NULL DROP TABLE #joinDated
IF OBJECT_ID('tempdb..#EmpStatus') IS NOT NULL DROP TABLE #EmpStatus		

DECLARE @fltr_EmployeeInformation TABLE(Id INT)
DECLARE @fltr_Department TABLE(Id INT)
DECLARE @fltr_Designation TABLE(Id INT)
DECLARE @fltr_CompanyBranchFrom TABLE(Id INT)
DECLARE @fltr_CompanyBranchTo TABLE(Id INT)
DECLARE @fltr_JobStatus TABLE(Id INT)

INSERT INTO @fltr_EmployeeInformation SELECT Ids FROM dbo.SetTempHashValues(@EmployeeInformationIds)
INSERT INTO @fltr_Department SELECT Ids FROM dbo.SetTempHashValues(@DepartmentIds)
INSERT INTO @fltr_Designation SELECT Ids FROM dbo.SetTempHashValues(@DesignationIds)
INSERT INTO @fltr_CompanyBranchFrom SELECT Ids FROM dbo.SetTempHashValues(@CompanyBranchIds)
INSERT INTO @fltr_CompanyBranchTo SELECT Ids FROM dbo.SetTempHashValues(@CompanyBranchIds_To)
IF @JobStatusIds=''
BEGIN
INSERT INTO @fltr_JobStatus SELECT JobStatusId FROM JobStatus AS js WHERE js.JobStatusId NOT IN(3,4)
END
ELSE
	BEGIN
	INSERT INTO @fltr_JobStatus SELECT Ids FROM dbo.SetTempHashValues(@JobStatusIds)	
	END
	
SELECT	eb.EmployeeInformationId, eb.CompanyBranchId, eb.AssignDate,  eb.EmployeeBranchId, eb.UserId DataEntryUserId,eb.DataEntryDate,
		DENSE_RANK() OVER (PARTITION BY eb.EmployeeInformationId ORDER BY eb.AssignDate,eb.EmployeeBranchId desc) SortOrder 
		INTO #EmpBranchData
FROM EmployeeBranch eb 
WHERE eb.DataEntryStatus=1 AND eb.AssignDate BETWEEN @FromDate AND @ToDate AND
CASE WHEN @EmployeeInformationIds='' THEN 0 ELSE EmployeeInformationId END IN (SELECT ids FROM dbo.SetTempHashValues(@employeeInformationIds) AS sthv)

SELECT	a.SortOrder,a.EmployeeInformationId, a.CompanyBranchId,b.CompanyBranchId AS ToCompanyBranchId, a.EmployeeBranchId, a.DataEntryUserId,a.AssignDate FromDate, 
		a.DataEntryDate,ISNULL(b.AssignDate,@ToDate) ToDate 
		INTO #BranchHistory 
FROM #EmpBranchData a
LEFT JOIN #EmpBranchData b ON a.EmployeeInformationId=b.EmployeeInformationId AND a.SortOrder+1=b.SortOrder	
WHERE a.companybranchid<>ISNULL(b.companybranchid,0)

SELECT	DISTINCT ei.EmployeeInformationId, ei.EmployeeCode, ei.MachineCode, Isnull(ei.FirstName,'')+' '+ISNULL(ei.MiddleName,'')+' '+ ISNULL(ei.LastName,'') Employee,--eb.SortOrder AS NoofTransfer,
		cb.CompanyBranchId,cbTo.CompanyBranchId AS CompanyBranchId_To,cb.LongName AS CompanyBranch,cb.ShortName AS CompanyBranchSN,cbTo.LongName AS CompanyBranch_To,cbTo.ShortName AS CompanyBranchSN_To,FromDate,ToDate
		,CASE WHEN DATEDIFF(day, FromDate, ToDate)/365>0 THEN CAST(DATEDIFF(day, FromDate, ToDate)/365 AS VARCHAR(4)) +'Y ' ELSE '' END +
		CASE WHEN (DATEDIFF(day, FromDate,ToDate)%365)/30>0 THEN CAST((DATEDIFF(day, FromDate,ToDate)%365)/30 AS VARCHAR(4))+'M ' ELSE '' END +
		CAST((DATEDIFF(d, FromDate,ToDate)%365)%30 AS VARCHAR(4))+'D' AS Duration,eb.DataEntryUserId,DATEDIFF(day, FromDate, ToDate) AS DurationDays,SortOrder
		INTO #EmpHistory
FROM	EmployeeInformation AS ei
		Inner JOIN	#BranchHistory AS eb ON eb.EmployeeInformationId = ei.EmployeeInformationId 
		Inner JOIN CompanyBranch AS cb ON cb.CompanyBranchId = eb.CompanyBranchId
		LEFT JOIN CompanyBranch AS cbTo ON  eb.ToCompanyBranchId= cbTo.CompanyBranchId

SELECT * INTO 
#EmpStatus FROM  (
SELECT	ejs.EmployeeInformationId, ejs.JobStatusId, ejs.AssignDate, ejs.DataEntryDate,
		DENSE_RANK()OVER (PARTITION BY Ejs.EmployeeInformationId ORDER BY ejs.AssignDate DESC,ejs.dataentrydate DESC,EmployeeJobStatusId DESC) SortOrder,
		Max(CASE WHEN ejs.JobStatusId Not IN (3,4) THEN ejs.EmployeeJobStatusId ELSE NULL END )OVER (PARTITION BY Ejs.EmployeeInformationId,
		CASE WHEN ejs.JobStatusId IN (3,4) THEN 0 ELSE 1 end ORDER BY ejs.AssignDate DESC,ejs.dataentrydate DESC,EmployeeJobStatusId DESC) ReJoinId,
		MAX(CASE WHEN ejs.JobStatusId IN (3,4) THEN 1 ELSE 0 END) OVER (PARTITION BY Ejs.EmployeeInformationId) ResignStatus,
		Max(CASE WHEN ejs.JobStatusId Not IN (3,4) THEN ejs.EmployeeJobStatusId ELSE 0 end)OVER (PARTITION BY Ejs.EmployeeInformationId) ProbationStatusId
FROM	EmployeeJobStatus AS ejs
INNER JOIN (SELECT DISTINCT EmployeeInformationId FROM #EmpHistory) E ON ejs.EmployeeInformationId=e.EmployeeInformationId
WHERE	ejs.DataEntryStatus=1 AND CASE WHEN @EmployeeInformationIds='' THEN '' ELSE ejs.EmployeeInformationId END 
		IN (SELECT ids FROM dbo.SetTempHashValues(@EmployeeInformationIds) AS sthv)) a
WHERE a.SortOrder=1


SELECT	es.EmployeeInformationId,es.JobStatusId,CASE WHEN es.ResignStatus=1 THEN ISNULL(rj.AssignDate, pj.AssignDate) ELSE pj.AssignDate END JoinDate 
INTO #joinDated
FROM		#EmpStatus es
LEFT JOIN	EmployeeJobStatus AS rj ON es.ReJoinId=rj.EmployeeJobStatusId
LEFT JOIN	EmployeeJobStatus AS pj ON es.ProbationStatusId=pj.EmployeeJobStatusId

SELECT ei.EmployeeInformationId, ei.EmployeeCode, ei.MachineCode, Employee,ISNULL(d.Name,'NA') AS Designation,ISNULL(ISNULL(d.ShortName,d.Name),'NA') DesignationSN,js.Name JobStatus,ISNULL(js.ShortName,js.Name) AS JobStatusSN,JoinDate
,ei.CompanyBranchId,CompanyBranch,CompanyBranchSN,CompanyBranchId_To,CompanyBranch_To,CompanyBranchSN_To,ISNULL(dep.Name,'NA') AS Department,ISNULL(dep.ShortName,'NA') AS DepartmentSN,FromDate,ToDate,Duration,DurationDays,
		Isnull(ei2.FirstName,'')+' '+ISNULL(ei2.MiddleName,'')+' '+ ISNULL(ei2.LastName,'') DataEntryUser,(CASE WHEN ei.CompanyBranchId_To IS NULL THEN 0 ELSE ei.SortOrder END) AS TransferCount,
		SUM(CASE WHEN ei.CompanyBranchId_To IS NULL OR ei.CompanyBranchId=ei.CompanyBranchId_To THEN 0 ELSE 1 END) OVER(PARTITION BY Ei.EmployeeInformationId) AS TotalTransferCount
		,FORMAT(FromDate,'MMMyy') AS TransferInMonth,FORMAT(ToDate,'MMMyy') AS TransferOutMonth
		,CAST(FORMAT(FromDate,'yy')+FORMAT(FromDate,'MM') AS INT) AS TransferInMonthNum, CAST(FORMAT(ToDate,'yy')+FORMAT(ToDate,'MM') AS INT) AS TransferOutMonthNum
INTO #EmpHistory2
FROM #EmpHistory Ei
left JOIN #joinDated jd ON jd.EmployeeInformationId=ei.EmployeeInformationId
LEFT JOIN JobStatus AS js ON js.JobStatusId=jd.JobStatusId
LEFT JOIN (SELECT EmployeeDesignationId,ed.EmployeeInformationId,DesignationId,AssignDate,
                  DENSE_RANK() OVER(PARTITION BY ed.EmployeeInformationId ORDER by AssignDate DESC,ed.EmployeeDesignationId DESC) SortOrder
             FROM EmployeeDesignation ed
		  ) AS ed ON ed.EmployeeInformationId=ei.EmployeeInformationId  AND ed.SortOrder=1 
LEFT JOIN Designation AS d ON d.DesignationId = ed.DesignationId
LEFT JOIN (SELECT EmployeeDepartmentId,EmployeeInformationId,DepartmentId,AssignDate,
                  DENSE_RANK() OVER(PARTITION BY EmployeeInformationId ORDER by AssignDate DESC,EmployeeDepartmentId DESC) SortOrder
             FROM EmployeeDepartment
		  ) AS edep ON ei.EmployeeInformationId=edep.EmployeeInformationId AND edep.SortOrder=1 
LEFT JOIN Department AS dep ON edep.DepartmentId=dep.DepartmentId
LEFT JOIN [User] AS u ON u.UserId = ei.DataEntryUserId
LEFT JOIN EmployeeInformation AS ei2 ON u.EmployeeInformationId=ei2.EmployeeInformationId
INNER JOIN @fltr_EmployeeInformation AS fei ON CASE WHEN @EmployeeInformationIds='' THEN 0 ELSE Ei.EmployeeInformationId END=fei.Id
INNER JOIN @fltr_Department AS fdep ON CASE WHEN @DepartmentIds='' THEN 0 ELSE edep.DepartmentId END=fdep.Id
INNER JOIN @fltr_Designation AS fd ON CASE WHEN @DesignationIds='' THEN 0 ELSE ed.DesignationId END=fd.Id
INNER JOIN @fltr_CompanyBranchFrom AS fcb ON CASE WHEN @CompanyBranchIds='' THEN 0 ELSE Ei.CompanyBranchId END=fcb.Id
INNER JOIN @fltr_CompanyBranchTo AS fcb2 ON CASE WHEN @CompanyBranchIds_To='' THEN 0 ELSE Ei.CompanyBranchId_To END=fcb2.Id
INNER JOIN @fltr_JobStatus AS fjs ON js.JobStatusId=fjs.Id
ORDER BY EmployeeInformationId,FromDate

SELECT a.*,b.EmployeeCount,1 AS CountIn,(CASE WHEN CompanyBranchId_To IS NULL THEN 0 ELSE 1 END) AS CountOut,(CASE WHEN CompanyBranchId_To IS NOT NULL THEN 0 ELSE 1 END) AS CountOut2
FROM #EmpHistory2 AS a
INNER JOIN (SELECT CompanyBranchId,COUNT(DISTINCT EmployeeInformationId) AS EmployeeCount
FROM #EmpHistory2 AS b
GROUP BY CompanyBranchId) AS b ON a.CompanyBranchId=b.CompanyBranchId
ORDER BY a.TotalTransferCount DESC,a.EmployeeInformationId,FromDate
	
IF OBJECT_ID('tempdb..#BranchHistory') IS NOT NULL DROP TABLE #BranchHistory
IF OBJECT_ID('tempdb..#EmpBranchData') IS NOT NULL DROP TABLE #EmpBranchData
IF OBJECT_ID('tempdb..#EmpHistory') IS NOT NULL DROP TABLE #EmpHistory
IF OBJECT_ID('tempdb..#EmpHistory2') IS NOT NULL DROP TABLE #EmpHistory2
IF OBJECT_ID('tempdb..#joinDated') IS NOT NULL DROP TABLE #joinDated
IF OBJECT_ID('tempdb..#EmpStatus') IS NOT NULL DROP TABLE #EmpStatus
END

ELSE IF(@Type=4)--Employee--ToDo: Add more details like references, attachements etc, roster (next 30 days)
--Reference: ['TSBE.Manager.Dashboard.HRManager.Employee']
BEGIN

--DECLARE @FromDate AS DATETIME='2021-04-14';--ToDo: Implement
--DECLARE @ToDate DATETIME=NULL
--DECLARE @EmployeeInformationId INT=74
SET @ToDate=GETDATE()

--BEGIN: Job Status History
;WITH cteEJSHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, JobStatusId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeJobStatus H WHERE DataEntryStatus=1 AND H.EmployeeInformationId=@EmployeeInformationId)

SELECT	a.EmployeeInformationId, a.DimId,d.ShortName AS DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpJobStatusHist
FROM cteEJSHistSrc AS a
LEFT JOIN cteEJSHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN JobStatus AS d ON a.DimId=d.JobStatusId
--END: Job Status History

SELECT
EI.EmployeeInformationId,
EI.EmployeeCode,
EI.MachineCode,
RTRIM(LTRIM(RTRIM(LTRIM(RTRIM(LTRIM(ISNULL(EI.FirstName,''))) + ' ' + RTRIM(LTRIM(ISNULL(EI.MiddleName,''))))) + ' ' + RTRIM(LTRIM(ISNULL(EI.LastName,''))))) AS EmployeeName,
EI.FatherName,
EI.MotherName,
EI.HusbandName,
EI.GenderTypeId,
ISNULL(GT.GenderShortName,'M') AS GenderShortName,ISNULL(GT.GenderLongName,'Male') AS Gender,
EI.MeritalStatusId,ISNULL(MS.StatusShortName,'S') AS MaritalStausSN,ISNULL(MS.StatusLongName,'Single') AS MaritalStatus,
ISNULL(R.ReligionName,'Muslim') AS Religion,
EI.CNIC,FORMAT(EI.NICExpiryDate,'yyyy-MM-dd') as NICExpiryDate,FORMAT(EI.NICIssuanceDate,'yyyy-MM-dd') as NICIssuanceDate ,EI.NTN,EI.EOBINumber,
EI.DateOfBirth,
DATEDIFF(YEAR,ISNULL(EI.DateOfBirth, DATEADD(YEAR,-18,@ToDate)),@ToDate) AS Age,
DBO.Age(EI.DateOfBirth,@ToDate) AS Age2,
EI.PlaceOfBirth AS PlaceOfBirthId, C.CityShortName PlaceOfBirthSN,C.CityLongName AS PlaceOfBirth,
EI.MotherTongueId, ISNULL(L.ShortName,'Urdu') AS MotherTongueSN,ISNULL(L.Name,'Urdu') AS MotherTongue,
EI.BloodGroupId,BG.[Name] AS BloodGroup,
EJS.StartDate AS JoinDate,
--DBO.Time_GetDateDiff('D','YEAR',EJS.StartDate,@ToDate) AS ServiceLength,Miscalcl
DATEDIFF(DAY,EJS.StartDate,@ToDate)/365.25 AS ServiceLength,
DBO.Age(EJS.StartDate,@ToDate) AS ServiceLength2
--Training History
,eimg.ImageBlock,eimg.[Signature]
--,EI.*
FROM EmployeeInformation EI
LEFT JOIN GenderType AS GT ON EI.GenderTypeId=GT.GenderTypeId
LEFT JOIN MeritalStatus AS MS ON EI.MeritalStatusId=MS.MeritalStatusId
LEFT JOIN Religion AS R ON EI.ReligionId=R.ReligionId
LEFT JOIN [Language] AS L ON EI.MotherTongueId=L.LanguageId
LEFT JOIN BloodGroup AS BG ON EI.BloodGroupId=BG.BloodGroupId
LEFT JOIN City AS C ON EI.PlaceOfBirth=C.CityId
INNER JOIN #tmpJobStatusHist AS EJS ON EI.EmployeeInformationId=EJS.EmployeeInformationId AND EJS.SortOrder=1
LEFT JOIN EmployeeImage AS eimg ON ei.EmployeeInformationId=eimg.EmployeeInformationId AND ei.DataEntryStatus=1
WHERE EI.EmployeeInformationId= @EmployeeInformationId

;WITH cteEJSHistSrc2(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, JobStatusId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeJobStatus H WHERE DataEntryStatus=1 AND H.EmployeeInformationId=@EmployeeInformationId)
--BEGIN: Branch History
,cteEBHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, CompanyBranchId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeBranch H WHERE DataEntryStatus=1 AND H.EmployeeInformationId=@EmployeeInformationId)
--END: Branch History

--BEGIN: Department History
,cteEDHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, DepartmentId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeDepartment H WHERE DataEntryStatus=1 AND H.EmployeeInformationId=@EmployeeInformationId)
--END: Department History

--BEGIN: Designation History
,cteEDesHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, DesignationId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeDesignation H WHERE DataEntryStatus=1 AND H.EmployeeInformationId=@EmployeeInformationId)
--END: Designation History

SELECT 'Job Status' AS Head,	a.EmployeeInformationId, a.DimId,d.ShortName AS DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
FROM cteEJSHistSrc2 AS a
LEFT JOIN cteEJSHistSrc2 AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN JobStatus AS d ON a.DimId=d.JobStatusId
UNION ALL
SELECT 'Company Branch' AS Head, a.EmployeeInformationId,a.DimId,d.ShortName AS DimShortName,d.[LongName] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
FROM cteEBHistSrc AS a
LEFT JOIN cteEBHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN CompanyBranch AS d ON a.DimId=d.CompanyBranchId
UNION ALL
SELECT 'Department' AS Head, a.EmployeeInformationId, a.DimId, d.ShortName AS DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
FROM cteEDHistSrc AS a
LEFT JOIN cteEDHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN Department AS d ON a.DimId=d.DepartmentId
UNION ALL
SELECT 'Designation' AS Head, a.EmployeeInformationId, a.DimId,d.ShortName DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
FROM cteEDesHistSrc AS a
LEFT JOIN cteEDesHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN Designation AS d ON a.DimId=d.DesignationId

SELECT 'Education' AS Head, h.EmployeeInformationId, h.AssignDate AS EndDate, ISNULL(d.ShortName,d.[Name]) AS Education
,RANK() OVER (PARTITION BY h.EmployeeQualificationId ORDER BY h.AssignDate DESC) AS SortOrder
FROM EmployeeQualification AS h
INNER JOIN Qualification AS d ON h.QualificationId=d.QualificationId
WHERE h.DataEntryStatus=1 AND h.EmployeeInformationId=@EmployeeInformationId
 
SELECT 'Experience' AS Head, EmployeeInformationId,FromDate AS StartDate, ToDate AS EndDate, Organization,Designation,Salary,ISNULL(c.ShortName,c.LongName) AS Currency
,RANK() OVER (PARTITION BY EmployeeExperienceId ORDER BY ToDate DESC) AS SortOrder 
FROM EmployeeExperience H
INNER JOIN Currency AS c ON h.CurrencyId=H.CurrencyId
 WHERE h.DataEntryStatus=1 AND H.EmployeeInformationId=@EmployeeInformationId

--Contact
SELECT cn.EmployeeInformationId,cn.ContactNo,ct.LongName as ContactTypeName,cn.DefaultNumber AS IsDefault,cn.IsSendSMS,cn.IsSendEmail, ct.ContactTypeParent
FROM ContactNumber AS cn
INNER JOIN ContactType AS ct ON cn.ContactTypeId=ct.ContactTypeId
WHERE cn.DataEntryStatus=1 AND cn.EmployeeInformationId=@EmployeeInformationId
ORDER BY cn.DefaultNumber,cn.DataEntryDate
--Address

SELECT ca.EmployeeInformationId,ca.[Address] AS StreetAddress,car.AreaLongName AS Area,c.CityLongName AS City,c2.CountryLongName AS Country,ca.DefaultAddress AS IsDefault
  FROM ContactAddress ca
INNER JOIN AddressType at ON ca.AddressTypeId=at.AddressTypeId
INNER JOIN CityArea AS car ON ca.CityAreaId=car.CityAreaId
INNER JOIN City AS c ON car.CityId=c.CityId
INNER JOIN Country AS c2 ON c.CountryId=c2.CountryId
WHERE ca.EmployeeInformationId=@EmployeeInformationId
ORDER BY ca.DefaultAddress,ca.DataEntryDate

----BEGIN: Salary History
--;WITH cteESalHistSrc(EmployeeInformationId, AssignDate,CalcBase,DimId,DimShortName,DimName,Amount,SortOrder) AS (
----Patch not updated: SELECT H.EmployeeInformationId, H.AssignDate,(CASE WHEN SS.SalaryTypeId=1 THEN 'Basic' ELSE (CASE WHEN ST.CalculationCriteria BETWEEN 11 AND 20 THEN 'Addition' WHEN ST.CalculationCriteria BETWEEN 31 AND 40 THEN 'Deduction' END) END) AS CalcBase, 
--SELECT H.EmployeeInformationId, H.AssignDate,(CASE WHEN SS.SalaryTypeId=1 THEN 'Basic' WHEN SS.SalaryTypeId IN (2,6,9,26,27,11,13,16,20,22,24) THEN 'Addition' WHEN SS.SalaryTypeId IN (3,7,8,10,25,4,5,12,17,18,19,21,23,28) THEN 'Deduction'  END) AS CalcBase, 
--SS.SalaryTypeId AS DimId,ST.ShortName AS DimShortName,ST.[Name] AS DimName,H.Amount, RANK() OVER (PARTITION BY H.EmployeeInformationId,H.SalaryStructureId ORDER BY H.AssignDate DESC, H.DataEntryDate DESC) AS SortOrder 
--FROM EmployeeSalaryStructure H 
--LEFT JOIN SalaryStructure SS ON ss.SalaryStructureId = H.SalaryStructureId
--LEFT JOIN SalaryType ST ON st.SalaryTypeId = ss.SalaryTypeId
--WHERE H.DataEntryStatus=1 AND H.EmployeeInformationId=@EmployeeInformationId)

----SELECT * FROM cteESalHistSrc

--SELECT	a.EmployeeInformationId,0 AS DimId,CAST(SUM(a.Amount) AS VARCHAR) AS DimShortName,CAST(SUM(a.Amount) AS VARCHAR) AS DimName,
--MIN(a.AssignDate) StartDate, (CASE WHEN MIN(b.AssignDate) IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,MIN(b.AssignDate)) END) AS EndDate,a.SortOrder
--FROM cteESalHistSrc AS a
--LEFT JOIN cteESalHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
--GROUP BY a.EmployeeInformationId,a.AssignDate,a.SortOrder
----END: Salary History

DROP TABLE #tmpJObStatusHist

END

IF @Type=5--Turnover
BEGIN

-- DECLARE @FromDate AS DATETIME='2022-01-01';
-- DECLARE @ToDate DATETIME=GETDATE()
-- DECLARE @CompanyBranchIds NVARCHAR(MAX)='';
-- DECLARE @DepartmentIds NVARCHAR(MAX)='';
-- DECLARE @DesignationIds NVARCHAR(MAX)='';
-- DECLARE @GenderTypeIds NVARCHAR(MAX)='';
-- DECLARE @GetEmployees INT=0
-- DECLARE @GetKeysFromName BIT=0
-- DECLARE @EmployementStatus NVARCHAR(20)=''


IF OBJECT_ID('tempdb..#tmpCompanyBranch_5') IS NOT NULL DROP TABLE #tmpCompanyBranch_5
IF OBJECT_ID('tempdb..#tmpDepartment_5') IS NOT NULL DROP TABLE #tmpDepartment_5
IF OBJECT_ID('tempdb..#tmpDepartment_5') IS NOT NULL DROP TABLE #tmpDepartment_5
IF OBJECT_ID('tempdb..#tmpDesignation_5') IS NOT NULL DROP TABLE #tmpDesignation_5
IF OBJECT_ID('tempdb..#tmpGenderType_5') IS NOT NULL DROP TABLE #tmpGenderType_5

IF OBJECT_ID('tempdb..#EmpJobStatusHist_5') IS NOT NULL DROP TABLE #EmpJobStatusHist_5
IF OBJECT_ID('tempdb..#EmpJobStatusHist_5_0') IS NOT NULL DROP TABLE #EmpJobStatusHist_5_0
IF OBJECT_ID('tempdb..#tmpEmpBranchHist_5') IS NOT NULL DROP TABLE #tmpEmpBranchHist_5
IF OBJECT_ID('tempdb..#tmpEmpDepartmentHist_5') IS NOT NULL DROP TABLE #tmpEmpDepartmentHist_5
IF OBJECT_ID('tempdb..#tmpEmpDesignationHist_5') IS NOT NULL DROP TABLE #tmpEmpDesignationHist_5
IF OBJECT_ID('tempdb..#tmpEmpEducationHist_5') IS NOT NULL DROP TABLE #tmpEmpEducationHist_5
IF OBJECT_ID('tempdb..#tmpData') IS NOT NULL DROP TABLE #tmpData


CREATE TABLE #tmpCompanyBranch_5(CompanyBranchId INT,LongName NVARCHAR(200),ShortName NVARCHAR(50))
CREATE TABLE #tmpDepartment_5(DepartmentId INT,[Name] NVARCHAR(200),ShortName NVARCHAR(50))
CREATE TABLE #tmpDesignation_5(DesignationId INT,[Name] NVARCHAR(200),ShortName NVARCHAR(50))
CREATE TABLE #tmpGenderType_5(GenderTypeId INT,GenderLongName NVARCHAR(200),GenderShortName NVARCHAR(50))

IF @GetKeysFromName=1
BEGIN
	INSERT INTO #tmpCompanyBranch_5
	SELECT CompanyBranchId,LongName,ShortName
	FROM CompanyBranch
	WHERE CASE WHEN @CompanyBranchIds = '' THEN '' ELSE ShortName END IN (SELECT Ids FROM dbo.SetTempHashStringValues(1,@CompanyBranchIds,',') AS sthv)
	
	INSERT INTO #tmpDepartment_5
	SELECT DepartmentId,[Name],ShortName
	FROM Department
	WHERE CASE WHEN @DepartmentIds = '' THEN '' ELSE ShortName END IN (SELECT Ids FROM dbo.SetTempHashStringValues(1,@DepartmentIds,',') AS sthv)

	INSERT INTO #tmpDesignation_5
	SELECT DesignationId,[Name],ShortName
	FROM Designation
	WHERE CASE WHEN @DesignationIds = '' THEN '' ELSE ShortName END IN (SELECT Ids FROM dbo.SetTempHashStringValues(1,@DesignationIds,',') AS sthv)

	INSERT INTO #tmpGenderType_5
	SELECT GenderTypeId,GenderLongName,GenderShortName
	FROM GenderType
	WHERE CASE WHEN @GenderTypeIds = '' THEN '' ELSE ISNULL(GenderShortName,'M') END IN (SELECT Ids FROM dbo.SetTempHashStringValues(1,@GenderTypeIds,',') AS sthv)
END
ELSE
	BEGIN
	INSERT INTO #tmpCompanyBranch_5
	SELECT CompanyBranchId,LongName,ShortName
	FROM CompanyBranch
	WHERE CASE WHEN @CompanyBranchIds = '' THEN 0 ELSE CompanyBranchId END IN (SELECT Ids FROM dbo.SetTempHashValues(@CompanyBranchIds) AS sthv)

	INSERT INTO #tmpDepartment_5
	SELECT DepartmentId,[Name],ShortName
	FROM Department
	WHERE CASE WHEN @DepartmentIds = '' THEN 0 ELSE DepartmentId END IN (SELECT Ids FROM dbo.SetTempHashValues(@DepartmentIds) AS sthv);

	INSERT INTO #tmpDesignation_5
	SELECT DesignationId,[Name],ShortName
	FROM Designation
	WHERE CASE WHEN @DesignationIds = '' THEN 0 ELSE DesignationId END IN (SELECT Ids FROM dbo.SetTempHashValues(@DesignationIds) AS sthv);

	INSERT INTO #tmpGenderType_5
	SELECT GenderTypeId,GenderLongName,GenderShortName
	FROM GenderType
	WHERE CASE WHEN @GenderTypeIds = '' THEN 0 ELSE GenderTypeId END IN (SELECT Ids FROM dbo.SetTempHashValues(@GenderTypeIds) AS sthv);
	END

--BEGIN: Job Status History
--BEGIN: Refining for garbage data eg Firing before hiring: EmployeeInformationId=237947,163540
;WITH cteEJSHistSrc(EmployeeJobStatusId,EmployeeInformationId, AssignDate, JobStatusId,DataEntryDate,SortOrder) AS (
SELECT h.EmployeeJobStatusId,h.EmployeeInformationId, h.AssignDate, CASE WHEN h.JobStatusId= 4 THEN 3 else h.JobStatusId END JobStatusId,h.DataEntryDate, 
		DENSE_RANK() OVER (PARTITION BY h.EmployeeInformationId ORDER BY h.AssignDate ,h.DataEntryDate) AS SortOrder
FROM EmployeeJobStatus H 
INNER JOIN ViewEmployeeInformation AS vei ON vei.EmployeeInformationId = h.EmployeeInformationId
WHERE CASE WHEN h.JobStatusId NOT IN (3,4) then h.AssignDate ELSE vei.JoiningDate end<=vei.JoiningDate
and h.DataEntryStatus=1
--and h.EmployeeInformationId=2007
)

SELECT a.EmployeeJobStatusId, a.EmployeeInformationId, a.JobStatusId,a.AssignDate,b.JobStatusId AS End_JobStatusId,b.EmployeeJobStatusId AS End_EmployeeJobStatusId,a.DataEntryDate,a.SortOrder
INTO #EmpJobStatusHist_5_0
FROM cteEJSHistSrc AS a
LEFT JOIN cteEJSHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder=b.SortOrder+1

--END: Refining for garbage data eg Firing before hiring: EmployeeInformationId=237947,163540

;WITH cteEJSHistSrc2(EmployeeJobStatusId,EmployeeInformationId, AssignDate, JobStatusId,SortOrder,End_JobStatusId) AS (
SELECT EmployeeJobStatusId,EmployeeInformationId, AssignDate, JobStatusId, DENSE_RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC ,DataEntryDate DESC) AS SortOrder,End_JobStatusId
FROM #EmpJobStatusHist_5_0 H
WHERE JobStatusId<>CASE WHEN SortOrder=1 AND JobStatusId IN(3,4) THEN End_JobStatusId ELSE ISNULL(End_JobStatusId,0) END)

SELECT a.EmployeeJobStatusId, a.EmployeeInformationId, a.JobStatusId AS DimId,d.ShortName AS DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, ISNULL(DATEADD(ms,-2,b.AssignDate),'2999-12-31 23:59:59') AS EndDate,a.SortOrder,a.End_JobStatusId
INTO #EmpJobStatusHist_5
FROM cteEJSHistSrc2 AS a
LEFT JOIN cteEJSHistSrc2 AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder=b.SortOrder+1
INNER JOIN JobStatus AS d ON a.JobStatusId=d.JobStatusId




--declare @e int=163540
--Select * from EmployeeJobStatus WHERE EmployeeInformationId=@e and dataentrystatus=1 order by AssignDate,dataentrydate
--Select * FROM #EmpJobStatusHist_5_0 WHERE EmployeeInformationId=@e
--SELECT * FROM #EmpJobStatusHist_5 WHERE EmployeeInformationId=@e
--END: Job Status History


--BEGIN: Branch History
;WITH cteEBHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, CompanyBranchId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeBranch H WHERE DataEntryStatus=1)
SELECT	a.EmployeeInformationId,a.DimId,d.ShortName AS DimShortName,d.[LongName] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59.999' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpBranchHist_5
FROM cteEBHistSrc AS a
LEFT JOIN cteEBHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN #tmpCompanyBranch_5 AS d ON a.DimId=d.CompanyBranchId
--END: Branch History

--BEGIN: Department History
;WITH cteEDHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, DepartmentId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeDepartment H WHERE DataEntryStatus=1)
SELECT	a.EmployeeInformationId, a.DimId, d.ShortName AS DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59.999' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpDepartmentHist_5
FROM cteEDHistSrc AS a
LEFT JOIN cteEDHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN #tmpDepartment_5 AS d ON a.DimId=d.DepartmentId
--END: Department History

--BEGIN: Designation History
;WITH cteEDesHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, DesignationId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeDesignation H WHERE DataEntryStatus=1)
SELECT	a.EmployeeInformationId, a.DimId,d.ShortName DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59.999' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpDesignationHist_5
FROM cteEDesHistSrc AS a
LEFT JOIN cteEDesHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN Designation AS d ON a.DimId=d.DesignationId
--END: Designation History

--BEGIN: Education History
;WITH cteEEduHistSrc(EmployeeInformationId, AssignDate,DimId,SortOrder) AS (
SELECT EmployeeInformationId, AssignDate, QualificationId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
FROM EmployeeQualification H WHERE DataEntryStatus=1)
SELECT	a.EmployeeInformationId, a.DimId,d.ShortName DimShortName,d.[Name] As DimName,
a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59.999' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
INTO #tmpEmpEducationHist_5
FROM cteEEduHistSrc AS a
LEFT JOIN cteEEduHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
INNER JOIN Qualification AS d ON a.DimId=d.QualificationId
--END: Qualification History

--ToThink: @M.Jahanzaib: Should show department, branch etc with respect to cut-off date/@ToDate?
SELECT h.*
,ed.DimId AS DepartmentId,ed.DimName AS Department, (CASE WHEN ISNULL(ed.DimshortName,'')='' THEN ed.DimName ELSE ed.DimshortName END) AS DepartmentSN
,eb.DimId AS CompanyBranchId,eb.DimName AS CompanyBranch, (CASE WHEN ISNULL(eb.DimshortName,'')='' THEN eb.DimName ELSE eb.DimshortName END) AS CompanyBranchSN
,edes.DimId AS DesignationId,edes.DimName AS Designation, (CASE WHEN ISNULL(edes.DimshortName,'')='' THEN edes.DimName ELSE edes.DimshortName END) AS DesignationSN
,EI.GenderTypeId,ISNULL(GT.GenderLongName,'Male') AS Gender, (CASE WHEN ISNULL(GT.GenderShortName,'')='' THEN 'M' ELSE GT.GenderShortName END) AS GenderSN
,EE.DimId AS QualificationId,EE.DimName AS Education, (CASE WHEN ISNULL(EE.DimShortName,'')='' THEN EE.DimName ELSE EE.DimShortName END) AS EducationSN
,NULL AS [Status]
INTO #tmpData
FROM #EmpJobStatusHist_5 AS h
INNER JOIN #tmpEmpDepartmentHist_5 AS ED ON h.EmployeeInformationId=ED.EmployeeInformationId AND ED.SortOrder=1
INNER JOIN #tmpEmpDesignationHist_5 AS EDes ON h.EmployeeInformationId=EDes.EmployeeInformationId AND EDes.SortOrder=1
INNER JOIN #tmpEmpBranchHist_5 AS EB ON h.EmployeeInformationId=EB.EmployeeInformationId AND EB.SortOrder=1
INNER JOIN EmployeeInformation AS ei ON h.EmployeeInformationId=ei.EmployeeInformationId
INNER JOIN #tmpGenderType_5 AS GT ON EI.GenderTypeId=GT.GenderTypeId
LEFT JOIN #tmpEmpEducationHist_5 AS EE ON EI.EmployeeInformationId=EE.EmployeeInformationId AND EE.SortOrder=1


IF @GetEmployees=1
BEGIN--GetEmployees

SELECT
EI.EmployeeInformationId,
EI.EmployeeCode,
EI.MachineCode,
ISNULL(EI.FirstName,'')+(CASE WHEN ISNULL(EI.MiddleName,'')='' THEN '' ELSE  ' '+EI.MiddleName END)+(CASE WHEN ISNULL(EI.LastName,'')='' THEN '' ELSE  ' '+EI.LastName END) AS EmployeeName,
EI.FatherName,
EI.MotherName,
EI.HusbandName,
EI.GenderTypeId,EJS.GenderSN,EJS.Gender,
EI.MeritalStatusId,ISNULL(MS.StatusShortName,'S') AS MaritalStausSN,ISNULL(MS.StatusLongName,'Single') AS MaritalStatus,
ISNULL(R.ReligionName,'Muslim') AS Religion,
EI.CNIC,EI.NICExpiryDate,EI.NTN,EI.EOBINumber,
EI.DateOfBirth,
DATEDIFF(YEAR,ISNULL(EI.DateOfBirth, DATEADD(YEAR,-18,@ToDate)),@ToDate) AS Age,
DBO.Age(EI.DateOfBirth,@ToDate) AS Age2,
EI.PlaceOfBirth AS PlaceOfBirthId, C.CityShortName PlaceOfBirthSN,C.CityLongName AS PlaceOfBirth,
EI.MotherTongueId, ISNULL(L.ShortName,'Urdu') AS MotherTongueSN,ISNULL(L.Name,'Urdu') AS MotherTongue,
EI.BloodGroupId,BG.[Name] AS BloodGroup
,EJS.EmployementStatus,EJS.StartDate AS JoinDate,EJS.EndDate AS LefDate,DATEDIFF(DAY,EJS.StartDate,(CASE WHEN EJS.EndDate>@ToDate THEN @ToDate ELSE EJS.EndDate END))/365.25 AS ServiceLength,DBO.Age(EJS.StartDate,(CASE WHEN EJS.EndDate>@ToDate THEN @ToDate ELSE EJS.EndDate END)) AS ServiceLength2,ejs.SortOrder
,eimg.ImageBlock,eimg.[Signature]
,EJS.DepartmentId,EJS.Department,EJS.DepartmentSN,EJS.CompanyBranchId,EJS.CompanyBranch,EJS.CompanyBranchSN,EJS.DesignationId,EJS.Designation,EJS.DesignationSN
,EJS.QualificationId,EJS.Education,EJS.EducationSN
FROM EmployeeInformation EI
INNER JOIN (
	SELECT d.*,'Old' AS EmployementStatus
	FROM #tmpData AS d 
	WHERE d.StartDate<@FromDate AND d.EndDate>=@FromDate AND DimId NOT IN(3,4) AND (@EmployementStatus='' OR @EmployementStatus='Old')
	UNION ALL
	SELECT d.*,'Hired' AS EmployementStatus
	FROM #tmpData AS d 
	WHERE d.StartDate BETWEEN @FromDate AND @ToDate AND DimId NOT IN(3,4) AND (@EmployementStatus='' OR @EmployementStatus='Hired')
	UNION ALL
	SELECT d.*,'Left' AS EmployementStatus
	FROM #tmpData AS d 
	WHERE d.StartDate BETWEEN @FromDate AND @ToDate AND DimId IN(3,4) AND (@EmployementStatus='' OR @EmployementStatus='Left')
) AS EJS ON EI.EmployeeInformationId=EJS.EmployeeInformationId
LEFT JOIN MeritalStatus AS MS ON EI.MeritalStatusId=MS.MeritalStatusId
LEFT JOIN Religion AS R ON EI.ReligionId=R.ReligionId
LEFT JOIN [Language] AS L ON EI.MotherTongueId=L.LanguageId
LEFT JOIN BloodGroup AS BG ON EI.BloodGroupId=BG.BloodGroupId
LEFT JOIN City AS C ON EI.PlaceOfBirth=C.CityId
LEFT JOIN EmployeeImage AS eimg ON ei.EmployeeInformationId=eimg.EmployeeInformationId AND ei.DataEntryStatus=1
END--GetEmployees
ELSE
BEGIN--Summary

DECLARE @H_ToDate DATE=DATEFROMPARTS(YEAR(@ToDate)-1,12,31)
DECLARE @H_FromDate DATE=DATEFROMPARTS(YEAR(@H_ToDate)-3,1,1)
DECLARE @Calendar TABLE(TheDate DATE,TheMonth INT,TheMonthName NVARCHAR(9),TheQuarter INT,TheYear INT,TheFirstOfMonth DATE,TheLastOfMonth DATE,TheFirstOfQuarter DATE,TheLastOfQuarter DATE)
INSERT INTO @Calendar
EXEC web.spDashboardAPI @Type=24,@FromDate=@H_FromDate,@ToDate=@H_ToDate

DECLARE @NewFromDate AS DATETIME
SET @NewFromDate = DATEFROMPARTS(YEAR(@FromDate)-0,1,1)
 
DECLARE @Calendar_Current TABLE(TheDate DATE,TheMonth INT,TheMonthName NVARCHAR(9),TheQuarter INT,TheYear INT,TheFirstOfMonth DATE,TheLastOfMonth DATE,TheFirstOfQuarter DATE,TheLastOfQuarter DATE)
INSERT INTO @Calendar_Current
EXEC web.spDashboardAPI @Type=24,@FromDate=@NewFromDate,@ToDate=@ToDate

--1 History year wise
SELECT TheYear,SUM(Count_Old) AS Count_Old,SUM(Count_Hired) AS Count_Hired,SUM(Count_Left) AS Count_Left
,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
FROM (
	--Current/This Period
	SELECT YEAR(@ToDate) AS TheYear,SUM(CASE WHEN DimId NOT IN(3,4) THEN 1 ELSE 0 END) AS Count_Old,0 AS Count_Hired,0 AS Count_Left
	,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	FROM (SELECT TheYear,CAST(MIN(TheDate) AS DATETIME) + CAST('00:00:00' AS DATETIME) TheFirst,CAST(MAX(TheDate) AS datetime)+ CAST('23:59:59.998' AS DATETIME) AS TheLast
		  FROM @Calendar_Current
		  GROUP BY TheYear) AS cal
	INNER JOIN #tmpData AS d ON d.StartDate<cal.TheFirst AND d.EndDate>=cal.TheFirst
	GROUP BY d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	UNION ALL
	SELECT YEAR(@ToDate) AS TheYear, 0 AS Count_Old,SUM(CASE WHEN DimId NOT IN(3,4) THEN 1 ELSE 0 END) AS Count_Hired,SUM(CASE WHEN DimId IN(3,4) THEN 1 ELSE 0 END) AS Count_Left
	,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	FROM (
		SELECT TheYear,CAST(MIN(TheDate) AS DATETIME) + CAST('00:00:00' AS DATETIME) TheFirst,CAST(MAX(TheDate) AS datetime)+ CAST('23:59:59.998' AS DATETIME) AS TheLast
		FROM @Calendar_Current
		GROUP BY TheYear) AS cal
	INNER JOIN #tmpData AS d ON d.StartDate BETWEEN cal.TheFirst AND cal.TheLast
	GROUP BY d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN	--History
	--History
	UNION ALL
	SELECT TheYear,SUM(CASE WHEN DimId NOT IN(3,4) THEN 1 ELSE 0 END) AS Count_Old,0 AS Count_Hired,0 AS Count_Left
	,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	FROM (SELECT TheYear,CAST(MIN(TheDate) AS DATETIME) + CAST('00:00:00' AS DATETIME) TheFirst,CAST(MAX(TheDate) AS datetime)+ CAST('23:59:59.998' AS DATETIME) AS TheLast
		  FROM @Calendar
		  GROUP BY TheYear) AS cal
	INNER JOIN #tmpData AS d ON d.StartDate<cal.TheFirst AND d.EndDate>=cal.TheFirst
	GROUP BY TheYear,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	UNION ALL
	SELECT TheYear,0 AS Count_Old,SUM(CASE WHEN DimId NOT IN(3,4) THEN 1 ELSE 0 END) AS Count_Hired,SUM(CASE WHEN DimId IN(3,4) THEN 1 ELSE 0 END) AS Count_Left
	,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	FROM (SELECT TheYear,CAST(MIN(TheDate) AS DATETIME) + CAST('00:00:00' AS DATETIME) TheFirst,CAST(MAX(TheDate) AS datetime)+ CAST('23:59:59.998' AS DATETIME) AS TheLast
		  FROM @Calendar
		  GROUP BY TheYear) AS cal
	INNER JOIN #tmpData AS d ON d.StartDate BETWEEN cal.TheFirst AND cal.TheLast
	GROUP BY TheYear,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
) AS d
GROUP BY TheYear,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN

--2 History month wise
SELECT TheYear,TheMonth,TheMonthName,LEFT(TheMonthName,3) AS TheMonthNameSN,CAST(TheYear AS VARCHAR)+'-'+LEFT(TheMonthName,3) AS TheYearMonthSN,SUM(Count_Old) AS Count_Old,SUM(Count_Hired) AS Count_Hired,SUM(Count_Left) AS Count_Left
,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
FROM (
	--Current/This Period
	SELECT YEAR(@ToDate) AS TheYear,TheMonth,TheMonthName,SUM(CASE WHEN DimId NOT IN(3,4) THEN 1 ELSE 0 END) AS Count_Old,0 AS Count_Hired,0 AS Count_Left
	,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	FROM (SELECT TheYear,TheMonth,TheMonthName,CAST(MIN(TheDate) AS DATETIME) + CAST('00:00:00' AS DATETIME) TheFirst,CAST(MAX(TheDate) AS datetime)+ CAST('23:59:59.998' AS DATETIME) AS TheLast
		FROM @Calendar_Current
		GROUP BY TheYear,TheMonth,TheMonthName) AS cal
	INNER JOIN #tmpData AS d ON d.StartDate<cal.TheFirst AND d.EndDate>=cal.TheFirst
	GROUP BY TheMonth,TheMonthName,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	UNION ALL
	SELECT YEAR(@ToDate) AS TheYear,TheMonth,TheMonthName,0 AS Count_Old,SUM(CASE WHEN DimId NOT IN(3,4) THEN 1 ELSE 0 END) AS Count_Hired,SUM(CASE WHEN DimId IN(3,4) THEN 1 ELSE 0 END) AS Count_Left
	,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	FROM (SELECT TheYear,TheMonth,TheMonthName,CAST(MIN(TheDate) AS DATETIME) + CAST('00:00:00' AS DATETIME) TheFirst,CAST(MAX(TheDate) AS datetime)+ CAST('23:59:59.998' AS DATETIME) AS TheLast
		FROM @Calendar_Current
		GROUP BY TheYear,TheMonth,TheMonthName) AS cal
	INNER JOIN #tmpData AS d ON d.StartDate BETWEEN cal.TheFirst AND cal.TheLast
	GROUP BY TheMonth,TheMonthName,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	--History
	UNION ALL
	SELECT TheYear,TheMonth,TheMonthName,SUM(CASE WHEN DimId NOT IN(3,4) THEN 1 ELSE 0 END) AS Count_Old,0 AS Count_Hired,0 AS Count_Left
	,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	FROM (SELECT TheYear,TheMonth,TheMonthName,CAST(MIN(TheDate) AS DATETIME) + CAST('00:00:00' AS DATETIME) TheFirst,CAST(MAX(TheDate) AS datetime)+ CAST('23:59:59.998' AS DATETIME) AS TheLast
		FROM @Calendar
		GROUP BY TheYear,TheMonth,TheMonthName) AS cal
	INNER JOIN #tmpData AS d ON d.StartDate<cal.TheFirst AND d.EndDate>=cal.TheFirst
	GROUP BY TheYear,TheMonth,TheMonthName,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	UNION ALL
	SELECT TheYear,TheMonth,TheMonthName,0 AS Count_Old,SUM(CASE WHEN DimId NOT IN(3,4) THEN 1 ELSE 0 END) AS Count_Hired,SUM(CASE WHEN DimId IN(3,4) THEN 1 ELSE 0 END) AS Count_Left
	,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
	FROM (SELECT TheYear,TheMonth,TheMonthName,CAST(MIN(TheDate) AS DATETIME) + CAST('00:00:00' AS DATETIME) TheFirst,CAST(MAX(TheDate) AS datetime)+ CAST('23:59:59.998' AS DATETIME) AS TheLast
		FROM @Calendar
		GROUP BY TheYear,TheMonth,TheMonthName) AS cal
	INNER JOIN #tmpData AS d ON d.StartDate BETWEEN cal.TheFirst AND cal.TheLast
	GROUP BY TheYear,TheMonth,TheMonthName,d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
) AS d
GROUP BY TheYear,TheMonth,TheMonthName,LEFT(TheMonthName,3),CAST(TheYear AS VARCHAR)+'-'+LEFT(TheMonthName,3),d.CompanyBranchId,d.CompanyBranch,d.CompanyBranchSN,d.DepartmentId,d.Department,d.DepartmentSN,d.DesignationId,d.Designation,d.DesignationSN,d.GenderTypeId,d.Gender,d.GenderSN
ORDER BY TheYear,TheMonth
END--Summary


IF OBJECT_ID('tempdb..#tmpCompanyBranch_5') IS NOT NULL DROP TABLE #tmpCompanyBranch_5
IF OBJECT_ID('tempdb..#tmpDepartment_5') IS NOT NULL DROP TABLE #tmpDepartment_5
IF OBJECT_ID('tempdb..#tmpDepartment_5') IS NOT NULL DROP TABLE #tmpDepartment_5
IF OBJECT_ID('tempdb..#tmpDesignation_5') IS NOT NULL DROP TABLE #tmpDesignation_5
IF OBJECT_ID('tempdb..#tmpGenderType_5') IS NOT NULL DROP TABLE #tmpGenderType_5

IF OBJECT_ID('tempdb..#EmpJobStatusHist_5') IS NOT NULL DROP TABLE #EmpJobStatusHist_5
IF OBJECT_ID('tempdb..#EmpJobStatusHist_5_0') IS NOT NULL DROP TABLE #EmpJobStatusHist_5_0
IF OBJECT_ID('tempdb..#tmpEmpBranchHist_5') IS NOT NULL DROP TABLE #tmpEmpBranchHist_5
IF OBJECT_ID('tempdb..#tmpEmpDepartmentHist_5') IS NOT NULL DROP TABLE #tmpEmpDepartmentHist_5
IF OBJECT_ID('tempdb..#tmpEmpDesignationHist_5') IS NOT NULL DROP TABLE #tmpEmpDesignationHist_5
IF OBJECT_ID('tempdb..#tmpEmpEducationHist_5') IS NOT NULL DROP TABLE #tmpEmpEducationHist_5
IF OBJECT_ID('tempdb..#tmpData') IS NOT NULL DROP TABLE #tmpData

END

IF @Type=6--Employee List
BEGIN
	
	--template
	/*DECLARE TABLE @tmp_Emp (EmployeeInformationId int,EmployeeCode nvarchar(15),MachineCode nvarchar(15),EmployeeName nvarchar(200),EmployeeNickName nvarchar(50),FatherName nvarchar(50),MotherName nvarchar(50),HusbandName nvarchar(50)
	,GenderTypeId int,GenderShortName nvarchar(3),Gender nvarchar(15),EducationId int,EducationSN nvarchar(5),Education nvarchar(100),MeritalStatusId int,MaritalStausSN nvarchar(4),MaritalStatus nvarchar(50)
	,Religion nvarchar(50),CNIC nvarchar(20),NICExpiryDate datetime,NTN nvarchar(50),EOBINumber varchar(100),DateOfBirth datetime,Age int,Age2 varchar(50),PlaceOfBirthId int,PlaceOfBirthSN nvarchar(4)
	,PlaceOfBirth nvarchar(50),MotherTongueId int,MotherTongueSN nvarchar(50),MotherTongue nvarchar(100),BloodGroupId int,BloodGroup nvarchar(100),JobStatusId int,JobSTatusSN nvarchar(50),JobStatus nvarchar(50)
	,JoinDate datetime,ServiceLength numeric(18, 6),ServiceLength2 varchar(50),CompanyBranchId int,CompanyBranchSN nvarchar(100),CompanyBranch nvarchar(200),DepartmentId int,DepartmentSN nvarchar(50),Department nvarchar(100) 
	,DesignationId int,	DesignationSN nvarchar(5),Designation nvarchar(100),GrossSalary money,ImageBlock IMAGE)*/
	
	--DECLARE @ToDate DATETIME=GETDATE()
	--DECLARE @CompanyBranchIds VARCHAR(MAX)='';
	--DECLARE @DepartmentIds VARCHAR(MAX)='';

	IF @ToDate IS NULL
	BEGIN
		SET @ToDate=GETDATE()
	END
		
	IF OBJECT_ID('tempdb..#EmpJobStatusHist_6') IS NOT NULL DROP TABLE #EmpJobStatusHist_6
	IF OBJECT_ID('tempdb..#tmpCompanyBranch_6') IS NOT NULL DROP TABLE #tmpCompanyBranch_6
	IF OBJECT_ID('tempdb..#tmpDepartment_6') IS NOT NULL DROP TABLE #tmpDepartment_6
	IF OBJECT_ID('tempdb..#tmpEmpBranchHist_6') IS NOT NULL DROP TABLE #tmpEmpBranchHist_6
	IF OBJECT_ID('tempdb..#tmpEmpDepartmentHist_6') IS NOT NULL DROP TABLE #tmpEmpDepartmentHist_6
	IF OBJECT_ID('tempdb..#tmpEmpDesignationHist_6') IS NOT NULL DROP TABLE #tmpEmpDesignationHist_6
	IF OBJECT_ID('tempdb..#tmpEmpSalaryHist_6') IS NOT NULL DROP TABLE #tmpEmpSalaryHist_6
	IF OBJECT_ID('tempdb..#tmpEmpEducationHist_6') IS NOT NULL DROP TABLE #tmpEmpEducationHist_6

	SELECT CompanyBranchId,LongName,ShortName
	INTO #tmpCompanyBranch_6
	FROM CompanyBranch
	WHERE CASE WHEN @CompanyBranchIds = '' THEN 0 ELSE CompanyBranchId END IN (SELECT Ids FROM dbo.SetTempHashValues(@CompanyBranchIds) AS sthv);

	SELECT DepartmentId,[Name],ShortName
	INTO #tmpDepartment_6
	FROM Department
	WHERE CASE WHEN @DepartmentIds = '' THEN 0 ELSE DepartmentId END IN (SELECT Ids FROM dbo.SetTempHashValues(@DepartmentIds) AS sthv);

	--BEGIN: Job Status History
	;WITH cteEJSHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
	SELECT EmployeeInformationId, AssignDate, JobStatusId AS DimId, DENSE_RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC,DataEntryDate DESC) AS SortOrder 
	FROM EmployeeJobStatus H WHERE DataEntryStatus=1)

	SELECT a.EmployeeInformationId, a.DimId,d.ShortName AS DimShortName,d.[Name] As DimName,
	a.AssignDate StartDate, ISNULL(b.AssignDate,'2999-12-31 23:59:59') AS EndDate,a.SortOrder
	INTO #EmpJobStatusHist_6
	FROM cteEJSHistSrc AS a
	LEFT JOIN cteEJSHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder= b.SortOrder+1
	INNER JOIN JobStatus AS d ON a.DimId=d.JobStatusId;
	--END: Job Status History

	--BEGIN: Branch History
	;WITH cteEBHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
	SELECT EmployeeInformationId, AssignDate, CompanyBranchId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
	FROM EmployeeBranch H WHERE DataEntryStatus=1)
	SELECT	a.EmployeeInformationId,a.DimId,d.ShortName AS DimShortName,d.[LongName] As DimName,
	a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
	INTO #tmpEmpBranchHist_6
	FROM cteEBHistSrc AS a
	LEFT JOIN cteEBHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
	INNER JOIN #tmpCompanyBranch_6 AS d ON a.DimId=d.CompanyBranchId
	--END: Branch History

	--BEGIN: Department History
	;WITH cteEDHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
	SELECT EmployeeInformationId, AssignDate, DepartmentId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
	FROM EmployeeDepartment H WHERE DataEntryStatus=1)
	SELECT	a.EmployeeInformationId, a.DimId, d.ShortName AS DimShortName,d.[Name] As DimName,
	a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
	INTO #tmpEmpDepartmentHist_6
	FROM cteEDHistSrc AS a
	LEFT JOIN cteEDHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
	INNER JOIN #tmpDepartment_6 AS d ON a.DimId=d.DepartmentId
	--END: Department History

	--BEGIN: Designation History
	;WITH cteEDesHistSrc(EmployeeInformationId, AssignDate, DimId,SortOrder) AS (
	SELECT EmployeeInformationId, AssignDate, DesignationId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
	FROM EmployeeDesignation H WHERE DataEntryStatus=1)
	SELECT	a.EmployeeInformationId, a.DimId,d.ShortName DimShortName,d.[Name] As DimName,
	a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
	INTO #tmpEmpDesignationHist_6
	FROM cteEDesHistSrc AS a
	LEFT JOIN cteEDesHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
	INNER JOIN Designation AS d ON a.DimId=d.DesignationId
	--END: Designation History

	--BEGIN: Education History
	;WITH cteEEduHistSrc(EmployeeInformationId, AssignDate,DimId,SortOrder) AS (
	SELECT EmployeeInformationId, AssignDate, QualificationId AS DimId, RANK() OVER (PARTITION BY EmployeeInformationId ORDER BY AssignDate DESC, DataEntryDate DESC) AS SortOrder 
	FROM EmployeeQualification H WHERE DataEntryStatus=1)
	SELECT	a.EmployeeInformationId, a.DimId,d.ShortName DimShortName,d.[Name] As DimName,
	a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
	INTO #tmpEmpEducationHist_6
	FROM cteEEduHistSrc AS a
	LEFT JOIN cteEEduHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
	INNER JOIN Qualification AS d ON a.DimId=d.QualificationId
	--END: Qualification History

	--BEGIN: Salary History
	;WITH cteESalHistSrc(EmployeeInformationId, AssignDate,CalcBase,DimId,DimShortName,DimName,Amount,SortOrder) AS (
	--Patch not updated: SELECT H.EmployeeInformationId, H.AssignDate,(CASE WHEN SS.SalaryTypeId=1 THEN 'Basic' ELSE (CASE WHEN ST.CalculationCriteria BETWEEN 11 AND 20 THEN 'Addition' WHEN ST.CalculationCriteria BETWEEN 31 AND 40 THEN 'Deduction' END) END) AS CalcBase, 
	SELECT H.EmployeeInformationId, H.AssignDate,(CASE WHEN SS.SalaryTypeId=1 THEN 'Basic' WHEN SS.SalaryTypeId IN (2,6,9,26,27,11,13,16,20,22,24) THEN 'Addition' WHEN SS.SalaryTypeId IN (3,7,8,10,25,4,5,12,17,18,19,21,23,28) THEN 'Deduction'  END) AS CalcBase, 
	SS.SalaryTypeId AS DimId,ST.ShortName AS DimShortName,ST.[Name] AS DimName,H.Amount, RANK() OVER (PARTITION BY H.EmployeeInformationId,H.SalaryStructureId ORDER BY H.AssignDate DESC, H.DataEntryDate DESC) AS SortOrder 
	FROM EmployeeSalaryStructure H 
	LEFT JOIN SalaryStructure SS ON ss.SalaryStructureId = H.SalaryStructureId
	LEFT JOIN SalaryType ST ON st.SalaryTypeId = ss.SalaryTypeId
	WHERE H.DataEntryStatus=1)
	SELECT	a.EmployeeInformationId,a.CalcBase, a.DimId,a.DimShortName,a.DimName,a.Amount,
	a.AssignDate StartDate, (CASE WHEN b.AssignDate IS NULL THEN CAST('2999-12-31 23:59:59' AS DATETIME) ELSE DATEADD(SECOND,-1,b.AssignDate) END) AS EndDate,a.SortOrder
	INTO #tmpEmpSalaryHist_6
	FROM cteESalHistSrc AS a
	LEFT JOIN cteESalHistSrc AS b ON a.EmployeeInformationId = b.EmployeeInformationId AND a.SortOrder = b.SortOrder + 1
	--END: Salary History

	SELECT
	EI.EmployeeInformationId,
	EI.EmployeeCode,
	EI.MachineCode,
	ISNULL(EI.FirstName,'')+(CASE WHEN ISNULL(EI.MiddleName,'')='' THEN '' ELSE  ' '+EI.MiddleName END)+(CASE WHEN ISNULL(EI.LastName,'')='' THEN '' ELSE  ' '+EI.LastName END) AS EmployeeName,
	EI.EmployeeNickName,
	EI.FatherName,
	EI.MotherName,
	EI.HusbandName,
	EI.GenderTypeId,
	ISNULL(GT.GenderShortName,'M') AS GenderShortName,ISNULL(GT.GenderLongName,'Male') AS Gender,
	EE.DimId AS EducationId,EE.DimShortName AS EducationSN,ISNULL(EE.DimName,'Matric') AS Education,
	EI.MeritalStatusId,ISNULL(MS.StatusShortName,'S') AS MaritalStausSN,ISNULL(MS.StatusLongName,'Single') AS MaritalStatus,
	ISNULL(R.ReligionName,'Muslim') AS Religion,
	EI.CNIC,EI.NICExpiryDate,EI.NTN,EI.EOBINumber,
	EI.DateOfBirth,
	DATEDIFF(YEAR,ISNULL(EI.DateOfBirth, DATEADD(YEAR,-18,@ToDate)),@ToDate) AS Age,
	DBO.Age(EI.DateOfBirth,@ToDate) AS Age2,
	EI.PlaceOfBirth AS PlaceOfBirthId, C.CityShortName PlaceOfBirthSN,C.CityLongName AS PlaceOfBirth,
	EI.MotherTongueId, ISNULL(L.ShortName,'Urdu') AS MotherTongueSN,ISNULL(L.Name,'Urdu') AS MotherTongue,
	EI.BloodGroupId,BG.[Name] AS BloodGroup,
	EJS.DimId AS JobStatusId,EJS.DimShortName AS JobSTatusSN,EJS.DimName AS JobStatus,
	EJS.StartDate AS JoinDate,
	DATEDIFF(DAY,EJS.StartDate,@ToDate)/364.25 AS ServiceLength,
	DBO.Age(EJS.StartDate,@ToDate) AS ServiceLength2,
	EB.DimId AS CompanyBranchId,EB.DimShortName AS CompanyBranchSN, EB.DimName AS CompanyBranch,
	ED.DimId AS DepartmentId,ED.DimShortName AS DepartmentSN,ED.DimName AS Department,
	EDes.DimId AS DesignationId,EDes.DimShortName AS DesignationSN,EDes.DimName AS Designation,
	ESal.Amount AS GrossSalary
	,eimg.ImageBlock
	FROM EmployeeInformation EI
	LEFT JOIN GenderType AS GT ON EI.GenderTypeId=GT.GenderTypeId
	LEFT JOIN MeritalStatus AS MS ON EI.MeritalStatusId=MS.MeritalStatusId
	LEFT JOIN Religion AS R ON EI.ReligionId=R.ReligionId
	LEFT JOIN [Language] AS L ON EI.MotherTongueId=L.LanguageId
	LEFT JOIN BloodGroup AS BG ON EI.BloodGroupId=BG.BloodGroupId
	LEFT JOIN City AS C ON EI.PlaceOfBirth=C.CityId
	LEFT JOIN EmployeeImage AS eimg ON ei.EmployeeInformationId=eimg.EmployeeInformationId AND ei.DataEntryStatus=1
	INNER JOIN #EmpJobStatusHist_6 AS EJS ON EI.EmployeeInformationId=EJS.EmployeeInformationId AND EJS.SortOrder=1
	LEFT JOIN #tmpEmpBranchHist_6 AS EB ON EI.EmployeeInformationId=EB.EmployeeInformationId AND EB.SortOrder=1
	LEFT JOIN #tmpEmpDepartmentHist_6 AS ED ON EI.EmployeeInformationId=ED.EmployeeInformationId AND ED.SortOrder=1
	LEFT JOIN #tmpEmpDesignationHist_6 AS EDes ON EI.EmployeeInformationId=EDes.EmployeeInformationId AND EDes.SortOrder=1
	LEFT JOIN #tmpEmpSalaryHist_6 AS ESal ON EI.EmployeeInformationId=ESal.EmployeeInformationId AND ESal.SortOrder=1 AND ESal.DimId=1
	LEFT JOIN #tmpEmpEducationHist_6 AS EE ON EI.EmployeeInformationId=EE.EmployeeInformationId AND EE.SortOrder=1
 
	IF OBJECT_ID('tempdb..#EmpJobStatusHist_6') IS NOT NULL DROP TABLE #EmpJobStatusHist_6
	IF OBJECT_ID('tempdb..#tmpCompanyBranch_6') IS NOT NULL DROP TABLE #tmpCompanyBranch_6
	IF OBJECT_ID('tempdb..#tmpDepartment_6') IS NOT NULL DROP TABLE #tmpDepartment_6
	IF OBJECT_ID('tempdb..#tmpEmpBranchHist_6') IS NOT NULL DROP TABLE #tmpEmpBranchHist_6
	IF OBJECT_ID('tempdb..#tmpEmpDepartmentHist_6') IS NOT NULL DROP TABLE #tmpEmpDepartmentHist_6
	IF OBJECT_ID('tempdb..#tmpEmpDesignationHist_6') IS NOT NULL DROP TABLE #tmpEmpDesignationHist_6
	IF OBJECT_ID('tempdb..#tmpEmpSalaryHist_6') IS NOT NULL DROP TABLE #tmpEmpSalaryHist_6
	IF OBJECT_ID('tempdb..#tmpEmpEducationHist_6') IS NOT NULL DROP TABLE #tmpEmpEducationHist_6
END
