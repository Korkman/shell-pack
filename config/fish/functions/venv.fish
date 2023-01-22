function venv -d \
	"Checks for Python virtual environment in current directory, ascendents and certain subdirectories and activates it"
	
	if set -q VIRTUAL_ENV
		echo "Deactivating virtual environment"
		deactivate
		return 0
	end
	
	# recursive parent directory search for .venv subdirectory or bin/activate.fish file
	set -l oldpwd "$PWD"
	set -l found no
	while test "$found" = "no"
		if [ -e "bin/activate.fish" ]
			echo "Activating virtual environment (bin/activate.fish)"
			. "bin/activate.fish"
			set found yes
		else if [ -e ".venv/bin/activate.fish" ]
			echo "Activating virtual environment (.venv/bin/activate.fish)"
			. ".venv/bin/activate.fish"
			set found yes
		end
		if test "$found" = "no"
			cd .. || break
			if test "$PWD" = "/"
				break
			end
		end
	end
	
	cd "$oldpwd"
	
	if test "$found" = "yes"
		return 0
	else
		echo "No virtual environment detected."
		return 1
	end
end
