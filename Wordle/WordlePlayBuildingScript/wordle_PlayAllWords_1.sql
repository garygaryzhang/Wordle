--this script will run your algo in a loop for every word in the Wordle universe
--it will use your starting word
set nocount on

--choose starting word
declare @starting_word char(5) = 'SLATE'
,		@player varchar(20) = 'Gary'

--clear all plays for that player
delete WordlePlays where Player = @player

------------------------------------------------------------
--execute the algo to solve every possible wordle word
------------------------------------------------------------
declare @word char(5) = '', @word_count int = 0, @current_word_date date = '', @guess char(5) = '', @guess_count int = 0, @total_guesses int = 0,
		@next_guess char(5) = '', @l1 tinyint = 0, @l2 tinyint=0, @l3 tinyint =0, @l4 tinyint =0, @l5 tinyint =0,
		@start_time datetime, @end_time datetime, @total_seconds_elapsed int = 0

select	@start_time = getdate(),
		@current_word_date = '2021-06-19' --the earliest date in Wordle

while @current_word_date <= '2027-10-20'  --the last date in Wordle
  begin	
		set @word_count += 1 
		select @next_guess = @starting_word, @guess_count = 0, @l1 = NULL, @l2= NULL, @l3 = NULL, @l4 = NULL, @l5 = NULL		
		while coalesce(@l1,0)+coalesce(@l2,0)+coalesce(@l3,0)+coalesce(@l4,0)+coalesce(@l5,0) < 5
		  begin
			set @guess = @next_guess
			exec wordle_PlayWord @player,@current_word_date,@guess, @L1 output, @L2 output, @L3 output, @L4 output, @L5 output , @IsDebugRun = 0

			select	@guess_count += 1,
					@total_guesses += 1

			if @guess_count > 20 --something is wrong, it should not take this long per word.  This is here to prevent infinite loops
				break;

			exec wordle_GetOptimalNextWord_sample @player, @current_word_date, @NextGuess = @next_guess output,@IsDebugRun = 0			
			--exec wordle_GetOptimalNextWord_martinezaz @player, @current_word_date, @NextGuess = @next_guess output,@IsDebugRun = 0			
		  end
		set @current_word_date = dateadd(dd,1,@current_word_date)
  end

  select @end_time = getdate(),
		 @total_seconds_elapsed = datediff(SS, @start_time, @end_time)

------------------------------------------------------------
--record the results for this execution of the algo
------------------------------------------------------------
; WITH SolveTries_cte (WordDate, NumTries) 
AS
(
	select	WordDate, max(TryNumber) as NumTries
	from	WordlePlays
	where	Player = @player
	group by WordDate
)
insert into WordleAlgoResults	(Player, PlayDate, Score, StartingWord, WordCount, GuessCount, ElapsedSeconds, SolveAvgGuesses,
								SolvedIn_One, SolvedIn_Two, SolvedIn_Three, SolvedIn_Four, SolvedIn_Five, 
								SolvedIn_Six, SolvedIn_Seven, SolvedIn_Eight, SolvedIn_Nine, SolvedIn_Ten, SolvedIn_OverTen)
select	Player = @player,
		PlayDate = getdate(),
		Score = 10000 - (@total_guesses + @total_seconds_elapsed),
		StartingWord = @starting_word,
		WordCount = @word_count,
		GuessCount = @total_guesses,
		ElapsedSeconds = @total_seconds_elapsed,
		SolveAvgGuesses = avg(cast(NumTries as float)),
		SolvedIn_One = coalesce(sum(case when NumTries = 1 then 1 else 0 end),0),
		SolvedIn_Two = coalesce(sum(case when NumTries = 2 then 1 else 0 end),0),
		SolvedIn_Three = coalesce(sum(case when NumTries = 3 then 1 else 0 end),0),
		SolvedIn_Four = coalesce(sum(case when NumTries = 4 then 1 else 0 end),0),
		SolvedIn_Five = coalesce(sum(case when NumTries = 5 then 1 else 0 end),0),
		SolvedIn_Six = coalesce(sum(case when NumTries = 6 then 1 else 0 end),0),
		SolvedIn_Seven = coalesce(sum(case when NumTries = 7 then 1 else 0 end),0),
		SolvedIn_Eight = coalesce(sum(case when NumTries = 8 then 1 else 0 end),0),
		SolvedIn_Nine = coalesce(sum(case when NumTries = 9 then 1 else 0 end),0),
		SolvedIn_Ten = coalesce(sum(case when NumTries = 10 then 1 else 0 end),0),
		SolvedIn_OverTen = coalesce(sum(case when NumTries > 10 then 1 else 0 end),0)
from	SolveTries_cte


select * from WordleAlgoResults where Player = @player
