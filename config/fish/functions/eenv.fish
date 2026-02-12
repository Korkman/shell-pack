function eenv -d \
	"Evaluate .env file (use POSIX subshell parse the .env file)."
	set -l env_file .env
	if test (count $argv) -gt 0
		set env_file $argv[1]
	end
	__sp_env_to_fish $env_file | source
end

function __sp_env_to_fish
	if test (count $argv) -eq 0
		echo "Usage: $argv[0] <env-file>" >&2
		exit 1
	end

	if not test -f $argv[1]
		echo "Error: File '$argv[1]' not found" >&2
		exit 1
	end

	set -l sourcefile (builtin realpath $argv[1])

	# Capture environment before sourcing
	set -l old_env (sh -c 'env -0' | string split0)

	# Capture environment after sourcing the file, autoexporting all new variables
	set -l new_env (sh -c "set -a && . '$sourcefile' && env -0" | string split0)

	# Parse old environment into associative array
	set -l old_vars
	set -l old_contents
	for line in $old_env
		if test -n "$line"
			set -l parts (string split -m 1 -- '=' "$line")
			if test (count $parts) -eq 2
				set -l var_name "$parts[1]"
				set -l var_value "$parts[2]"
				set -a -- old_vars "$var_name"
				set -a -- old_contents "$var_value"
			end
		end
	end

	# Process new environment and output changes
	for line in $new_env
		if test -n "$line"
			set -l parts (string split -m 1 -- '=' "$line")
			if test (count $parts) -eq 2
				set -l var_name "$parts[1]"
				set -l var_value "$parts[2]"
				
				# Check if variable is new or changed
				set -l idx (contains -i -- "$var_name" $old_vars)
				and begin
					set -l -- old_value "$old_contents[$idx]"
					if test "$var_value" = "$old_value"
						continue
					end
				end
				# Changed variable
				printf "set -gx %s %s\n" "$var_name" (string escape -- "$var_value")
				
			end
		end
	end
end
