PRINT 'Executing patch: 302-Insert_SoftwareModuleForm_HSCodeInventory_Nabeel'

--Insert Form Data
DECLARE @UserId INT
SET @UserId=2

PRINT 'Adding in SoftwareForm'
--SELECT * FROM SoftwareForm order by 1 desc
IF NOT EXISTS (SELECT SoftwareFormId FROM SoftwareForm WHERE SoftwareFormId=491)
BEGIN
INSERT INTO SoftwareForm(SoftwareFormId,FormName,IndustryId,FormStatus,IsVisibleWeb,DataEntryDate,UserId)
VALUES(491,'HSCodeInventory',0,1,1,GETDATE(),@UserId)
PRINT 'SoftwareForm 491 Added!'
END
ELSE
	BEGIN
	PRINT 'EXIT execution from SoftwareForm!'
	END

PRINT 'Adding in SoftwareModuleForm'
--SELECT * FROM SoftwareModuleForm  where SoftwareModuleId  = 61
IF NOT EXISTS (SELECT SoftwareModuleFormId FROM SoftwareModuleForm WHERE SoftwareModuleFormId=1084)
BEGIN
INSERT INTO SoftwareModuleForm(SoftwareModuleFormId,SoftwareModuleId,SoftwareFromId,ModuleFormStatus,FormDisplayName,IsVisibleWeb,DataEntryDate,DataEntryStatus)
VALUES(1084, 61, 491, 0, 'HS Code Inventory', 1, GETDATE(), 1)
PRINT 'SoftwareModuleFormId 1084 added!'
END
ELSE
	BEGIN
	PRINT 'EXIT w/o execution from SoftwareModuleForm!'
	END

--Insert Filter Data
PRINT 'Adding in SoftwareModuleFormComponent...'
IF NOT EXISTS(SELECT SoftwareModuleFormComponentId FROM SoftwareModuleFormComponent WHERE SoftwareModuleFormComponentId = 837)
BEGIN
INSERT [dbo].[SoftwareModuleFormComponent] ([SoftwareModuleFormComponentId], [SoftwareModuleFormId], [SoftwareComponentId], [DisplayName], [DefaultValue], [OrderBy], [DataEntryDate], [DataEntryStatus], [Parameter]) 
VALUES (837, 1084, 154, NULL, N'eval_js:new Date(),eval_js:new Date()', 1, GETDATE(), 1, N'FromDate, ToDate')

INSERT [dbo].[SoftwareModuleFormComponent] ([SoftwareModuleFormComponentId], [SoftwareModuleFormId], [SoftwareComponentId], [DisplayName], [DefaultValue], [OrderBy], [DataEntryDate], [DataEntryStatus], [Parameter])
 VALUES (838, 1084, 153, N'Branch', N'', 2, GETDATE(), 1, N'CompanyBranchIds')

 INSERT [dbo].[SoftwareModuleFormComponent] ([SoftwareModuleFormComponentId], [SoftwareModuleFormId], [SoftwareComponentId], [DisplayName], [DefaultValue], [OrderBy], [DataEntryDate], [DataEntryStatus], [Parameter]) 
VALUES (839, 1084, 162, N'Product Item', N'', 3, GETDATE(), 1, N'ProductItemIds')

INSERT [dbo].[SoftwareModuleFormComponent] ([SoftwareModuleFormComponentId], [SoftwareModuleFormId], [SoftwareComponentId], [DisplayName], [DefaultValue], [OrderBy], [DataEntryDate], [DataEntryStatus], [Parameter]) 
VALUES (840, 1084, 161, N'Product Category', N'', 4, GETDATE(), 1, N'ProductCategoryIds')

INSERT [dbo].[SoftwareModuleFormComponent] ([SoftwareModuleFormComponentId], [SoftwareModuleFormId], [SoftwareComponentId], [DisplayName], [DefaultValue], [OrderBy], [DataEntryDate], [DataEntryStatus], [Parameter], [CustomLogic]) 
VALUES (841, 1084, 151, N'Branch Wise?', N'0', 5, GETDATE(), 1, N'IsBranchWise', N'[{"value":"0","text":"No"},{"value":"1","text":"Yes"}]')

INSERT [dbo].[SoftwareModuleFormComponent] ([SoftwareModuleFormComponentId], [SoftwareModuleFormId], [SoftwareComponentId], [DisplayName], [DefaultValue], [OrderBy], [DataEntryDate], [DataEntryStatus], [Parameter], [CustomLogic]) 
VALUES (842, 1084, 151, N'With Category?', N'1', 6, GETDATE(), 1, N'@IsWithCategory', N'[{"value":"0","text":"No"},{"value":"1","text":"Yes"}]')

INSERT [dbo].[SoftwareModuleFormComponent] ([SoftwareModuleFormComponentId], [SoftwareModuleFormId], [SoftwareComponentId], [DisplayName], [DefaultValue], [OrderBy], [DataEntryDate], [DataEntryStatus], [Parameter], [CustomLogic]) 
VALUES (843, 1084, 151, N'With Item?', N'1', 7, GETDATE(), 1, N'@IsWithItem', N'[{"value":"0","text":"No"},{"value":"1","text":"Yes"}]')

INSERT INTO [dbo].[SoftwareModuleFormComponent] 
([SoftwareModuleFormComponentId], [SoftwareModuleFormId], [SoftwareComponentId], [DisplayName], [DefaultValue], [OrderBy], [DataEntryDate], [DataEntryStatus], [Parameter], [CustomLogic]) 
SELECT 844, 1084, 151, N'Inventory Criteria', N'2', 8, GETDATE(), 1, N'InventoryFilter', N'[{"value":"0","text":"All"},{"value":"1","text":"Equal to"},{"value":"2","text":"Not equal to"},{"value":"3","text":"Less than"},{"value":"4","text":"Less than or Equal to"},{"value":"5","text":"Greater than"},{"value":"6","text":"Greater than or Equal to"}]'
UNION ALL
SELECT 845, 1084, 157, N'Criteria Value', N'0', 9, GETDATE(), 1, N'InventoryValue', NULL


PRINT 'Added in SoftwareModuleFormComponent!'
END
ELSE
	BEGIN
	PRINT 'EXIT w/o execution from SoftwareModuleFormComponent!'
	END

