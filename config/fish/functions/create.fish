#!/usr/bin/env fish
function create -d "Creates a new text file with a basic template and opens it in editor"
	set file_type $argv[1]
	
	# check for help options
	if test "$file_type" = "-h" || test "$file_type" = "--help" || test (count $argv) -eq 0
		echo "Usage: create TYPE FILENAME"
		echo "Creates a new text file with a basic template and opens it in editor"
		return 0
	end

	# if first argument contains a dot, use the extension as type
	if string match -q "*.?*" -- "$file_type"
		set -l extension (string split -r -m1 . "$file_type")[2]
		switch "$extension"
			case "sh"
				set argv[2] $argv[1]
				set argv[1] "sh"
			case "fish"
				set argv[2] $argv[1]
				set argv[1] "fish"
			case "service"
				set argv[2] $argv[1]
				set argv[1] "systemd-service"
			case "mount"
				set argv[2] $argv[1]
				set argv[1] "systemd-mount"
			case "desktop"
				set argv[2] $argv[1]
				set argv[1] "desktop"
			case "md"
				set argv[2] $argv[1]
				set argv[1] "md"
			case "txt"
				set argv[2] $argv[1]
				set argv[1] "txt"
		end
		set file_type $argv[1]
	end

	# determine the template based on the type
	set -l executable 0
	set -l line 1
	set -l suggested_path ""
	switch "$file_type"
		case "bash"
			set template "#!/bin/bash\n{\nset -eu\n\nexit\n}"
			set executable 1
			set line 4
		case "sh"
			set template "#!/bin/sh\n{\nset -eu\n\nexit\n}"
			set executable 1
			set line 4
		case "fish"
			set template "#!/usr/bin/env fish\n"
			set executable 1
			set line 2
		case "docker-compose"
			set template "services:\n  example-service:\n    image: example-image\n    ports:\n      - '8080:80'\n    restart: always\n    volumes:\n      - ./data:/data\n    #network_mode: host"
			set line 2
			if test (count $argv) -lt 2; set -a argv "compose.yaml"; end
		case "systemd-service"
			set template "[Unit]\nDescription=Example Service\n\n[Service]\nExecStart=/usr/bin/example\nRestart=always\n\n[Install]\nWantedBy=multi-user.target"
			set line 2
			set suggested_path "/etc/systemd/system/"
		case "systemd-mount"
			set template "[Unit]\nDescription=Example Mount\n\n[Mount]\nWhat=/dev/sdX1\nWhere=/mnt/example\nType=ext4\nOptions=defaults\n\n[Install]\nWantedBy=multi-user.target"
			set line 2
			set suggested_path "/etc/systemd/system/"
		case "cron"
			set template "# Example cron job\n# <minute> <hour> <day_of_month> <month> <day_of_week> <user> <command>\n* * * * * root /usr/bin/example"
			set line 3
			set suggested_path "/etc/cron.d/"
		case "desktop"
			set template "[Desktop Entry]\nVersion=1.0\nName=Example\nComment=This is an example\nExec=/usr/bin/example\nIcon=example\nTerminal=false\nType=Application\nCategories=Utility;\nMimeType=text/html;"
			set line 1
			set suggested_path "$HOME/.local/share/applications/"
		case "md"
			set template "# Headline\n\nThis is a paragraph with `inline code` example.\n\n## Link\n[Example](https://example.com)\n\n## Bullet Points\n- Item 1\n- Item 2\n- Item 3\n\n## Table\n| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |\n| Cell 3   | Cell 4   |\n\n## Formatting\n**Bold Text**\n*Italic Text*\n\n## Code\n```bash\n# This is a code block\n\necho 'Hello, World!'\n```"
			set line 1
		case "txt"
			set template "This is a text file.\n\nYou can write anything here."
			set line 1
		case '*'
			echo "Error: Unsupported type '$file_type'. Supported types are: bash, sh, fish, docker-compose, systemd-service, systemd-mount, cron, desktop, md, txt."
			return 1
	end

	if test (count $argv) -lt 2
		create --help
		return 1
	end
	
	set filename $argv[2]

	# ask if cd into suggested_path is okay
	if test -n "$suggested_path" && test "$suggested_path" != "$PWD"
		read -l -P "Change directory to $suggested_path? (Y/n) " REPLY
		or return 1
		if test -z "$REPLY" -o "$REPLY" = "y"
			if ! test -d "$suggested_path"
				read -l -P "Directory does not exist. Create? (Y/n) " REPLY
				or return 1
				if test -z "$REPLY" -o "$REPLY" = "y"
					mkdir -p "$suggested_path"
				else
					return 1
				end
			end
			cd "$suggested_path"
		end
	end
	
	# test if directory is writable
	if not test -w (dirname "$filename")
		echo "Error: Cannot write to directory '$filename'"
		return 1
	end
	
	# check if the file already exists
	if test -e "$filename"
		echo "Error: File '$filename' already exists."
		read -l -P "Edit it? (Y/n) " REPLY
		or return 1
		if test -z $REPLY -o $REPLY = "y"
			"$EDITOR" "$filename"
			return 0
		else
			return 1
		end
	end
	
	# create a new text file with the given name and write template content
	echo -e "$template" > "$filename"
	
	# make the file executable only for bash, sh, and fish
	if test $executable -eq 1
		chmod +x "$filename"
	end

	if test -z "$EDITOR"
		set -f EDITOR "mcedit"
	end
	
	# open the file in the default editor with cursor position for supported editors
	switch "$EDITOR"
		case "*mcedit" "*vi" "*vim" "*nano"
			"$EDITOR" +$line "$filename"
		case '*'
			"$EDITOR" "$filename"
	end

	# check if the file still matches the template after editing
	if string match --quiet -- (echo -e "$template" | string join '\n') (cat "$filename" | string join '\n')
		read -l -P "Delete unmodified template? (Y/n) " REPLY
		or return 1
		if test -z $REPLY -o $REPLY = "y"
			rm "$filename"
			echo "File '$filename' deleted."
		end
	end
end
