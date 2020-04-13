#!/bin/bash

function run_commands() {
  local description="$1"
  local commands="$2"
  local hr="============================================================================================================="
  echo ""
  echo -e "\e[37m${hr}"
  echo ""
  echo -e "\e[92m${description}:"
  echo -e "\e[94m${commands}"
  echo -e "\e[37m${hr}"
  read -p $'\e[93mPress enter to continue and run the commands...\e[0m '
  echo ""
  commands_file="/tmp/$(date +%s).sh"
  echo "#!/bin/bash" > $commands_file
  printf "$commands" >> $commands_file
  chmod +x $commands_file
  $commands_file
  rm $commands_file
  echo ""
}

function info() {
  echo ""
  echo -e "\e[92m${1}\e[0m"
  echo ""
}
