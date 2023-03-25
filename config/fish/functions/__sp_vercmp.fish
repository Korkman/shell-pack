# original author: https://github.com/faho
# original source: https://github.com/fish-shell/fish-shell/issues/4419#issuecomment-330951128
function __sp_vercmp \
    --description "Compare versions"
    
    # This is a pure fish version of rpm's "vercmp" utility.
    # It is useful for e.g. making completions dependent on having at least a certain version.
    # It both prints and returns
    # "-1" if the first version is smaller
    # "1" if the first version is greater
    # "0" if both are equal
    #
    # This handles really rather weird versions like '1.4.0~pre2+git141-g6d40dace6358-1'
    # (an actual debian package version),
    # and also "2.6.0-610-g55ab7a42" - which is a $FISH_VERSION
    # when building from git.
    #
    # Behavior is weird for some (meaningless) comparisons, e.g.
    # Git versions with the same number of commits compare the hash (same as vercmp).
    if not set -q argv[2]
        echo "Expected two arguments" >&2
        return 2
    end
    # Note: We do _not_ verify that the arguments are versions
    # - the definition we accept is very loose anyway.

    # First split on "." and "-" to remove those characters.
    # Then split on every character to allow comparing beta versions and such.
    set -l first (string split "." -- $argv[1] | string split "-" | string split "")
    set -l second (string split "." -- $argv[2] | string split "-" | string split "")
    # Missing trailing components are effectively 0
    # This also makes 2.6a1 smaller than 2.6 - since the latter is interpreted as "2600", the former as "26a1".
    while test (count $first) -lt (count $second)
        set first $first 0
    end
    while test (count $second) -lt (count $first)
        set second $second 0
    end
    while set -q first[1]
        # Simple case - both are the same character, so skip ahead.
        if test $first[1] = $second[1]
            set -e first[1]
            set -e second[1]
            continue
        else if string match -qr '[0-9]' -- $first[1]; and not string match -qr '[0-9]' -- $second[1]
            # First is numeric, second isn't - first is greater.
            # (I.e. 2.6a1 is _smaller_ than 2.6.0)
            echo 1
            return 2
        else if not string match -qr '[0-9]' -- $first[1]; and string match -qr '[0-9]' -- $second[1]
            # Other way around - second is numeric, so first is smaller.
            echo -1
            return 1
        else if test (printf '%d' "'$first[1]" | string join "") -lt (printf '%d' "'$second[1]" | string join "")
            # Both are numeric or both aren't - compare character value.
            # Note that this is decidedly not locale-aware and encoding dependent.
            echo -1
            return 1
        else
            # These are different characters, so the only option is that second < first
            echo 1
            return 2
        end
    end
    # No components differ, version is the same.
    echo 0
    return 0
end
