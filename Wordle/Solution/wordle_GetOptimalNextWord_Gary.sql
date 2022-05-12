CREATE PROCEDURE[dbo].[wordle_GetOptimalNextWord_Gary]
(	@Player char(25)        
,	@WordDate date	--in the game of wordle you can only play one word a day, so this is like a WordID
,	@NextGuess char(5) output   --this will return the next word to play
,	@IsDebugRun bit = 0
)

AS

/*
_________________________________________________________________________________________________
_________________________________________________________________________________________________

	proc name: 	wordle_GetOptimalNextWord_Gary
	author:		Gary Zhang

	description: 	this looks at the words played to guess a Wordle word and determines the optimal next guess

					Rules:
					1 - you must return the optimal next word to guess in the @NextGuess variable
					2 - you can't reference any table other than WordleWords and WordlePlays (you obviously can't reference the answers table)
					3 - this is supposed to simulate "hard mode" in Wordle, meaning with each guess has to use all known clues
					4 - no loops or cursors
					5 - no hard-coded words
_______________________________________________________________________________________________________________________________
_______________________________________________________________________________________________________________________________

*/

/*
-- you must use this data to figure out what word to play next, and use no other functions, tables or sources at all
select	* 
from	WordlePlays 
where	Player = @Player
and		WordDate = @WordDate

select * 
from	WordleWords

*/

--you must replace this code below with returning your best next guess.  This it is here just so that this can work from the PlayAllWords script
--select @NextGuess = Word from WordleAnswers where WordDate = @WordDate

Declare 
@MaxTryNumber tinyint = 0,
@TryNumber tinyint = 1,
@WhereClausCommand varchar(max) = ''

SET @MaxTryNumber = (SELECT max(TryNumber) FROM dbo.WordlePlays 
				     WHERE Player = @Player
			         AND WordDate = @WordDate)

While(@TryNumber <= @MaxTryNumber)
BEGIN
	
	Declare @L1		bit	
	       ,@L2		bit	
		   ,@L3		bit	
		   ,@L4		bit	
		   ,@L5		bit	
		   ,@L1Letter char(1)
		   ,@L2Letter char(1)
		   ,@L3Letter char(1)
		   ,@L4Letter char(1)
		   ,@L5Letter char(1)
		   ,@L1Cmd  varchar(max)
		   ,@L2Cmd  varchar(max)
		   ,@L3Cmd	varchar(max)
		   ,@L4Cmd	varchar(max)
		   ,@L5Cmd	varchar(max)
		   ,@i int = 0

	SELECT @L1 = L1
		  ,@L2 = L2
		  ,@L3 = L3
		  ,@L4 = L4
		  ,@L5 = L5
		  ,@L1Letter = SUBSTRING(Word, 1, 1)
		  ,@L2Letter = SUBSTRING(Word, 2, 1)
		  ,@L3Letter = SUBSTRING(Word, 3, 1)
		  ,@L4Letter = SUBSTRING(Word, 4, 1)
		  ,@L5Letter = SUBSTRING(Word, 5, 1)
	FROM dbo.WordlePlays
	WHERE Player = @Player
	  AND WordDate = @WordDate
	  AND TryNumber = @TryNumber

	SET @L1Cmd = CASE WHEN @L1 IS NULL 
					  THEN CASE WHEN @WhereClausCommand = ''
								THEN 'Word NOT LIKE ''%' + @L1Letter + '%'''
						   ELSE ' AND Word NOT LIKE ''%' + @L1Letter + '%'' '
						   END
				      WHEN @L1 = 0
					  THEN CASE WHEN @WhereClausCommand = ''
								THEN 'Num' + @L1Letter + ' >= 1 AND Word NOT LIKE ''' + @L1Letter + '%'' '
						   ELSE ' AND Num' + @L1Letter + ' >= 1 '
						   END
					  WHEN @L1 = 1
					  THEN CASE WHEN @WhereClausCommand = ''
								THEN 'Word LIKE ''' + @L1Letter + '%'''
						   ELSE ' AND Word LIKE ''' + @L1Letter + '%'' '
						   END
				 END

	SET @L2Cmd = CASE WHEN @L2 IS NULL 
					  THEN ' AND Word NOT LIKE ''%' + @L2Letter + '%'' '
				      WHEN @L2 = 0
					  THEN ' AND Num' + @L2Letter + ' >= 1 AND Word NOT LIKE ''_' + @L2Letter + '%'' '
					  WHEN @L2 = 1
					  THEN ' AND Word LIKE ''_' + @L2Letter + '%'' '
				  END

	SET @L3Cmd = CASE WHEN @L3 IS NULL 
					  THEN ' AND Word NOT LIKE ''%' + @L3Letter + '%'' '
				      WHEN @L3 = 0
					  THEN ' AND Num' + @L3Letter + ' >= 1 AND Word NOT LIKE ''__' + @L3Letter + '%'' '
					  WHEN @L3 = 1
					  THEN ' AND Word LIKE ''__' + @L3Letter + '%'' '
				  END

	SET @L4Cmd = CASE WHEN @L4 IS NULL 
					  THEN ' AND Word NOT LIKE ''%' + @L4Letter + '%'' '
				      WHEN @L4 = 0
					  THEN ' AND Num' + @L4Letter + ' >= 1 AND Word NOT LIKE ''___' + @L4Letter + '%'' '
					  WHEN @L4 = 1
					  THEN ' AND Word LIKE ''___' + @L4Letter + '%'' '
				  END

	SET @L5Cmd = CASE WHEN @L5 IS NULL 
					  THEN ' AND Word NOT LIKE ''%' + @L5Letter + '%'' '
				      WHEN @L5 = 0
					  THEN ' AND Num' + @L5Letter + ' >= 1 AND Word NOT LIKE ''____' + @L5Letter + '%'' '
					  WHEN @L5 = 1
					  THEN ' AND Word LIKE ''____' + @L5Letter + '%'' '
				  END

	SET @WhereClausCommand += @L1Cmd + @L2Cmd + @L3Cmd + @L4Cmd + @L5Cmd

	SET @TryNumber += 1
END

DECLARE @cmd nvarchar(max) = N'SELECT TOP 1 @OutPutWord = Word FROM dbo.WordleWords WHERE ' + @WhereClausCommand + N' ORDER BY NEWID() '
EXEC sp_executesql @cmd, N'@OutPutWord char(5) out', @NextGuess OUT

