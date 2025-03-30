#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set default value if no argument is provided
MESSAGE_COUNT=${1:-500}

# Execute the ruby script using path relative to the script location
ruby "${SCRIPT_DIR}/../src/producers/sns/load-test.rb" $MESSAGE_COUNT
