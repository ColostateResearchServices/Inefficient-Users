#!/bin/bash

##
## FILE: merged_script.sh
##
## DESCRIPTION:
## This Script is used to get the number of service units used by the user/users and saves the user details who used less than 40k service units over a specified period.
##
## AUTHOR: Tharini Suresh
##
## DATE: 09/08/2024
## 
## VERSION: 1.1 (Modified)
##
## Usage
## To execute the code run : ./inefficient_users.sh num_months output_file_all.csv output_file_less_than_40k.csv 
## Example : ./inefficient_users.sh 6 all_uers.csv less_than_40k.csv 
## Here num_months is the number of past months to fetch data, output_file_all stores the service units of all users, and output_file_less_than_40k stores the users who used less than 40K service units.
##

# Check if the required arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 num_months output_file_all output_file_less_than_40k"
    exit 1
fi

# Get the number of months from the argument
num_months=$1

# Output file to save the SUs of all users
OUTPUT_FILE_ALL=$2

# Output file to save the users with less than 40,000 SUs
OUTPUT_FILE_LESS_THAN_40K=$3

# Temporary file to store users with less than 40,000 SUs
TEMP_FILE=$(mktemp)

# Get the current date
current_date=$(date +%Y-%m-%d)

# Create a CSV file and write the header
echo "User,Account" > csu_users.csv

# Loop through each past month
for ((i = 0; i < num_months; i++)); do
    # Calculate the start and end dates for the current month
    start_date=$(date -d "$current_date - $i months" +%Y-%m-01)
    end_date=$(date -d "$start_date + 1 month - 1 day" +%Y-%m-%d)

    # Run the command for the current month and append the output to the CSV file
    sacct --allusers --starttime="$start_date"T00:00:00 --endtime="$end_date"T23:59:59 -X -p --format=user | grep -i colostate | uniq >> csu_users.csv
done

# Clear the output files if they exist, or create them if they don't
> $OUTPUT_FILE_ALL
> $OUTPUT_FILE_LESS_THAN_40K

# Mock function to simulate fetching service units for a user
get_su_data() {
    local user=$1
    local days=90
    # Simulate output format: username|service_units
    echo "$user|$((RANDOM % 50000))"
}

# Loop through each user in the generated CSV file
tail -n +2 csu_users.csv | while IFS=, read -r USER ACCOUNT; do
    # Fetch the Service Units for the user over the last 90 days
    OUTPUT=$(get_su_data $USER)

    # Output the fetched service units to the all users file
    echo "$OUTPUT" >> $OUTPUT_FILE_ALL

    # Check if used SUs is less than 40,000 and save to temporary file
    if echo "$OUTPUT" | awk -F'|' '$2 < 40000' | grep -q "."; then
        echo "$OUTPUT" | awk -F'|' '{print $1 "," $2}' >> $TEMP_FILE
    fi
done

# Print users with less than 40,000 SUs to the output file
echo "Users with less than 40,000 SUs:" >> $OUTPUT_FILE_LESS_THAN_40K
cat $TEMP_FILE >> $OUTPUT_FILE_LESS_THAN_40K

# Clean up temporary file
rm $TEMP_FILE

echo "Service Units data saved to $OUTPUT_FILE_ALL"
echo "Users with less than 40,000 SUs saved to $OUTPUT_FILE_LESS_THAN_40K"
