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
doge2023
Doge1
Doge12
Doge13
Doge123
Doge2023
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
# STEP 4: Create Custom Rules
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
# STEP 5: Create Appendages
# -----------------------------
echo -e "0\n1\n2\n3\n4\n5\n6\n7\n8\n9" > "$APPENDAGES"
for i in {00..99}; do echo "$i" >> "$APPENDAGES"; done
for i in {2000..2020}; do echo "$i" >> "$APPENDAGES"; done
echo -e "!\n@\n#\n$\n%\n^\n&\n*\n(\n)\n_\n-\n+\n=\n.\n," >> "$APPENDAGES"
echo -e "!2013\n@2014\n#2013\n$2014\n!123\n@123\n#123\n$123\n!!\n@@" >> "$APPENDAGES"
echo "[+] Created appendages file '$APPENDAGES' with $(wc -l < "$APPENDAGES") entries."

# -----------------------------
# Helper Functions
# -----------------------------
is_cracked() {
  local output=$(hashcat --show -m "$HASH_MODE" "$HASHFILE" --potfile-path "$POTFILE")
  if [ -n "$output" ]; then
    PASSWORD_FOUND=$(echo "$output" | cut -d: -f2-)
    CRACKED=true
  else
    CRACKED=false
  fi
}

run_hashcat() {
  local phase=$1
  local use_S=$2
  shift 2

  if $CRACKED; then
    echo "[-] Skipping $phase (password already found)"
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
# Main Execution
# -----------------------------
SCRIPT_START_TIME=$(date +%s)
CRACKED=false
PASSWORD_FOUND=""

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
run_hashcat "Phase8_Prefix_Mask_Dict" true -a 7 "$HASHFILE" "$PREFIX_MASK" "$DICT"

# Phase 8: Brute-Force Prefix + Dictionary
for len in $(seq "$MIN_BRUTE_LEN" "$MAX_BRUTE_LEN"); do
  MASK=$(printf '?1%.0s' $(seq 1 "$len"))
  run_hashcat "Phase8_Brute_Prefix_Dict_len$len" true -a 7 "$HASHFILE" "$MASK" "$DICT" -1 "$BRUTE_MASK_CHARSET"
done

# Phase 9: Pure Brute-Force
for len in {4..16}; do
  if ! $CRACKED; then
    mask=$(printf '?1%.0s' $(seq 1 "$len"))
    run_hashcat "Phase9_Brute_force_len$len" true -a 3 "$HASHFILE" "$mask" -1 '?l?d!@#$%^&*()_-'
  fi
done

# -----------------------------
# Summary
# -----------------------------
SCRIPT_END_TIME=$(date +%s)
TOTAL_DURATION=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
echo "Total time: $TOTAL_DURATION seconds"
if $CRACKED; then
  echo "Password found: $PASSWORD_FOUND"
else
  echo "Password not found after all phases"
fi
