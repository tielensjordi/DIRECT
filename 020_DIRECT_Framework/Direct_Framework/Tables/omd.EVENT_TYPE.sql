﻿CREATE TABLE [omd].[EVENT_TYPE] (
    [EVENT_TYPE_CODE]        VARCHAR (100)  NOT NULL,
    [EVENT_TYPE_DESCRIPTION] VARCHAR (1000) NOT NULL,
    CONSTRAINT PK_EVENT_TYPE PRIMARY KEY CLUSTERED ([EVENT_TYPE_CODE] ASC)
);

