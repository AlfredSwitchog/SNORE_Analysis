#!/bin/bash

# Example usage: ./run_segmentT1.sh 101

# Get participant ID from command-line argument
PARTICIPANT_ID=$1

# Check that a participant ID was provided
if [ -z "$PARTICIPANT_ID" ]; then
  echo "Usage: $0 <participant_id>"
  exit 1
fi

# Run MATLAB with the segmentT1 function
matlab -nodisplay -nosplash -r "try, segmentT1($PARTICIPANT_ID); catch e, disp(getReport(e)), exit(1); end; exit(0);"
