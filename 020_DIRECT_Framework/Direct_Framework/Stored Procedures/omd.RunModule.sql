﻿/*
Process: Run Module
Purpose: Executes a data logistics process / query in a DIRECT wrapper.
Input: 
  - Module Code
  - Query (statement to execute)
  - Debug flag Y/N (default to N)
Returns:
  - Process result (success, failure)
Usage:
    DECLARE @QueryResult VARCHAR(10);
    EXEC [omd].[RunModule]
      @ModuleCode = '<>',
	  @Query = '<>'
      @QueryResult = @QueryResult OUTPUT;
    PRINT @QueryResult;

	or

    EXEC [omd].[RunModule]
      @ModuleCode = '<>',
      @Debug = 'Y'
	  @Query = '<>';

*/

CREATE PROCEDURE omd.RunModule
	-- Add the parameters for the stored procedure here
	@ModuleCode VARCHAR(255),
	@Query VARCHAR(MAX) = NULL, -- An input query, which can be custom or calling a procedure. This will override the executable defined for the Module
    @BatchInstanceId INT = 0, -- The Batch Instance Id, if the Module is run from a Batch.
	@Debug VARCHAR(1) = 'N',
    @ModuleInstanceIdColumnName VARCHAR(255) = 'MODULE_INSTANCE_ID', -- Used to override if certain solutions have other columns names as audit trail id/ module instance id.
    @ModuleInstanceId BIGINT = NULL OUTPUT,
	@QueryResult VARCHAR(10) = NULL OUTPUT
AS
BEGIN

  IF @Debug = 'Y'
	PRINT 'Start of the RunModule process.';

  -- Retrieve the code to execute, if not overridden by providing the @query parameter.
  IF @Query IS NULL
    BEGIN
        SELECT @Query = [EXECUTABLE] FROM [omd].[MODULE] WHERE MODULE_CODE = @ModuleCode;

        IF @Debug = 'Y'
            PRINT 'The executable code retrieved is: '''+@Query+'''.';
    END
  ELSE
    BEGIN
        IF @Debug = 'Y'
            PRINT 'A code override has been provided: '''+@Query+'''.';
    END

  -- Create Module Instance
  EXEC [omd].[CreateModuleInstance]
    @ModuleCode = @ModuleCode,
    @Query = @Query,
    @Debug = @Debug,
    @BatchInstanceId = @BatchInstanceId, -- The Batch Instance Id, if the Module is run from a Batch.
    @ModuleInstanceId = @ModuleInstanceId OUTPUT;
  
  -- Module Evaluation
  DECLARE @ProcessIndicator VARCHAR(10);
  EXEC [omd].[ModuleEvaluation]
    @ModuleInstanceId = @ModuleInstanceId,
    @Debug = @Debug,
    @ModuleInstanceIdColumnName = @ModuleInstanceIdColumnName,
    @ProcessIndicator = @ProcessIndicator OUTPUT;

    IF @Debug = 'Y'
      PRINT @ProcessIndicator;
  
  IF @ProcessIndicator NOT IN ('Abort','Cancel') -- These are end-states for the process.
    BEGIN TRY
      /*
	    Main ETL block
	  */

      -- Replace placeholder variable(s)
      SET @Query = REPLACE(@Query,'@ModuleInstanceId', @ModuleInstanceId)

      -- Run the code
      EXEC(@Query);

      /*
	    Wrap up
	  */

      IF @Debug = 'Y'
        PRINT 'Success pathway';

      -- Module Success
      EXEC [omd].[UpdateModuleInstance]
        @ModuleInstanceId = @ModuleInstanceId,
        @Debug = @Debug,
        @EventCode = 'Success'

	  SET @QueryResult = 'Success';

   END TRY
    BEGIN CATCH
      IF @Debug = 'Y'
        PRINT 'Failure pathway';

      -- Module Failure
      EXEC [omd].[UpdateModuleInstance]
        @ModuleInstanceId = @ModuleInstanceId,
        @Debug = @Debug,
        @EventCode = 'Failure';
	  
	  SET @QueryResult = 'Failure';

	   -- Logging
	   DECLARE @EventDetail VARCHAR(4000) = ERROR_MESSAGE(),
               @EventReturnCode int = ERROR_NUMBER();

	  EXEC [omd].[InsertIntoEventLog]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventDetail = @EventDetail,
		@EventReturnCode = @EventReturnCode;

	  THROW
    END CATCH
  ELSE
    SET @QueryResult = @ProcessIndicator;

END