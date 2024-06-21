#! /bin/bash
remote=$(git remote)
url=$(git remote get-url $remote)
commit=$(git rev-parse HEAD)
path=$(pwd)
echo "$path $url $commit"