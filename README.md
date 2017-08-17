# mfctools by LinxuLovah
Tools to be used in conjunction with MyFreeCams

## tiptool.sh bash script
```
Stores MyFreeCams tips and performs statistical reporting.
Tip information is stored in ${HOME}/.tiptool/tips.txt

Camgirl synonyms (from name changes) are stored in ${HOME}/.tiptool/camgirl_synonyms.txt one per line, 
with the old name and the new name separated by a space or tab.

Adding tips:
    -at
   --add-tips                Reads the copied-and-pasted contents of the MFC
       Token Usage page from stdin.  Bring up that page and copy just the
       table of token usage, with or   without tip comments.  The easiest
       way to do  this is to copy the the tip data to the clipboard run
       "${CMDNAME} -a", paste the token usage lines into the
       terminal, then press Control-D.
       Alternately, you can paste it into a file, and run
       "${CMDNAME} -a < myfilename"
       If you paste the same tip multiple times. it will be counted
       multiple times.
    -rt                      Same as add-tips but deletes existing tips first
   --replace-tips

Searching
NOTE: All searches are regular espressions, not just character matches.
All searches are additive.  Matching records must match all searches
    -sy <YEAR>                Search by year
   --search_year <YEAR>
    -sm <MONTH>               Search by month
   --search_month <MONTH>
    -sd <DAY_OF_MONTH>        Search by day
   --search_day <DAY_OF_MONTH>
    -st <TYPE>                Search by type (Tip, GroupShow,..)
   --search_type <TYPE>
    -sc <CAMGIRL>             Search by CamGirl name
   --search_type <CAMGIRL>
    -str <MIN> <MAX>          Search for tip ammounts in that range
   --search_tokenrange
    -sn <MESSAGE>             Search for a message in tip comments
   --search_note <MESSAGE>
    -sa <MESSAGE>             Search the entire record for the message
   --search_all

Grouping/subtotaling
These options will print subtotals
    -gc                       Group by CamGirl
   --groupby-camgirl
    -gy                       Group by year
   --groupby-year
    -gm                       Group by month
   --groupby-month
    -gw                       Group by week
   --groupby-week
    -gd                       Group by day
   --groupby-day

Ranking (list highest to lowest)
    -rc                       Rank CamGirls by percentage of total tips they received
   --rank-camgirls

Other options
    -h                        Print this help text
    -v                        Verbose mode
    -r                        Print out all matching records, not just totals.  
    --print_records           If you add Buy or Balance lines to the input, it will display a running balance of tokens in the last field. 
                              Note that totals will be inaccurate if not all records match
    -nr                       Print out all non-matching records, not just totals.
    --print_reverse_records
    
Example lines to feed into -at or -rt (the Tip lines match the format of MFC's Token Usage report, with or without tip notes.  The Balance and Buy lines should be entered by hand):
Dec 13th, 2015, 11:05:16	Balance	none	30
Dec 13th, 2015, 11:05:16	Buy none	900
Dec 15th, 2015, 08:47:56	Tip	ModelOne	50	
Dec 15th, 2015, 08:48:56	Tip	ModelTwo	40
This is a tip note line, right after the tip line, just like in MFC's tip log
Dec 15th, 2015, 08:49:56	Tip	ModelThree	40
```
