function venv -a arg_cd -d \
	"Checks for Python virtual environment in current directory, ascendents and certain subdirectories and activates it"
	
	# test if already within venv, if yes deactivate and return
	if set -q VIRTUAL_ENV
		echo "Deactivating virtual environment"
		deactivate
		return 0
	end
	
	# store old pwd
	set -l __sp_venv_oldpwd "$PWD"
	
	# cd into user supplied directory first
	if test "$arg_cd" != ""
		cd "$arg_cd" || return 1
	end
	
	# recursive parent directory search for .venv subdirectory or bin/activate.fish file
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
	
	# cd back to old pwd, return status
	cd "$__sp_venv_oldpwd"
	
	if test "$found" = "yes"
		return 0
	else
		echo "No virtual environment detected."
		return 1
	end
end
