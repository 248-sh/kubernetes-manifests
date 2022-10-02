clone FILES TAG REPOSITORY FOLDER:
  #!/usr/bin/env bash
  # set -euxo pipefail

  tput setaf 2
  echo "SYNCING {{ REPOSITORY }}@{{ TAG }}"
  tput sgr0

  rm -Rf {{ FOLDER }} 2> /dev/null

  git clone --depth 1 --filter=blob:none --no-checkout --branch {{ TAG }} {{ REPOSITORY }} {{ FOLDER }}
  pushd {{ FOLDER }} 1> /dev/null
  git sparse-checkout set {{ FILES }}
  git read-tree -mu HEAD
  rm -Rf .git
  popd 1> /dev/null
