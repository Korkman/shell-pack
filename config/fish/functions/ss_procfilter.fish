# reformat ss
function ss_procfilter
  sed 's/users:((//; s/))/\]/; s/pid=//g; s/,fd=[0-9]*//g; s/"//g; s/),(/\]\//g; s/,/\[/g; s/\//,/g';
end
