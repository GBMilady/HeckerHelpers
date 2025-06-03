#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
DICT="doge_ext.dict"
APPENDAGES="appendages.txt"
SUFFIX_MASK="doge_suffix.mask"
PREFIX_MASK="doge_prefix.mask"
BRUTE_MASK_CHARSET='?d!@#$%^&*()_-'
GPU_DEVICES="1,2"
HASHFILE="wallet.hash"
HASH_MODE="11300"  # Bitcoin/Litecoin wallet.dat
STATUS_TIMER=30
MIN_BRUTE_LEN=1
MAX_BRUTE_LEN=8
POTFILE="hashcat.potfile"
CUSTOM_RULES="custom_rules.rule"
COMPREHENSIVE_RULES="rules/best64.rule"  # Adjust path if needed
HASHCAT_ENABLED=1
JOHN_ENABLED=1

# Parse command-line arguments to disable tools
for arg in "$@"; do
  if [ "$arg" = "--no-hashcat" ]; then
    HASHCAT_ENABLED=0
  elif [ "$arg" = "--no-john" ]; then
    JOHN_ENABLED=0
  fi
done

# Check if at least one tool is enabled
if [ $HASHCAT_ENABLED -eq 0 ] && [ $JOHN_ENABLED -eq 0 ]; then
  echo "Error: Both hashcat and John the Ripper are disabled. Please enable at least one tool."
  exit 1
fi

# Install tools if missing
if [ $HASHCAT_ENABLED -eq 1 ] && ! command -v hashcat &> /dev/null; then
  echo "Installing hashcat..."
  sudo apt update
  sudo apt install hashcat -y
fi

if [ $JOHN_ENABLED -eq 1 ] && ! command -v john &> /dev/null; then
  echo "Installing John the Ripper..."
  sudo apt update
  sudo apt install john -y
fi

if [ $HASHCAT_ENABLED -eq 1 ] || [ $JOHN_ENABLED -eq 1 ]; then
  if ! command -v tmux &> /dev/null; then
    echo "Installing tmux..."
    sudo apt update
    sudo apt install tmux -y
  fi
fi

# -----------------------------
# STEP 1: Generate Dictionary
# -----------------------------
cat <<EOF > "$DICT"
doge
Dog3
D0ge
dog3
Doge
doge1
doge12
doge13
doge123
doge2013
Doge1
Doge12
Doge13
Doge123
Doge2013
dog31
dog312
dog313
dog3123
dog32013
Dog31
Dog312
Dog313
Dog3123
Dog32013
D0ge1
D0ge12
D0ge13
D0ge123
D0ge2013
!doge
doge!
!Doge
Doge!
!D0ge
D0ge!
!dog3
dog3!
!Dog3
Dog3!
!D0ge13
D0ge13!
!D0ge2013
D0ge2013!
!Dog3!
!Doge123!
!Doge13!
!doge13!
doge13!
D0g3
D0g3!
!D0g3
D0g3!
Doge123!
!Doge123
Dog3
Dog3!
!Dog3
doge123!
!doge123
D0g3r
D0g3r!
!D0g3r
doge$
doge123$
!doge123$
Doge_
Doge123_
!Doge123_
doge2014
Doge2014
!doge2014
doge2014!
d0ge2014
D0ge2014
dog32014
Dog32014
d0g32014
D0g32014
doge1232014
Doge1232014
!doge1232014
doge1232014!
doge2014$
Doge2014$
!doge2014!
!Doge2014!
d0g3r2014
D0g3r2014
!d0g3r2014
d0g3r2014!
doge#2014
Doge#2014
EOF
echo "[+] Created dictionary '$DICT' with $(wc -l < "$DICT") entries."

# -----------------------------
# STEP 2: Create Suffix Mask
# -----------------------------
cat <<EOF > "$SUFFIX_MASK"
?d
?d?d
?d?d?d
?d?d?d?d
?d?d?d?d?d
2013
13
123
!1
!12
!123
!2013
$1
$12
$123
@123
_123
#123
2014
!2014
$2014
@2014
_2014
#2014
$
$$
#
##
EOF
echo "[+] Created suffix mask '$SUFFIX_MASK'."

# -----------------------------
# STEP 3: Create Prefix Mask
# -----------------------------
cat <<EOF > "$PREFIX_MASK"
!
!?
!??
!?d
!?d?d
!@#
@!$
@12
@123
_123
!2013
$123
!D
@D
#D
2014!
2014@
2014#
!2014
@2014
#2014
$
@
#
EOF
echo "[+] Created prefix mask '$PREFIX_MASK'."

# -----------------------------
# STEP 4: Create Custom Rules for hashcat
# -----------------------------
cat <<EOF > "$CUSTOM_RULES"
:
^D
e3
o0
s$
$2 $0 $1 $4
^2 ^0 ^1 ^4
$!
^!
EOF
echo "[+] Created custom rules file '$CUSTOM_RULES'."

# -----------------------------
# STEP 5: Create Appendages for Combinator Attack
# -----------------------------
echo -e "0\n1\n2\n3\n4\n5\n6\n7\n8\n9" > "$APPENDAGES"
for i in {00..99}; do echo "$i" >> "$APPENDAGES"; done
for i in {2000..2020}; do echo "$i" >> "$APPENDAGES"; done
echo -e "!\n@\n#\n$\n%\n^\n&\n*\n(\n)\n_\n-\n+\n=\n.\n," >> "$APPENDAGES"
echo -e "!2013\n@2014\n#2013\n$2014\n!123\n@123\n#123\n$123\n!!\n@@" >> "$APPENDAGES"
echo "[+] Created appendages file '$APPENDAGES' with $(wc -l < "$APPENDAGES") entries."

# -----------------------------
# STEP 6: Create Custom Rules for John the Ripper
# -----------------------------
cat <<EOF > custom.rules
[List.Rules:Custom]
:
c
so0
se3
ss$
^!
$!
^2^0^1^3
$2$0$1$3
^2^0^1^4
$2$0$1$4
c $!
c $2$0$1$3
so0 $!
se3 $2$0$1$4
EOF
echo "[+] Created John the Ripper custom rules file 'custom.rules'."

# -----------------------------
# Wallet Hash
# -----------------------------
echo "\$bitcoin\$64\$f6b24eafc850333525e39649de8add88b349a05d7d0d7a04839557ef87b252f0\$16\$0b150e0714a91842\$77315\$2\$00\$2\$00" > "$HASHFILE"
echo "[+] Saved wallet hash to '$HASHFILE'."

# -----------------------------
# Helper Functions for hashcat
# -----------------------------
is_cracked() {
  local output=$(hashcat --show -m "$HASH_MODE" "$HASHFILE" --potfile-path "$POTFILE")
  if [ -n "$output" ]; then
    HASHCAT_PASSWORD_FOUND=$(echo "$output" | cut -d: -f2-)
    HASHCAT_CRACKED=true
  else
    HASHCAT_CRACKED=false
  fi
}

run_hashcat() {
  local phase=$1
  local use_S=$2
  shift 2

  if $HASHCAT_CRACKED; then
    echo "[-] Skipping $phase (password already found by hashcat)"
    return
  fi

  echo "[+] Starting $phase"
  start_time=$(date +%s)

  if $use_S; then
    hashcat -m "$HASH_MODE" "$@" --session "$phase" --potfile-path "$POTFILE" \
            -w 3 --optimized-kernel-enable --status --status-timer="$STATUS_TIMER" \
            -d "$GPU_DEVICES" -S
  else
    hashcat -m "$HASH_MODE" "$@" --session "$phase" --potfile-path "$POTFILE" \
            -w 3 --optimized-kernel-enable --status --status-timer="$STATUS_TIMER" \
            -d "$GPU_DEVICES"
  fi

  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "[+] $phase completed in $duration seconds"
  is_cracked
}

# -----------------------------
# Helper Functions for John the Ripper
# -----------------------------
is_john_cracked() {
  local output=$(john --show "$HASHFILE" | grep -v "0 password hashes cracked")
  if [ -n "$output" ]; then
    JOHN_PASSWORD_FOUND=$(echo "$output" | head -n 1 | cut -d: -f2)
    JOHN_CRACKED=true
  else
    JOHN_CRACKED=false
  fi
}

# -----------------------------
# Main Execution
# -----------------------------
SCRIPT_START_TIME=$(date +%s)
HASHCAT_CRACKED=false
JOHN_CRACKED=false
HASHCAT_PASSWORD_FOUND=""
JOHN_PASSWORD_FOUND=""

# Create a wrapper script for hashcat to run all phases
cat <<'EOF' > run_hashcat_phases.sh
#!/bin/bash

# Import configuration from parent script
DICT="doge_ext.dict"
APPENDAGES="appendages.txt"
SUFFIX_MASK="doge_suffix.mask"
PREFIX_MASK="doge_prefix.mask"
BRUTE_MASK_CHARSET='?d!@#$%^&*()_-'
GPU_DEVICES="1,2"
HASHFILE="wallet.hash"
HASH_MODE="11300"
STATUS_TIMER=30
MIN_BRUTE_LEN=1
MAX_BRUTE_LEN=8
POTFILE="hashcat.potfile"
CUSTOM_RULES="custom_rules.rule"
COMPREHENSIVE_RULES="rules/best64.rule"

is_cracked() {
  local output=$(hashcat --show -m "$HASH_MODE" "$HASHFILE" --potfile-path "$POTFILE")
  if [ -n "$output" ]; then
    HASHCAT_PASSWORD_FOUND=$(echo "$output" | cut -d: -f2-)
    HASHCAT_CRACKED=true
  else
    HASHCAT_CRACKED=false
  fi
}

run_hashcat() {
  local phase=$1
  local use_S=$2
  shift 2

  if $HASHCAT_CRACKED; then
    echo "[-] Skipping $phase (password already found by hashcat)"
    return
  fi

  echo "[+] Starting $phase"
  start_time=$(date +%s)

  if $use_S; then
    hashcat -m "$HASH_MODE" "$@" --session "$phase" --potfile-path "$POTFILE" \
            -w 3 --optimized-kernel-enable --status --status-timer="$STATUS_TIMER" \
            -d "$GPU_DEVICES" -S
  else
    hashcat -m "$HASH_MODE" "$@" --session "$phase" --potfile-path "$POTFILE" \
            -w 3 --optimized-kernel-enable --status --status-timer="$STATUS_TIMER" \
            -d "$GPU_DEVICES"
  fi

  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "[+] $phase completed in $duration seconds"
  is_cracked
}

HASHCAT_CRACKED=false
HASHCAT_PASSWORD_FOUND=""

# Phase 0: Pure Dictionary Attack
run_hashcat "Phase0_Pure_Dict" false -a 0 "$HASHFILE" "$DICT"

# Phase 1: Dictionary with Custom Rules
run_hashcat "Phase1_Dict_Custom_Rules" false -a 0 "$HASHFILE" "$DICT" -r "$CUSTOM_RULES"

# Phase 2: Dictionary with Comprehensive Rules
run_hashcat "Phase2_Dict_Best64_Rules" false -a 0 "$HASHFILE" "$DICT" -r "$COMPREHENSIVE_RULES"

# Phase 3: Combinator (Dictionary + Appendages)
run_hashcat "Phase3_Combinator_Dict_Appendages" false -a 1 "$HASHFILE" "$DICT" "$APPENDAGES"

# Phase 4: Combinator (Appendages + Dictionary)
run_hashcat "Phase4_Combinator_Appendages_Dict" false -a 1 "$HASHFILE" "$APPENDAGES" "$DICT"

# Phase 5: Dictionary + Suffix Mask
run_hashcat "Phase5_Dict_Suffix_Mask" true -a 6 "$HASHFILE" "$DICT" "$SUFFIX_MASK"

# Phase 6: Dictionary + Brute-Force Suffix
for len in $(seq "$MIN_BRUTE_LEN" "$MAX_BRUTE_LEN"); do
  MASK=$(printf '?1%.0s' $(seq 1 "$len"))
  run_hashcat "Phase6_Dict_Brute_Suffix_len$len" true -a 6 "$HASHFILE" "$DICT" "$MASK" -1 "$BRUTE_MASK_CHARSET"
done

# Phase 7: Prefix Mask + Dictionary
run_hashcat "Phase7_Prefix_Mask_Dict" true -a 7 "$HASHFILE" "$PREFIX_MASK" "$DICT"

# Phase 8: Brute-Force Prefix + Dictionary
for len in $(seq "$MIN_BRUTE_LEN" "$MAX_BRUTE_LEN"); do
  MASK=$(printf '?1%.0s' $(seq 1 "$len"))
  run_hashcat "Phase8_Brute_Prefix_Dict_len$len" true -a 7 "$HASHFILE" "$MASK" "$DICT" -1 "$BRUTE_MASK_CHARSET"
done

# Phase 9: Pure Brute-Force
for len in {4..16}; do
  if ! $HASHCAT_CRACKED; then
    mask=$(printf '?1%.0s' $(seq 1 "$len"))
    run_hashcat "Phase9_Brute_force_len$len" true -a 3 "$HASHFILE" "$mask" -1 '?l?d!@#$%^&*()_-'
  fi
done

if $HASHCAT_CRACKED; then
  echo "Hashcat cracked the password: $HASHCAT_PASSWORD_FOUND"
fi
EOF

chmod +x run_hashcat_phases.sh

# Create a wrapper script for John the Ripper to run all phases
cat <<'EOF' > run_john_phases.sh
#!/bin/bash

HASHFILE="wallet.hash"
DICT="doge_ext.dict"
JOHN="john"

is_john_cracked() {
  local output=$(john --show "$HASHFILE" | grep -v "0 password hashes cracked")
  if [ -n "$output" ]; then
    JOHN_PASSWORD_FOUND=$(echo "$output" | head -n 1 | cut -d: -f2)
    JOHN_CRACKED=true
  else
    JOHN_CRACKED=false
  fi
}

JOHN_CRACKED=false
JOHN_PASSWORD_FOUND=""

# Phase 1: Wordlist Attack (No Rules)
echo "[+] Phase 1: Wordlist Attack (No Rules)"
start_time=$(date +%s)
$JOHN --format=bitcoin-wallet --wordlist="$DICT" "$HASHFILE"
end_time=$(date +%s)
duration=$((end_time - start_time))
echo "[+] Phase 1 completed in $duration seconds"
is_john_cracked

# Phase 2: Wordlist with Custom Rules
if ! $JOHN_CRACKED; then
  echo "[+] Phase 2: Wordlist with Custom Rules"
  start_time=$(date +%s)
  $JOHN --format=bitcoin-wallet --wordlist="$DICT" --rules=Custom "$HASHFILE"
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "[+] Phase 2 completed in $duration seconds"
  is_john_cracked
fi

# Phase 3: Wordlist with Default Rules
if ! $JOHN_CRACKED; then
  echo "[+] Phase 3: Wordlist with Default Rules"
  start_time=$(date +%s)
  $JOHN --format=bitcoin-wallet --wordlist="$DICT" --rules "$HASHFILE"
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "[+] Phase 3 completed in $duration seconds"
  is_john_cracked
fi

# Phase 4: Incremental Mode (Brute-Force)
if ! $JOHN_CRACKED; then
  echo "[+] Phase 4: Incremental Mode (Brute-Force)"
  start_time=$(date +%s)
  $JOHN --format=bitcoin-wallet --incremental=Alnum "$HASHFILE"
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "[+] Phase 4 completed in $duration seconds"
  is_john_cracked
fi

if $JOHN_CRACKED; then
  echo "John the Ripper cracked the password: $JOHN_PASSWORD_FOUND"
fi
EOF

chmod +x run_john_phases.sh

# Run tools based on configuration
if [ $HASHCAT_ENABLED -eq 1 ] && [ $JOHN_ENABLED -eq 1 ]; then
  echo "Starting cracking session with hashcat and John the Ripper..."
  tmux new-session -d -s cracking_session
  tmux split-window -h
  tmux select-pane -t 0
  tmux send-keys "./run_hashcat_phases.sh" C-m
  tmux select-pane -t 1
  tmux send-keys "./run_john_phases.sh" C-m
  tmux attach -t cracking_session
elif [ $HASHCAT_ENABLED -eq 1 ]; then
  echo "Running hashcat only..."
  ./run_hashcat_phases.sh
elif [ $JOHN_ENABLED -eq 1 ]; then
  echo "Running John the Ripper only..."
  ./run_john_phases.sh
fi

# Check for cracked password
echo "Cracking completed. Checking for results..."
if [ $HASHCAT_ENABLED -eq 1 ]; then
  hashcat --show -m "$HASH_MODE" "$HASHFILE" --potfile-path "$POTFILE"
fi
if [ $JOHN_ENABLED -eq 1 ]; then
  john --show "$HASHFILE"
fi

# -----------------------------
# Summary
# -----------------------------
SCRIPT_END_TIME=$(date +%s)
TOTAL_DURATION=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
echo "Total time: $TOTAL_DURATION seconds"
if $HASHCAT_CRACKED; then
  echo "Hashcat cracked the password: $HASHCAT_PASSWORD_FOUND"
elif $JOHN_CRACKED; then
  echo "John the Ripper cracked the password: $JOHN_PASSWORD_FOUND"
else
  echo "Password not found after all phases"
fi

echo "To detach from tmux, press Ctrl+B then D. To reattach, use 'tmux attach -t cracking_session'."
