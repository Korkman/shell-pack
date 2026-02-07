# actual qssh additions
complete -c qssh -f -l qssh-nick -d "Give a name to a host"
complete -c qssh -f -l qssh-read -d "Show MRU record for the host"
complete -c qssh -f -l qssh-export-db -d "Export database (tab-delimited)"
complete -c qssh -f -l qssh-export-with-header	-d "Add headers to export"
complete -c qssh -f -l qssh-compact-db -d "Perform database maintenance, reducing size"
complete -c qssh -f -l qssh-fingerprint -d "Scan and show fingerprints provided by host"
complete -c qssh -f -l qssh-exit -d "Close the master connection held for the host"
complete -c qssh -f -l qssh-preview -d "Preview pane content for fzf"
complete -c qssh -f -l qssh-autocomplete-host -d "Host list with nicknames for autocomplete"
complete -c qssh -f -l qssh-update-cache -d "Update cache for autocomplete"
complete -c qssh -f -l qssh-set-custom-ssh-login -d "Set a custom ssh wrapper to log into host"
complete -c qssh -f -l qssh-multipick -d "Connect to multiple hosts in tmux"
complete -c qssh -f -l qssh-one-window -d "Connect to multiple hosts at once in one tmux window"
complete -c qssh -f -l qssh-mirror-keyboard -d "Connect to multiple hosts at once in one tmux window, send keystrokes to all"
complete -c qssh -f -k -a '(qssh --qssh-autocomplete-host)'

# until Fish comes up with a way to remove present position argument completes,
# we cannot simply
#   complete -c qssh --wrap ssh
# see Issue #6987

# so this copy & paste from /usr/share/fish

# also, source manpage completions

# even copied __fish_complete_ssh to __fish_complete_qssh, so upwards-compatible
function __fish_complete_qssh -d "common completions for ssh commands" --argument command
    complete -c $command -s 1 -d "Protocol version 1 only"
    complete -c $command -s 2 -d "Protocol version 2 only"
    complete -c $command -s 4 -d "IPv4 addresses only"
    complete -c $command -s 6 -d "IPv6 addresses only"
    complete -c $command -s C -d "Compress all data"
    complete -xc $command -s c -d "Encryption algorithm" -a "blowfish 3des des"
    complete -r -c $command -s F -d "Configuration file"
    complete -r -c $command -s i -d "Identity file"
    complete -x -c $command -s o -d "Options" -a "
		AddressFamily
		BatchMode
		BindAddress
		ChallengeResponseAuthentication
		CheckHostIP
		Cipher
		Ciphers
		Compression
		CompressionLevel
		ConnectionAttempts
		ConnectTimeout
		ControlMaster
		ControlPath
		GlobalKnownHostsFile
		GSSAPIAuthentication
		GSSAPIDelegateCredentials
		Host
		HostbasedAuthentication
		HostKeyAlgorithms
		HostKeyAlias
		HostName
		IdentityFile
		IdentitiesOnly
		LogLevel
		MACs
		NoHostAuthenticationForLocalhost
		NumberOfPasswordPrompts
		PasswordAuthentication
		Port
		PreferredAuthentications
		Protocol
		ProxyCommand
		PubkeyAuthentication
		RhostsRSAAuthentication
		RSAAuthentication
		SendEnv
		ServerAliveInterval
		ServerAliveCountMax
		SmartcardDevice
		StrictHostKeyChecking
		TCPKeepAlive
		UsePrivilegedPort
		User
		UserKnownHostsFile
		VerifyHostKeyDNS
	"
    complete -c $command -s v -d "Verbose mode"
end

__fish_complete_qssh qssh

complete -c qssh -n 'test (__fish_number_of_cmd_args_wo_opts) -ge 2' -d "Command to run" -x -a '(__fish_complete_subcommand --fcs-skip=2)'

complete -c qssh -s a -d "Disables forwarding of the authentication agent"
complete -c qssh -s A -d "Enables forwarding of the authentication agent"

complete -x -c ssh -s b -d "Local address to bind to" -a "(__fish_print_addresses)"

complete -x -c ssh -s e -d "Escape character" -a "\^ none"
complete -c qssh -s f -d "Go to background"
complete -c qssh -s g -d "Allow remote host to connect to local forwarded ports"
complete -c qssh -s I -d "Smartcard device"
complete -c qssh -s k -d "Disable forwarding of Kerberos tickets"
complete -c qssh -s l -x -a "(__fish_complete_users)" -d "User"
complete -c qssh -s m -d "MAC algorithm"
complete -c qssh -s n -d "Prevent reading from stdin"
complete -c qssh -s N -d "Do not execute remote command"
complete -c qssh -s p -x -d "Port"
complete -c qssh -s q -d "Quiet mode"
complete -c qssh -s s -d "Subsystem"
complete -c qssh -s t -d "Force pseudo-tty allocation"
complete -c qssh -s T -d "Disable pseudo-tty allocation"
complete -c qssh -s x -d "Disable X11 forwarding"
complete -c qssh -s X -d "Enable X11 forwarding"
complete -c qssh -s L -d "Locally forwarded ports"
complete -c qssh -s R -d "Remotely forwarded ports"
complete -c qssh -s D -d "Dynamic port forwarding"
complete -c qssh -s c -d "Encryption cipher" -xa "(ssh -Q cipher)"

# end copy & paste
