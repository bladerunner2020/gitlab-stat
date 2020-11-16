# gitlab-stat.sh

This bash script calculates stats on your gitlab repositories.

## Requirements

The following tools should be installed:
- Node JS
- git
- cloc
- gitbeaker cli 
- python 3 

**GITLAB_PERSONAL_KEY** environment variable should be set to your personal GitLab key.

You should be able to **git clone** GitLab repositories

## How it works

- gets all info on your repositories to *gitlab-repos.json*
- extact **ssh_url_to_repo** and clone the repo
- run **git shortlog** and **cloc** on it 
- save info to **result.json**
- finally run a js-script to calculate summary

