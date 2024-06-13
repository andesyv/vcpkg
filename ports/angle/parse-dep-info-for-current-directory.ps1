$remote = git remote
$url = git remote get-url $remote
$commit = git rev-parse HEAD
'"{0} {1} {2}"' -f $PWD.Path,$url,$commit