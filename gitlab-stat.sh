#!/bin/bash
set -e 

function calculateTotal
{
echo "This is an example of using a function"
node <<HERE
  const result = require('./result.json');

  const projects = Object.keys(result);
  const stats = {};

  projects.forEach((name) => {
    const project = result[name];
    const types = Object.keys(project).filter((type) => type !== 'header');
    types.forEach((type) => {
      const data = project[type];
      if (!stats[type]) stats[type] = {};
      Object.keys(data).forEach((param) => {
        if (!stats[type][param]) stats[type][param] = 0;
        stats[type][param] += data[param];
      });
    });
  });
  console.log(JSON.stringify(stats));
HERE
}

NODE_NO_WARNINGS=1

gitbeaker projects all --owned=1 --gb-token=$GITLAB_PERSONAL_KEY > temp.json

echo { > result.json
START=1

node -pe 'require("./temp.json").filter(({ssh_url_to_repo}) => !!ssh_url_to_repo).map(({ ssh_url_to_repo }) => ssh_url_to_repo).join("\n")' | while read line 
do
  if ((START == 0)); then
    echo , >> result.json
  fi
  PROJECT=$(echo $line | sed "s/.*\/\(.*\).git$/\1/")
  echo Processing: $PROJECT
  git clone $line
  echo \"$PROJECT\": >> result.json
  cloc --json $PROJECT >> result.json
  rm -rf $PROJECT
  START=0
done
echo } >> result.json

calculateTotal

# rm result.json
# rm temp.json

# git shortlog -s -n --all  | awk '{ sum += $1; } END { print sum; }' "$@"

#node -pe 'JSON.parse(process.argv[1]).forEach(({ ssh_url_to_repo }) => console.log(ssh_url_to_repo))' ($JSON_REPO_LIST)
