
# DOCS=$(cat <<EOF
# ${GREEN}USAGE:${NC}
# $ xno setup
# $ xno balance
# $ xno whois @moon
# $ xno send @esteban 0.1
# $ xno install (Coming Soon)
# EOF
# )

# OPTIONS_DOCS=$(cat <<EOF
# Options
# --cloud, -c  Use Cloud Node (Custodial).
# --local, -l  Use Local Node (Non-Custodial).
# --help, -h  Print CLI Documentation.
# --docs, -d  Open Nano.to Documentation.
# --update, -u  Get latest CLI Script.
# --version, -v  Print current CLI Version.
# --uninstall, -u  Remove CLI from system.
# EOF
# )

DOCS=$(cat <<EOF
${GREEN}USAGE:${NC}
$ xno version
$ xno install
EOF
)

if [[ "$1" = "--json" ]]; then
	echo "Tip: Use the '--json' flag to get command responses in JSON."
	exit 0
fi
