
CREATE FUNCTION [omd].[GetModuleIdByModuleInstanceId]
(
  @ModuleInstanceId INT -- An instance of the module.
)
RETURNS INT AS

-- =============================================
-- Function: Get Module Id (by Module Instance Id)
-- Description: Takes the module instance id as input and returns the Module Id as registered in the framework
-- =============================================

BEGIN
  -- Declare ouput variable

  DECLARE @ModuleId INT =
  (
    SELECT DISTINCT mi.MODULE_ID
    FROM [omd].[MODULE_INSTANCE] mi
    WHERE mi.MODULE_INSTANCE_ID = @ModuleInstanceId
  )

  -- SET @ModuleId = COALESCE(@ModuleId,0)  -- << line removed to catch NULL for incorrect @ModuleInstanceId

  -- Return the result of the function
  RETURN @ModuleId
END
