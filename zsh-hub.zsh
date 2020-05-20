0=${(%):-%N}
typeset -g ZSH_HUB_VERSION=$(<"${0:A:h}"/.version)
typeset -g ZSH_HUB_REVISION=$(<"${0:A:h}"/.revision-hash)
