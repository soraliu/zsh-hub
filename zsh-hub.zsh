0=${(%):-%N}
typeset -g ZSH_HUB_VERSION=$(<"${0:A:h}"/.version)
typeset -g ZSH_HUB_REVISION=$(<"${0:A:h}"/.revision-hash)
typeset -g ZSH_HUB_CACHE_DIR=~/.zsh-hub

grebase() {
  base=${1:-origin/master}
  hub rebase -i HEAD~$(hub rev-list ...$(hub merge-base HEAD ${base}) | wc -l | bc)
}

gbsort() {
  git for-each-ref --sort=-committerdate refs/heads
}

gupdate() {
  set -e

  pr_number=$(hub pr show -u | grep -o '\d\+$' 2>/dev/null)

  if [[ ${pr_number} == "" ]]; then
    echo 'PR not exist!'
    exit
  fi

  labels=$(git issue show ${pr_number} -f '%L' | sed 's/ //g')

  hub issue update ${pr_number} -l "${labels}" ${@}

  echo "update successfully"
}

gprstat() {
  UPSTREAM=origin
  BASE=master
  BASE_BRANCH=${UPSTREAM}/${BASE}

  pr_number=$1

  git fetch ${UPSTREAM} ${BASE}
  if [[ ${pr_number} == "" ]]; then
    git log --stat ...${BASE_BRANCH}
  else
    git fetch ${UPSTREAM} pull/${pr_number}/head
    ancestor_branch=$(git merge-base FETCH_HEAD ${BASE_BRANCH})
    git log --stat FETCH_HEAD...${ancestor_branch}
  fi
}

gprls() {
  refresh=
  while [ "$1" != "" ]; do
    case $1 in
      -r )
        refresh="true"
        ;;
      * )
        echo "usage: gprls
          [-r [refresh cache]]"
        exit 1
    esac
    shift
  done

  mkdir -p ${ZSH_HUB_CACHE_DIR}

  repo_name=$(basename $(hub remote get-url origin) | cut -d '.' -f 1)
  path_to_cache=${ZSH_HUB_CACHE_DIR}/${repo_name}

  if [[ -e ${path_to_cache} && ${refresh} == "" ]]; then
    cat ${path_to_cache}
    bash -c "hub pr list -f '%i_%au_%t%n' | column -t -s '_' > ${path_to_cache}" &
  else
    cached_data=$(hub pr list -f '%i_%au_%t%n' | column -t -s '_')
    echo ${cached_data}
    echo ${cached_data} > ${path_to_cache}
  fi
}

gpr() {
  show="false"
  base="master"
  while [ "$1" != "" ]; do
    case $1 in
      -s )
        show="true"
        ;;
      -b | --base ) shift
        base=$1
        ;;
      * )
        echo "usage: create hub pull request
          [-s [show pr]]
          [-b | --base [base branch]]"
        exit 1
    esac
    shift
  done

  account_name=$(hub api user -t | grep .login | cut -f 2)
  echo "Base branch: ${base:-master}"
  hub push ${account_name} -u -f && hub pull-request --no-edit -b ${base:-master}

  if [[ $show == "true" ]]; then
    hub pr show
  fi
}

gct() {
  comment=$1

  account_name=$(hub api -t user | grep .login | cut -f 2)
  repo_name=$(basename $(hub remote get-url origin) | cut -d '.' -f 1)

  parent_full_name=$(hub api -t repos/${account_name}/${repo_name} | grep .parent.full_name | cut -f 2)

  curr_branch=$(hub branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD)

  pr_number=$2
  if [[ ${pr_number} == "" ]]; then
    pr_number=$(hub pr list -h ${account_name}:${curr_branch} | grep -o -E '^\s*#\w+' | cut -d '#' -f 2)
  fi

  hub api -t repos/${parent_full_name}/issues/${pr_number}/comments --raw-field "body=${comment}" | grep '.html_url' | head -n 1
}

gci() {
  hub ci-status -f '%S %t %U
'
}
