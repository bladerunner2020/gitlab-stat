#!/bin/bash
set -e 

if [ -z "$GITLAB_PERSONAL_KEY" ]; then
  echo environment variable GITLAB_PERSONAL_KEY is not set!
  echo please set GITLAB_PERSONAL_KEY to your GitLab personal key before running this script.
  exit 1
fi

NODE_NO_WARNINGS=1

GITLAB_REPOS_INFO=gitlab-repos.json
RESULTS=result.json

if [ -f $GITLAB_REPOS_INFO ]; then
   echo Found $GITLAB_REPOS_INFO - use existing file with info on gitlab repos
else
   echo Generating $GITLAB_REPOS_INFO...
   gitbeaker projects all --owned=1 --gb-token=$GITLAB_PERSONAL_KEY > $GITLAB_REPOS_INFO
fi

if [ -f $RESULTS ]; then
   echo Found $RESULTS - use existing file. Remove it to process all repos again.
else 
  echo { > result.json
  START=1
  node -pe 'require("./'$GITLAB_REPOS_INFO'").filter(({ssh_url_to_repo}) => !!ssh_url_to_repo).map(({ ssh_url_to_repo }) => ssh_url_to_repo).join("\n")' | while read line 
  do
    if ((START == 0)); then
      echo , >> result.json
    fi
    PROJECT=$(echo $line | sed "s/.*\/\(.*\).git$/\1/")
    echo Processing: $PROJECT
    git clone $line
    
    COMMITS=$( git shortlog -s -n --all  | awk '{ sum += $1; } END { print sum; }' "$@" )
    echo \"$PROJECT\": { \"commits\": $COMMITS,   >> result.json
    echo \"stats\": >> result.json
    cloc --json $PROJECT >> result.json
    echo } >> result.json
    rm -rf $PROJECT
    START=0

    break
  done
  echo } >> result.json
fi

function calculateTotal
{
node <<HERE
  const result = require('./result.json');

  const projects = Object.keys(result);
  let stats = {
    totalCommits: 0,
    repositories: projects.length
  };

  projects.forEach((name) => {
    const project = result[name];
    stats.totalCommits += project.commits;
    const types = Object.keys(project.stats).filter((type) => type !== 'header');
    types.forEach((type) => {
      const data = project.stats[type];
      if (!stats[type]) stats[type] = {};
      Object.keys(data).forEach((param) => {
        if (!stats[type][param]) stats[type][param] = 0;
        stats[type][param] += data[param];
      });
    });
  });
  stats._SUM = stats.SUM
  delete stats.SUM
  console.log(JSON.stringify(stats));
HERE
}

calculateTotal | python -m json.tool > summary.json


# rm result.json
# rm temp.json
