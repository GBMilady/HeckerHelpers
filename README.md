Kirt's Random Security Helpers
==============================

A collection of scripts and tools designed to assist with various security-related tasks, including password cracking, vulnerability scanning, and more, because we all love to be lazy. 
This repository is likely to be all over the place, but it may help you at some point, for something. Expect very tailor-made things meant for very specific personal tasks.


*   **`TargetedHashcat.sh`**: A hashcat-based script with a multi-phase attack strategy, optimized for GPU usage and tailored for "doge"-based passwords.
*   **`TargetedCrack.sh`**: An enhanced version that combines hashcat and John the Ripper (JtR), running both tools concurrently using tmux to leverage GPU (hashcat) and CPU (JtR) resources.

### TargetedHashcat.sh

`TargetedHashcat.sh` is a bash script that uses **hashcat** to crack a Bitcoin/Litecoin wallet.dat hash. It implements a comprehensive multi-phase attack strategy, optimized for slow hashes and GPU performance.

#### Features

*   **Multi-Phase Attacks**:
    *   **Phase 0**: Pure dictionary attack (`-a 0`).
    *   **Phase 1**: Dictionary with custom rules (`-a 0 -r custom_rules.rule`).
    *   **Phase 2**: Dictionary with comprehensive rules (`-a 0 -r rules/best64.rule`).
    *   **Phase 3**: Combinator attack (dictionary + appendages, `-a 1`).
    *   **Phase 4**: Combinator attack (appendages + dictionary, `-a 1`).
    *   **Phase 5**: Dictionary + suffix mask (`-a 6`).
    *   **Phase 6**: Dictionary + brute-force suffix (`-a 6`, lengths 1–8).
    *   **Phase 7**: Prefix mask + dictionary (`-a 7`).
    *   **Phase 8**: Brute-force prefix + dictionary (`-a 7`, lengths 1–8).
    *   **Phase 9**: Pure brute-force (`-a 3`, lengths 4–16).

#### Usage

**Prepare the Wallet Hash**:
    *   Extract the hash from `wallet.dat` using a tool like `bitcoin2john.py` or provide it directly.
    *   Example hash: `$bitcoin$64$f6b24eafc850333525e39649de8add88b349a05d7d0d7a04839557ef87b252f0$16$0b150e0714a91842$77315$2$00$2$00`.
    *   Save the hash to `wallet.hash`.        
    
    chmod +x TargetedHashcat.sh    
         ./TargetedHashcat.sh
    
#### Configuration

*   `GPU_DEVICES`: Specify GPUs (e.g., `1,2`).
*   `MIN_BRUTE_LEN`/`MAX_BRUTE_LEN`: Adjust brute-force lengths (default: 1–8).
*   `BRUTE_MASK_CHARSET`: Character set for brute-force (default: `?d!@#$%^&*()_-`).
*   `STATUS_TIMER`: Progress update interval (default: 30 seconds).

### TargetedCrack.sh

`TargetedCrack.sh` is an enhanced version of `TargetedHashcat.sh` that integrates **John the Ripper (JtR)** alongside hashcat. It runs both tools concurrently using **tmux**, leveraging GPU (hashcat) and CPU (JtR) resources for maximum efficiency.

#### Features

*   **Hashcat Attacks** (all phases from `TargetedHashcat.sh`):
    *   Includes all 10 phases (0–9) as described above.
*   **John the Ripper Attacks**:
    *   **Phase 1**: Wordlist attack (no rules).
    *   **Phase 2**: Wordlist with custom rules.
    *   **Phase 3**: Wordlist with default rules.
    *   **Phase 4**: Incremental mode (brute-force with `Alnum` charset).
*   **Concurrent Execution**:
    *   Uses tmux to run hashcat and JtR side by side.
    *   Hashcat leverages GPU, JtR leverages CPU.
*   **Automatic Installation**:
    *   Installs hashcat, JtR, and tmux if missing (Debian-based systems).
*   **Configurability**:
    *   Command-line flags: `--no-hashcat`, `--no-john`.
    *   Retains all hashcat configurations.

#### Usage

**Prepare the Wallet Hash**:
    *   The script uses a predefined hash: `$bitcoin$64$f6b24eafc850333525e39649de8add88b349a05d7d0d7a04839557ef87b252f0$16$0b150e0714a91842$77315$2$00$2$00`.
    *   To use a different hash, edit the script to modify `wallet.hash`.
    *   **Default (Both Tools)**:
        
            ./TargetedCrack.sh
        
    *   **Hashcat Only**:
        
            ./TargetedCrack.sh --no-john
        
    *   **John the Ripper Only**:
        
            ./TargetedCrack.sh --no-hashcat
        
  **Monitor Progress**:
    *   If both tools are enabled, tmux opens with two panes (hashcat on the left, JtR on the right).
    *   Detach with `Ctrl+B, D`.
    *   Reattach with:
        
            tmux attach -t cracking_session
        
#### Configuration

*   **Hashcat**:
    *   Same as `TargetedHashcat.sh` (e.g., `GPU_DEVICES`, `MIN_BRUTE_LEN`, `BRUTE_MASK_CHARSET`).
*   **John the Ripper**:
    *   Custom rules in `custom.rules`. Edit to add more transformations.
    *   Incremental mode uses `Alnum` charset; modify `john.conf` to customize.

#### Example

    # Run with both tools
    ./TargetedCrack.sh
    
    # Run hashcat only
    ./TargetedCrack.sh --no-john
    

Prerequisites
-------------

*   **System**: Debian-based Linux (e.g., Ubuntu) with `sudo` privileges.
*   **Hardware**: Compatible GPU (e.g., NVIDIA with CUDA) recommended for hashcat.
*   **Tools**:
    *   **hashcat**, **John the Ripper**, and **tmux** are installed automatically by `TargetedCrack.sh` if missing.
    *   For `TargetedHashcat.sh`, install hashcat manually:
        
            sudo apt update
            sudo apt install hashcat -y
        
*   **Rules File**: `rules/best64.rule` for hashcat (adjust path in scripts if needed).

Notes
-----

*   **Performance**:
    *   `TargetedHashcat.sh`: Optimized for GPU usage with hashcat.
    *   `TargetedCrack.sh`: Leverages both GPU (hashcat) and CPU (JtR) for maximum efficiency.
*   **Dictionary**: `doge_ext.dict` is tailored for "doge"-based passwords. Replace with a larger wordlist (e.g., `rockyou.txt`) if needed.
*   **Rules**:
    *   Hashcat: Ensure `best64.rule` exists.
    *   JtR: Incremental mode can be customized in `john.conf`.
*   **System Compatibility**: Scripts assume a Debian-based system. Modify installation commands for other distributions (e.g., Fedora, Arch).
