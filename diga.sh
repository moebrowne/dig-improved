#!/bin/bash

DIGOUTPUT=$(dig +nocmd +noall +answer mountainofcode.co.uk ANY)

declare -A recordTypes
declare -A records

recordID=0
tableData=""

# Loop through each of the records returned from dig
while read -r record; do

	# Match this record using REGEX
	regexDNSRecord="^([[:alnum:]\-\.]+)[[:space:]]([0-9]+)[[:space:]](IN)[[:space:]]([[:alpha:]]+)[[:space:]](.+)$"
	[[ $record =~ $regexDNSRecord ]]

	# Add this records full details to the records associative array
	records[$recordID]="${BASH_REMATCH[0]}"

	# Add this records ID to the record types associative array
	recordTypes["${BASH_REMATCH[4]}"]+="$recordID "

	# Increment the record counter
	recordID=$((recordID+1))

done <<< "$DIGOUTPUT"

# Loop through each of the record types we found
for recordType in "${!recordTypes[@]}"; do

	# Get all the record IDs for this type
	recordTypeIDs=(${recordTypes[$recordType]})

	# Loop through each record ID for this record type
	for thisRecordID in "${recordTypeIDs[@]}"; do
		tableData="${records[$thisRecordID]}"
	done
done