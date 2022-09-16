#!/bin/bash

while getopts l:t:r:o: flag
do
  case "${flag}" in
    l) LOGIN=${OPTARG};;
    t) TOKEN_FILE=${OPTARG};;
    r) REPOS_FILE=${OPTARG};;
    o) OUTFILE=${OPTARG};;
  esac
done

: ${LOGIN:?Missing GitHub login (-l)}
: ${TOKEN_FILE:?Missing GitHub token file (-t)}
: ${REPOS_FILE:?Missing file listing repos (-r)}
: ${OUTFILE:?Missing target csv (-o)}

echo "GitHub login: $LOGIN"
echo "GitHub token file: $TOKEN_FILE"
echo "File listing repos: $REPOS_FILE"
echo "CSV results: $OUTFILE"

token=$(cat $TOKEN_FILE)
repos=$(cat $REPOS_FILE)

echo "Repo,User,Date,State,PR#,Title" > $OUTFILE

summarize_repo_prs() {
  repo=$1
  echo "REPO: $repo"

  for i in `seq 1 500`; do
    raw=$(curl --silent -u ${LOGIN}:${token} "https://api.github.com/repos/${repo}/pulls?state=all&per_page=100&page=${i}")

    size=$(echo $raw | jq 'length')
    if [ "$size" -eq "0" ]; then
      echo ""
      return
    fi

    latest=$(echo $raw | jq --raw-output '.[].created_at' | sort -r | head -n1)
    if ! [[ $latest =~ ^2022- ]]; then
      echo "<date limit>"
      return
    fi

    printf '.'
    echo $raw \
      | jq --raw-output 'map(. |= {"repo": .base.repo["full_name"], "user": .user["login"], created_at, state, "number": .number|tostring, title})' \
      | jq --raw-output 'map(to_entries | map(.value)) | .[] | @csv' \
      >> $OUTFILE

    sleep 1
  done

  echo "<count limit>"
  return
}

for repo in ${repos[@]}; do
  summarize_repo_prs $repo
done
