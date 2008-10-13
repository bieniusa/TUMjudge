#!/bin/bash
# $Id$

# Script to compare output from different solutions.
# Written by Jaap Eldering, April 2004
#
# Run this script in a problem-directory. Expects testdata
# input in 'testdata.in' and output in 'testdata.out'.
# Solutions must be of the form '<username>*.<langext>'
#
# Optionally the timelimit may be specified as argument.
#

# Extended pattern matching:
shopt -s extglob

USERS="jaap peter thijs test"

NLANG=5
LANG=('c' 'cpp'        'java' 'pascal'   'haskell')
EXTS=('c' 'cpp cc c++' 'java' 'pas pp p' 'hs'     )
ALLEXTS="${EXTS[@]}"

TESTSOL=$HOME/system/judge/test_solution.sh

TESTIN=testdata.in
TESTOUT=testdata.out
SAMPLEIN=testsample.in
SAMPLEOUT=testsample.out

TMPDIR="compare.$$.tmp"
TIMELIMIT=20
ALLOK=1

if [ "$1" ]; then
	TIMELIMIT="$1"
fi

if [ "$VERBOSE" ]; then
	[[ "$VERBOSE" = [2-7] ]] || VERBOSE=7 # loglevel LOG_DEBUG
	export VERBOSE
fi

if [ "$DEBUG" ]; then
	export DEBUG
fi

test_sol ()
{
	local lang base="" file="$1" in="$2" out="$3"
	# First determine language:
	for ((i=0; i<NLANG; i++)); do
		for ext in ${EXTS[$i]}; do
			if [[ "$file" = *.$ext ]]; then
				base="${file%.$ext}"
				lang="$i"
				break 2
			fi
		done
	done
	if [ -z "$base" ]; then
		echo "Could not determine language!?"
		exit 1
	fi

	mkdir "$TMPDIR/$file"
	$TESTSOL "$file" "${LANG[$lang]}" "$in" "$out" "$TIMELIMIT" "$TMPDIR/$file"
	exitcode=$?
	if [ $exitcode -ne 0 ]; then
		ALLOK=0
		printf "Error: "
		case $exitcode in
		1) echo "compile";;
		2) echo "timelimit";;
		3) echo "runtime error";;
		4) echo "no output";;
		5) echo "wrong answer";;
		*) echo "script error $exitcode";;
		esac
	else
		printf "Correct, runtime: %s\n" `cat $TMPDIR/$file/program.time`
	fi

}

[ -r "$TESTIN"    ] || { echo "No input testdata found."; exit 1; }
[ -r "$TESTOUT"   ] || { echo "No output testdata found."; exit 1; }
[ -r "$SAMPLEIN"  ] || { echo "No input sample testdata found."; exit 1; }
[ -r "$SAMPLEOUT" ] || { echo "No output sample testdata found."; exit 1; }

printf "Supported languages:"
for((i=0; i<NLANG; i++)); do printf " ${LANG[$i]},"; done
echo

# As extra information:
printf 'Checking %-15s   ' "$TESTIN"
checkinput $TESTIN || ALLOK=0
printf 'Checking %-15s   ' "$SAMPLEIN"
checkinput $SAMPLEIN || ALLOK=0

# Make a pattern string to match solutions with:
FILEMATCH="^("
for user in $USERS;   do FILEMATCH="${FILEMATCH}$user|"; done
FILEMATCH="${FILEMATCH%|}).*\\.("
for ext  in $ALLEXTS; do FILEMATCH="${FILEMATCH}$ext|";  done
FILEMATCH="${FILEMATCH%|})$"

mkdir $TMPDIR
# Loop through all solutions:
FIRST=1
for file in `ls | grep -E $FILEMATCH`; do
	if [ $FIRST = 1 ]; then
		FIRST=0
		printf '%-50s' "Testing sample testdata..."
		[ "$VERBOSE" ] && echo
		samplesol="sample-sol.${file##*.}"
		ln -s -f "$file" "$samplesol"
		test_sol "$samplesol" "$SAMPLEIN" "$SAMPLEOUT"
	fi
	printf '%-50s' "Testing solution '$file'... "
	[ "$VERBOSE" ] && echo
	test_sol "$file" "$TESTIN" "$TESTOUT"
done

[ "$DEBUG" ] || rm -rf "$TMPDIR" "$samplesol"

[ $ALLOK = 1 ] && exit 0

echo "There were errors!"
exit 1