#!/bin/bash

args=" $@ "

if [[ ! $1 = "" ]]; then
	domainName="$1"
else
	echo "No domain specified"
	exit 1
fi

regexArgRecordType=' -(-record|r) ([^ ]+) '
[[ $args =~ $regexArgRecordType ]]
if [ "${BASH_REMATCH[2]}" != "" ]; then
	searchRecordType="${BASH_REMATCH[2]}"
else
	searchRecordType="ANY"
fi

DIGOUTPUT=$(dig +nocmd +noall +answer "$domainName" "$searchRecordType")

declare -A recordTypes
declare -A records
declare -A recordsDomain
declare -A recordsTTL
declare -A recordsRelm
declare -A recordsType
declare -A recordsValue

declare -A recordColours
recordColours['A']="\e[34m"
recordColours['AAAA']="\e[36m"
recordColours['NS']="\e[95m"
recordColours['TXT']="\e[93m"
recordColours['SOA']="\e[32m"
recordColours['MX']="\e[91m"
recordColours['CNAME']="\e[94m"

recordID=0
tableData=""

# Check some records were returned
if [[ $DIGOUTPUT = "" ]]; then
	# Tell the user nothing was found
	if [[ $searchRecordType = "ANY" ]]; then
		echo "No DNS records were found for $domainName"
	else
		echo "No $searchRecordType DNS records were found for $domainName"
	fi
	exit 0
fi

# Count the number of records found
recordCount=$(echo "$DIGOUTPUT" | wc -l)

# Tell the user what we found
if [[ $searchRecordType = "ANY" ]]; then
	echo "Found $recordCount DNS records for $domainName"
else
	echo "Found $recordCount $searchRecordType records for $domainName"
fi

# Output the table headers
echo -e "Type\033[14GTTL\033[25GValue"

# Loop through each of the records returned from dig
while read -r record; do

	# Match this record using REGEX
	regexDNSRecord="^([[:alnum:]\-\.]+)[[:space:]]+([0-9]+)[[:space:]]+(IN)[[:space:]]+([[:alnum:]]+)[[:space:]]+(.+)$"
	[[ $record =~ $regexDNSRecord ]]

	# Check the record was matched
	if [[ ${BASH_REMATCH[0]} = "" ]]; then
		echo  -e "\e[41m Unknown record: '$record' \e[0m"
		continue
	fi

	# Add this records full details to the records associative array
	records[$recordID]="${BASH_REMATCH[0]}"

	# Add all this records details to associative arrays
	# Really wish BASH supported multi-dimensional arrays...
	recordsDomain[$recordID]="${BASH_REMATCH[1]}"
	recordsTTL[$recordID]="${BASH_REMATCH[2]}"
	recordsRelm[$recordID]="${BASH_REMATCH[3]}"
	recordsType[$recordID]="${BASH_REMATCH[4]}"
	recordsValue[$recordID]="${BASH_REMATCH[5]}"

	# Add this records ID to the record types associative array
	recordTypes["${BASH_REMATCH[4]}"]+="$recordID "

	# Increment the record counter
	recordID=$((recordID+1))

done <<< "$DIGOUTPUT"

# Loop through each of the record types we found
for recordType in "${!recordTypes[@]}"; do

	# Get all the record IDs for this type and create an array out of them
	recordTypeIDs=(${recordTypes[$recordType]})

	# Loop through each record ID for this record type
	for thisRecordID in "${recordTypeIDs[@]}"; do

		# Determine the colour this record should be
		recordColour="${recordColours[${recordsType[$thisRecordID]}]}"

		echo -e "$recordColour${recordsType[$thisRecordID]}\033[14G${recordsTTL[$thisRecordID]}\033[25G${recordsValue[$thisRecordID]}\e[0m"
	done
done