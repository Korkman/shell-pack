#!/usr/bin/env fish
function create -d "Creates a new text file with a basic template and opens it in editor"
	set file_type (string lower -- $argv[1])
	
	# check for help options
	if test "$file_type" = "-h" || test "$file_type" = "--help" || test (count $argv) -eq 0
		echo "Usage: create TYPE FILENAME"
		echo "Creates a new text file with a basic template and opens it in editor"
		return 0
	end

	# if first argument contains a dot, use the extension as type
	if string match -q "*.*" -- "$file_type"
		set -l extension (string split -r -m1 . "$file_type")[2]
		switch "$extension"
			case "bash"
				set argv[2] $argv[1]
				set argv[1] "bash"
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
			case "automount"
				set argv[2] $argv[1]
				set argv[1] "systemd-automount"
			case "desktop"
				set argv[2] $argv[1]
				set argv[1] "desktop"
			case "md"
				set argv[2] $argv[1]
				set argv[1] "md"
			case "yml" "yaml"
				set argv[2] $argv[1]
				set -l base (basename -- "$file_type")
				if string match -q "*compose*" -- "$base"
					set argv[1] "docker-compose"
				else
					set argv[1] "yaml"
				end
			case "txt"
				set argv[2] $argv[1]
				set argv[1] "txt"
			case "ini"
				set argv[2] $argv[1]
				set argv[1] "ini"
			case "env"
				set argv[2] $argv[1]
				set argv[1] ".env"
			case "py"
				set argv[2] $argv[1]
				set argv[1] "py"
			case "html" "htm"
				set argv[2] $argv[1]
				set argv[1] "html"
			case "timer"
				set argv[2] $argv[1]
				set argv[1] "systemd-timer"
		end
		set file_type $argv[1]
	end

	# determine the template based on the type
	set -l executable 0
	set -l line 1
	set -l suggested_path ""
	set -l suggested_ext ""
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
			set suggested_ext ".service"
		case "systemd-mount"
			set template "[Unit]\nDescription=Example Mount\n\n[Mount]\nWhat=/dev/sdX1\nWhere=/mnt/example\nType=ext4\nOptions=defaults\n\n[Install]\nWantedBy=multi-user.target"
			set line 2
			set suggested_path "/etc/systemd/system/"
			set suggested_ext ".mount"
		case "systemd-automount"
			set template "[Unit]\nDescription=Example Automount\n\n[Automount]\nWhere=/mnt/example\nTimeoutIdleSec=600\n\n[Install]\nWantedBy=multi-user.target"
			set line 2
			set suggested_path "/etc/systemd/system/"
			set suggested_ext ".automount"
		case "cron"
			set template "# Example cron job\n# <minute> <hour> <day_of_month> <month> <day_of_week> <user> <command>\n* * * * * root /usr/bin/example"
			set line 3
			set suggested_path "/etc/cron.d/"
		case "desktop"
			set template "[Desktop Entry]\nVersion=1.0\nName=Example\nComment=This is an example\nExec=/usr/bin/example\nIcon=example\nTerminal=false\nType=Application\nCategories=Utility;\nMimeType=text/html;"
			set suggested_path "$HOME/.local/share/applications/"
			set suggested_ext ".desktop"
		case "md" "markdown"
			set template "# Headline\n\nThis is a paragraph with `inline code` example.\n\n## Link\n[Example](https://example.com)\n\n## Bullet Points\n- Item 1\n- Item 2\n- Item 3\n\n## Table\n| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |\n| Cell 3   | Cell 4   |\n\n## Formatting\n**Bold Text**\n*Italic Text*\n\n## Code\n```bash\n# This is a code block\n\necho 'Hello, World!'\n```"
			set suggested_ext ".md"
		case "yaml" "yml"
			set template "# Example YAML\n# key: value\nexample:\n  nested: true\n  list:\n    - item1\n    - item2"
			set suggested_ext ".yaml"
		case "txt" "text"
			set template "This is a text file. You can write anything here."
		case "ini"
			set template "[section]\n; comment\nsome_key=value"
			set suggested_ext ".ini"
		case ".env"
			set template "# comment\nKEY=value"
			if test (count $argv) -lt 2; set -a argv ".env"; end
		case "py" "python"
			set template "#!/usr/bin/env python3\n\"\"\"\nDescription\n\"\"\"\n\nimport sys\n\n\ndef main():\n    pass\n\n\nif __name__ == \"__main__\":\n    main()"
			set executable 1
			set line 9
			set suggested_ext ".py"
		case "dockerfile"
			set template "FROM debian:trixie-slim\n\nRUN apt-get update && apt-get install -y --no-install-recommends \\\\\n    && rm -rf /var/lib/apt/lists/*\n\nWORKDIR /app\n\nCOPY . .\n\nCMD [\"/bin/bash\"]"
			set line 1
			if test (count $argv) -lt 2; set -a argv "Dockerfile"; end
		case "systemd-timer"
			set template "[Unit]\nDescription=Example Timer\n\n[Timer]\nOnCalendar=daily\nPersistent=true\n\n[Install]\nWantedBy=timers.target"
			set line 2
			set suggested_path "/etc/systemd/system/"
			set suggested_ext ".timer"
		case "html" "htm"
			set template "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>Title</title>\n</head>\n<body>\n  <h1>Hello, World!</h1>\n</body>\n</html>"
			set line 6
			set suggested_ext ".htm"
		case '*'
			echo "Error: Unsupported type '$file_type'. Supported types are: bash, sh, fish, python, docker-compose, dockerfile, systemd-service, systemd-mount, systemd-automount, systemd-timer, cron, desktop, html, md, txt, ini, .env, yaml."
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
	
	if test -n "$suggested_ext" && ! string match -q "*$suggested_ext" -- "$filename"
		set filename "$filename$suggested_ext"
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
