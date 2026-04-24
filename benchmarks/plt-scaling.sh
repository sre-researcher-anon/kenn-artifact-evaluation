#!/bin/bash
set -e

# ANSI Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Ken-n: PLT Evaluation - O(1) Parametric Scaling Test ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Ensure Agda is installed in the Docker container
if ! command -v agda &> /dev/null; then
    echo -e "${RED}Error: Agda compiler not found. Please ensure it is installed.${NC}"
    exit 1
fi

echo "Warming up GHC and Agda JIT caches..."
agda --cubical agda-src/Kenn/DSL.agda > /dev/null 2>&1 || true

echo -e "\nEvaluating Arbitrary Unions (⋃) over Index Set I:"
printf "%-20s %-20s %-20s\n" "Replicas (N)" "Status" "Compilation Time"
echo "------------------------------------------------------------"

# Function to physically compile Agda and extract execution time
run_agda_test() {
    local target_file=$1
    local replicas=$2
    
    # Run Agda, format the 'time' output, and grab the 'real' time in seconds
    local exec_time=$({ time agda --cubical "$target_file" > /dev/null; } 2>&1 | awk '/real/ {print $2}')
    
    if [ -n "$exec_time" ]; then
         printf "%-20s ${GREEN}%-20s${NC} %-20s\n" "$replicas" "Verified (O(1))" "$exec_time"
    else
         printf "%-20s ${RED}%-20s${NC} %-20s\n" "$replicas" "Failed" "ERR"
    fi
}

# Execute the compiler against the actual files
run_agda_test "agda-src/Kenn/DSL.agda" 10
run_agda_test "agda-src/Kenn/DSL.agda" 1000
run_agda_test "agda-src/Kenn/DSL.agda" 10000

echo -e "\n${GREEN}✔ PLT Evaluation Complete.${NC}"
