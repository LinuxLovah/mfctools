#!/bin/bash

# Configuration
TIPTOOL_HOME="${HOME}/.tiptool"
# How many tokens do you buy in a package at a time?
TOKEN_PURCHASE_COUNT=900
# How much does that package cost?
TOKEN_PURCHASE_COST=74.99


# Globals
# Array of months to turn names into numbers
MONTHS=(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
TOKEN_COST=`echo "${TOKEN_PURCHASE_COST} / ${TOKEN_PURCHASE_COUNT}" | bc -l`
CMDNAME=`basename $0`


# Functions
function usage() {
	cat << HELPHEREDOC

${CMDNAME}
Stores MyFreeCams tips and performs statistical reporting.
Tip information is stored in ${TIPFILE}

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
                              If you add Buy or Balance lines to the input, it will display a running balance of tokens in the last field. 
                              Note that totals will be inaccurate if not all records match
    
Example lines to feed into -at or -rt (the Tip lines match the format of MFC's Token Usage report, with or without tip notes.  The Balance and Buy lines should be entered by hand):
Dec 13th, 2015, 11:05:16	Balance	none	30
Dec 13th, 2015, 11:05:16	Buy none	900
Dec 15th, 2015, 08:47:56	Tip	ModelOne	50	
Dec 15th, 2015, 08:48:56	Tip	ModelTwo	40
This is a tip note line, right after the tip line, just like in MFC's tip log
Dec 15th, 2015, 08:49:56	Tip	ModelThree	40


HELPHEREDOC
exit
}


function calcPercent() {
	printf '%7.0f' `echo "( (${1} * 100) / (${2} * 100) ) * 100" | bc -l`
}

function calcCost() {
	echo "${1} * ${TOKEN_COST}" | bc -l
}

# Params: title matchCount matchTokens groupByCount
function printStats() {
	printf '\n=== %s\n' "${1}"
	printf '            Count          Tokens         Dollars\n'
	printf 'Match     %7d         %7d         %7.2f\n' ${2} ${3} `calcCost ${3}`
	printf 'Total     %7d         %7d         %7.2f\n' $totalCount $totalTokens `calcCost ${totalTokens}`
	printf 'Percent   %7.0f         %7.0f      %7.0f\n' `calcPercent ${2} ${totalCount}` `calcPercent ${3} ${totalTokens}`  `calcPercent ${3} ${totalTokens}`

	if [ ${4} -gt 0 ]
	then
		printf 'Average   %7d         %7d          %7.2f\n' $((${2} / ${4})) $((${3} / ${4})) `calcCost $((${3} / ${4}))`
	fi
}

function printSubStatsHeading() {
	printf '  Count        %%   Tokens        %%   Dollars  == %s\n' "${1}"
}

# Params: title matchCount matchTokens
function printSubStats() {
	printf '%7d  %7.0f  %7d  %7.0f   %7.2f  == %s\n' ${2}  `calcPercent ${2} ${totalCount}` ${3}  `calcPercent ${3} ${totalTokens}` `calcCost ${3}` "${1}"
}

# Params: title matchTokens
function printRankStats() {
	printf '%7d tokens     %7.0f%%     $%7.2f     %s\n' "${2}" `calcPercent ${2} ${totalTokens}` `calcCost ${2}` "${1}"
}

# Add a tip read in from the input to the tip file
function addTip() {
	if [ "${DEBUG_MODE}" != "" ] ; then
		echo "     addTip [${year}|${month}|${day}|${time}|${type}|${camgirl}|${tokens}|${note}]"
	fi
	if [[ "${year}" != "" ]] ; then
		year=`echo ${year} | tr -d '[,]'`
		year=`printf '%04d' ${year}`

		monthNo=0
		currentMonthNo=0
		for currentMonthName in "${MONTHS[@]}" ; do
			currentMonthNo=$((${currentMonthNo} + 1))
			if [ "${month}" = "${currentMonthName}" ]; then
				monthNo=`printf '%02d' ${currentMonthNo}`
				break
			fi
		done

		if [ ${monthNo} -eq 0 ] ; then
			if [ "${DEBUG_MODE}" != "" ] ; then
				echo "      Bad month, skipping"
			fi
		fi

		day=`echo ${day} | tr -d '[a-z,]'`
		day=`printf '%02d' ${day}`

		time=`echo ${time} | tr ':' '\t'`

		if [ "${DEBUG_MODE}" != "" ] ; then
			echo "WRITING [${monthNo}|${day}|${year}|${time}|${type}|${camgirl}|${tokens}|${note}] row ${count}"
		fi
		echo -e "${year}\t${monthNo}\t${day}\t${time}\t${type}\t${camgirl}\t${tokens}\t${note}" >> "${TMPTIPFILE}"

		count=$(($count + 1))
	else
		if [ "${DEBUG_MODE}" != "" ] ; then
			echo "      Empty year, skipping"
		fi
	fi
}

# Read lines from stdin
# Since we may have tip lines, and won't know it until after the data, we have to process each line after reading the next and
# determining what kind of line it is
function addTips() {
	echo "Adding rows"
	if [[ -f "${TIPFILE}" ]] ; then
		cp "${TIPFILE}" "${TMPTIPFILE}"
	else
		rm -f "${TMPTIPFILE}"
	fi

	count=0
	read -a lineIn
	#while read month day year time type camgirl tokens extra
	while [[ "${lineIn[0]}" != "" ]]
	do
		if [ "${DEBUG_MODE}" != "" ] ; then
			echo "READING [${lineIn[*]}]"
		fi

		# Identify the kind of line last read
		if [[ ${lineIn[4]} =~ "(Buy|Balance)" ]] ; then
			addTip
			month=${lineIn[0]}
			day=${lineIn[1]}
			year=${lineIn[2]}
			time=${lineIn[3]}
			type=${lineIn[4]}
			camgirl="none"
			tokens=${lineIn[5]}
			note="none"
		elif [[ ${lineIn[0]} =~ [A-Z][a-z][a-z] &&  ${lineIn[1]} =~ [0-9][0-9stndrd,]+ &&  ${lineIn[2]} =~ [0-9]{4}[,] ]] ; then
			addTip
			month=${lineIn[0]}
			day=${lineIn[1]}
			year=${lineIn[2]}
			time=${lineIn[3]}

			# The type field can have spaces in it, so however many fields past 7 there are, we need to add them to type
			fieldPtr=4
			typeFieldLast=$((${#lineIn[*]} - 3))
			# There will be an extra field for public/private if type is Transfer
			if [[ "${lineIn[5]}" == "Transfer" ]] ; then
				typeFieldLast=$((typeFieldLast - 1))
				if [ "${DEBUG_MODE}" != "" ] ; then
					echo "     Transfer record, decrementing last to ${typeFieldLast}"
				fi
			fi
			if [ "${DEBUG_MODE}" != "" ] ; then
				echo "     Tip fields: ${fieldPtr} / ${typeFieldLast}, ${#lineIn[*]} total fields"
			fi

			type=""
			while [[ ${fieldPtr} -le ${typeFieldLast} ]] ; do
				type="${type}${lineIn[$fieldPtr]}"
				if [ "${DEBUG_MODE}" != "" ] ; then
					echo "     Tip field ${fieldPtr} / ${typeFieldLast} now '${type}'"
				fi
				fieldPtr=$((fieldPtr + 1))
			done
			# Remove spaces in type
			type=`echo $type | tr -d ' '`

			camgirl=${lineIn[$fieldPtr]}
			fieldPtr=$((fieldPtr + 1))
			tokens=${lineIn[$fieldPtr]}
			note=""
		else
			if [ "${DEBUG_MODE}" != "" ] ; then
				echo "     Tip note line"
			fi
			note="${lineIn[*]}"
			# This record will be written on the next read, so don't addTip here
		fi

		read -a lineIn
	done

	# Process the last line
	addTip

	# Make sure we have sorted rows
	# We can't sort unique to elimiate duplicate adds in case there are multiple tips in the same second
	sort  < "${TMPTIPFILE}" > "${TIPFILE}"

	echo "${count} rows added, "`wc -l "${TIPFILE}"`" total"
	exit
}

# Deletes tips before adding
function replaceTips() {
	echo "Removing existing rows"

	if [[ -f "${TIPFILE}" ]] ; then
		rm "${TIPFILE}"
	fi
	if [[ -f "${TMPTIPFILE}" ]] ; then
		rm "${TMPTIPFILE}"
	fi
	addTips
}

# Create data directory
if [[ ! -d "${TIPTOOL_HOME}" ]] ; then
	mkdir -p "${TIPTOOL_HOME}"
	if [[ ! -d "${TIPTOOL_HOME}" ]] ; then
		echo "Cannot create '${TIPTOOL_HOME}'. Exiting."
		exit
	fi
fi
TIPFILE="${TIPTOOL_HOME}/tips.txt"
TMPTIPFILE="${TIPFILE}.tmp"
RANKTIPFILE="${TIPFILE}.rank"


while [[ $# -gt 0 ]]
do
	key="$1"
	shift
	if [ "${DEBUG_MODE}" != "" ] ; then
		echo "     Option is ${key}"
	fi
	case ${key} in
		-sy|--search_year)
			SEARCH_YEAR="$1"
			shift
			;;
		-sm|--search_month)
			SEARCH_MONTH="$1"
			shift
			;;
		-sd|--search_day)
			SEARCH_DAY="$1"
			shift
			;;
		-st|--search_type)
			SEARCHTYPE="$1"
			shift
			;;
		-sc|--search_camgirl)
			SEARCH_CAMGIRL="$1"
			shift
			;;
		-str|--search_tokenrange)
			SEARCH_TOKENRANGE=1
			SEARCH_TOKENRANGE_MIN=$1
			shift
			SEARCH_TOKENRANGE_MAX=$1
			shift
			;;
		-sn|--search_note)
			SEARCH_NOTE="$1"
			shift
			;;
		-sa|--search_ALL)
			SEARCH_ALL="$1"
			shift
			;;
		-r|--PRINT_RECORDS)
			PRINT_RECORDS=1
			;;
		-gc|--groupby-camgirl)
			GROUPBYCAMGIRL=1
			declare -A gbCamGirlCount
			declare -A gbCamGirlTokens
			;;
		-gy|--groupby-year)
			GROUPBYYEAR=1
			declare -A gbYearCount
			declare -A gbYearTokens
			;;
		-gm|--groupby-month)
			GROUPBYMONTH=1
			declare -A gbMonthCount
			declare -A gbMonthTokens
			;;
		-gw|--groupby-week)
			GROUPBYWEEK=1
			declare -A gbWeekCount
			declare -A gbWeekTokens
			;;
		-gd|--groupby-day)
			GROUPBYDAY=1
			declare -A gbDayCount
			declare -A gbDayTokens
			;;
		-rc|--rank-camgirls)
			RANKCAMGIRLS=1
			declare -A gbCamGirlCount
			declare -A gbCamGirlTokens
			;;
		-at|--add-tips)
			addTips
			;;
		-rt|--replace-tips)
			replaceTips
			;;
		-h|--help)
			usage
			;;
		-v|--verbose)
			DEBUG_MODE=1
			echo "     Verbose mode"
			;;
		*)
			# unknown option
			echo "Unknown option '${key}'"
			;;
	esac
done


# Read each record and process it
matchCount=0
matchTokens=0
groupByCount=0
balance=0

while read year month day hour minute second type camgirl tokens note
do
	# Does this record match the filter criteria?
	isMatch=1
	if [[ "${SEARCH_YEAR}" != "" && ! ${year} =~ ${SEARCH_YEAR} ]] ; then
		isMatch=0
	fi
	if [[ "${SEARCH_MONTH}" != "" && ! ${month} =~ ${SEARCH_MONTH} ]] ; then
		isMatch=0
	fi
	if [[ "${SEARCH_DAY}" != "" && ! ${day} =~ ${SEARCH_DAY} ]] ; then
		isMatch=0
	fi
	if [[ "${SEARCHTYPE}" != "" && ! ${type} =~ ${SEARCHTYPE} ]] ; then
		isMatch=0
	fi
	if [[ "${SEARCH_CAMGIRL}" != "" && ! ${camgirl} =~ ${SEARCH_CAMGIRL} ]] ; then
		isMatch=0
	fi
	if [[ "${SEARCH_TOKENRANGE}" != "" && ( ${tokens} -lt ${SEARCH_TOKENRANGE_MIN} || ${tokens} -gt ${SEARCH_TOKENRANGE_MAX}  ) ]] ; then
		isMatch=0
	fi
	if [[ "${SEARCH_NOTE}" != "" && ! ${note} =~ ${SEARCH_NOTE} ]] ; then
		isMatch=0
	fi
	if [[ "${SEARCH_ALL}" != "" && ! "$year $month $day $hour $minute $second $type $camgirl $tokens $note" =~ ${SEARCH_ALL} ]] ; then
		isMatch=0
	fi


	# Process the record
	if [[ $isMatch -eq 1 ]] ; then
		if [[ "${type}" == "Buy" ]] ; then
			balance=$((balance + $tokens))
		elif [[ "${type}" == "Balance" ]] ; then
			balance="${tokens}"
		elif [[ "${type}" == "Transfer" ]] ; then
			balance=$((balance - $tokens))
		elif [[ "${type}" == "Tip" || "${type}" == "GroupShow" || "${type}" == "Private" || "${type}" == "Voyeur" ]] ; then
			matchCount=$(($matchCount + 1))
			matchTokens=$(($matchTokens + $tokens))
			balance=$((balance - $tokens))
	
			# Grouping operations
			if [[ ${GROUPBYYEAR} -eq 1 ]] ; then
				gbYearCount[${year}]=$((gbYearCount[${year}] + 1))
				gbYearTokens[${year}]=$((gbYearTokens[${year}] + $tokens))
			fi
			if [[ ${GROUPBYMONTH} -eq 1 ]] ; then
				gbMonthCount[${year}.${month}]=$((gbMonthCount[${year}.${month}] + 1))
				gbMonthTokens[${year}.${month}]=$((gbMonthTokens[${year}.${month}] + $tokens))
			fi
			if [[ ${GROUPBYWEEK} -eq 1 ]] ; then
				week=`date -d "${year}${month}${day}" '+%U'`
				gbWeekCount[${year}.${week}]=$((gbWeekCount[${year}.${week}] + 1))
				gbWeekTokens[${year}.${week}]=$((gbWeekTokens[${year}.${week}] + $tokens))
			fi
			if [[ ${GROUPBYDAY} -eq 1 ]] ; then
				gbDayCount[${year}.${month}.${day}]=$((gbDayCount[${year}.${month}.${day}] + 1))
				gbDayTokens[${year}.${month}.${day}]=$((gbDayTokens[${year}.${month}.${day}] + $tokens))
			fi
			if [[ ${GROUPBYCAMGIRL} -eq 1 || ${RANKCAMGIRLS} -eq 1 ]] ; then
				gbCamGirlCount[$camgirl]=$((gbCamGirlCount[$camgirl] + 1))
				gbCamGirlTokens[$camgirl]=$((gbCamGirlTokens[$camgirl] + $tokens))
			fi
		fi

		# No negative balance
		if [[ ${balance} -lt 0 ]] ; then
			balance=0
		fi
		if [[ $PRINT_RECORDS -eq 1 ]] ; then
			echo "[$year|$month|$day|$hour|$minute|$second|$type|$camgirl|$tokens|$note|$balance]"
		fi
	fi
	totalCount=$(($totalCount + 1))
	totalTokens=$(($totalTokens + $tokens))
	
done < "${TIPFILE}"

# Print date groupings
if [[ ${GROUPBYYEAR} -eq 1 ]] ; then
	printSubStatsHeading  "Tips Grouped By Year"
	for key in `echo ${!gbYearCount[*]} | tr ' ' '\n' | sort`
	do
		printSubStats "Year ${key}" ${gbYearCount[$key]} ${gbYearTokens[$key]}
	done
	groupByCount=${#gbYearCount[@]}
fi
if [[ ${GROUPBYMONTH} -eq 1 ]] ; then
	printSubStatsHeading  "Tips Grouped By Month"
	for key in `echo ${!gbMonthCount[*]} | tr ' ' '\n' | sort`
	do
		printSubStats "Month ${key}" ${gbMonthCount[$key]} ${gbMonthTokens[$key]}
	done
	groupByCount=${#gbMonthCount[@]}
fi
if [[ ${GROUPBYWEEK} -eq 1 ]] ; then
	printSubStatsHeading  "Tips Grouped By Week"
	for key in `echo ${!gbWeekCount[*]} | tr ' ' '\n' | sort`
	do
		printSubStats "Week ${key}" ${gbWeekCount[$key]} ${gbWeekTokens[$key]}
	done
	groupByCount=${#gbWeekCount[@]}
fi
if [[ ${GROUPBYDAY} -eq 1 ]] ; then
	printSubStatsHeading  "Tips Grouped By Day"
	for key in `echo ${!gbDayCount[*]} | tr ' ' '\n' | sort`
	do
		printSubStats "Day ${key}" ${gbDayCount[$key]} ${gbDayTokens[$key]}
	done
	groupByCount=${#gbDayCount[@]}
fi

# Print camgirl groupings
if [[ ${GROUPBYCAMGIRL} -eq 1 ]] ; then
	printSubStatsHeading "Tips Grouped By Camgirl"
	for key in `echo ${!gbCamGirlCount[*]} | tr ' ' '\n' | sort`
	do
		printSubStats "Camgirl ${key}" ${gbCamGirlCount[$key]} ${gbCamGirlTokens[$key]}
	done
	groupByCount=${#gbCamGirlCount[@]}
fi

# Print camgirl rank
if [[ ${RANKCAMGIRLS} -eq 1 ]] ; then
	printf '\n=== Top Tipped Camgirls\n'
	cp /dev/null ${RANKTIPFILE}
	for key in `echo ${!gbCamGirlTokens[*]} | tr ' ' '\n' | sort`
	do
		printRankStats "${key}" ${gbCamGirlTokens[$key]} >>  ${RANKTIPFILE}
	done
	groupByCount=${#gbCamGirlTokens[@]}
	cat ${RANKTIPFILE} | sort -n -r -b | nl -s " " -b a -n rn
fi

# Print totals
printStats "TOTALS" ${matchCount} ${matchTokens} ${groupByCount}



