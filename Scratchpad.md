copypasta commanderinos
============================

hashcat -m 11300 -a 0 wallet.hash /workspace/hashmob.net_2025-06-01.found -r /usr/share/hashcat/rules/leetspeak.rule -w 3 --optimized-kernel-enable --force --status --status-timer=30 -d 1,2 --session hashmob-leetspeak --restore

hashcat -m 11300 -a 0 wallet.hash custom-list.dict -r OneRuleToRuleThemStill.rule -w 3 --optimized-kernel-enable --force --status --status-timer=30 -d 1,2 --session dogelist-onerule --restore
