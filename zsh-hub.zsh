0=${(%):-%N}
typeset -g ZSH_HUB_VERSION=$(<"${0:A:h}"/.version)
typeset -g ZSH_HUB_REVISION=$(<"${0:A:h}"/.revision-hash)

grebase() {
  base=${1:-origin/master}
  hub rebase -i HEAD~$(hub rev-list ...$(hub merge-base HEAD ${base}) | wc -l | bc)
}

gpr() {
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

  show=
}

gct() {
  comment=$1

  account_name=$(hub api -t user | grep .login | cut -f 2)
  repo_name=$(basename $(hub remote get-url origin) | cut -d '.' -f 1)

  parent_full_name=$(hub api -t repos/${account_name}/${repo_name} | grep .parent.full_name | cut -f 2)

  curr_branch=$(hub branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD)
  pr_number=$(hub pr list -h ${account_name}:${curr_branch} | grep -o -E '^\s*#\w+' | cut -d '#' -f 2)

  hub api -t repos/${parent_full_name}/issues/${pr_number}/comments --raw-field "body=${comment}" | grep '.html_url' | head -n 1
}

gci() {
  hub ci-status -f '%S %t %U
'
}
