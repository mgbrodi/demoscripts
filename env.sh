# Usage example:
# source env.sh scripts/dockerfile-1.txt files/dockerfile
# source demorunner.sh scripts/dockerfile-1.txt

demo_script=""
demo_files=""

if [ ! -f "${1}" ]; then
  echo "File does not exist: [${1}]"
  kill -INT $$
else
  demo_script="${1}"
fi

if [ ! -d "${2}" ]; then
  echo "Directory does not exist: [${2}]"
  kill -INT $$
else
  demo_files="${2}"
fi

##### DEMO ENV VARS

# brew install coreutils (for greadlink)
demo_script_absolute_path=$(greadlink -f "${demo_script}")
demo_files_absolute_path=$(greadlink -f "${demo_files}")
demo_script_handle=$(echo $(basename "${demo_script}") | cut -d. -f1)

export DEMO_HOME=`pwd`
export DEMO_SCRIPT="${demo_script_absolute_path}"
export DEMO_FILES="${demo_files_absolute_path}"
export DEMO_TEMP="${DEMO_HOME}/temp/${demo_script_handle}"
# Default delay is 10. To make it faster, increase the number
export DEMO_DELAY=15
export SAVED_DEMO_DELAY=${DEMO_DELAY}

echo
echo "### Setting env vars"
echo "DEMO_HOME=${DEMO_HOME}"
echo "DEMO_TEMP=${DEMO_TEMP}"
echo "DEMO_SCRIPT=${DEMO_SCRIPT}"
echo "DEMO_FILES=${DEMO_FILES}"
echo "DEMO_COLOR=${DEMO_COLOR}"
echo "DEMO_DELAY=${DEMO_DELAY}"
echo "SAVED_DEMO_DELAY=${SAVED_DEMO_DELAY}"
echo

##### APPEARANCE SETTINGS
# https://github.com/sharkdp/bat
#brew install bat

mkdir -p "$(bat --config-dir)/themes"
cp config/bat/themes/*.tmTheme "$(bat --config-dir)/themes"
bat cache --build

export BAT_STYLE=grid
#export BAT_STYLE=plain
#export BAT_STYLE=numbers
export BAT_PAGER=""
#export BAT_PAGER="never"

if [ -z ${COLORFGBG} ]; then
  # Background is white
  export BAT_THEME=ansi-light-MODIFIED
  #export BAT_THEME=GitHub
  export DEMO_COLOR=blue
else
  # Background is black
  if [[ ${DEMO_COLOR} != white ]]; then
    export DEMO_COLOR=yellow
  fi
fi

# https://github.com/dandavison/delta
#brew install git-delta

##### TEMP DIR

if [ "$(ls -A ${DEMO_TEMP})" ]; then
  echo "Temp dir is not empty [${DEMO_TEMP}]"
  echo "Contents:"
  ls -la "${DEMO_TEMP}"
  echo
  read -p "Keep or remove? [KP|rm] : " action
  action="${action:-KP}"
  if [[ "${action}" =~ rm|RM|Rm|rM ]]; then
    echo "Removing temp directory ${DEMO_TEMP}"
    rm -rf "${DEMO_TEMP}"
  else
    echo "Using existing temp directory ${DEMO_TEMP}"
  fi
fi
if [ ! -d "${DEMO_TEMP}" ]; then
  echo "Creating temp directory ${DEMO_TEMP}"
  mkdir -p "${DEMO_TEMP}"
fi

##### ALIASES

# Stop running containers & prune images, containers, volumes, and networks (stopped,unused, and dangling)
alias dclean="docker ps -a -q | xargs -n1 docker stop; docker system prune -af"
# Remove all containers; prune dangling images; prune images, containers, volumes, and networks with specified label
alias dclean2="docker ps -a -q | xargs -n1 docker rm -f; docker image prune -f; docker system prune -af --filter label=maintainer=me@example.org"

# Rename Terminal tabs
tabname() { printf '\e]1;%s\a' $1; }

# Change Terminal prompt to show only a $
export PS1="\[\033[0m\]\$ "

# BEGIN SECTION: Fancy cat and diff aliases
#brew install colordiff

# catt - like cat, but skip commented lines and empty lines
cattf() { grep -v -A1 '^[[:blank:]]*$' "${@}" | grep -v '^--$' | grep -vE '^\s*#'; }
alias catt=cattf

# cattd - like dif, but side-by-side and colored, and skip commented lines and empty lines
cattdf() { cattf ${1} > .___cattdf_temp_file_1; cattf ${2} > .___cattdf_temp_file_2; colordiff -yW"`tput cols`" .___cattdf_temp_file_1 .___cattdf_temp_file_2; rm .___cattdf_temp_file_1; rm .___cattdf_temp_file_2; }
alias cattd=cattdf

# catd - like dif, but side-by-side and colored
catdf() { colordiff -yW"`tput cols`" ${1} ${2}; }
alias catd=catdf
# END SECTION: Fancy cat and diff aliases

# Generate args to highlight changed lines for bat
BAT_LANG_FLAG="-l Dockerfile"
batdf() { hArgs=$(diff --unchanged-line-format="" --old-line-format="" --new-line-format="%dn " ${1} ${2} | xargs -n1 -I {} printf -- '-H %s:%s ' {} {}); bat ${BAT_LANG_FLAG} ${2} $hArgs; }
alias batd=batdf
alias bat="bat ${BAT_LANG_FLAG}"

#####  GUIDANCE

command="cd \${DEMO_TEMP}; source demorunner.sh \${DEMO_SCRIPT} 1; cd \${DEMO_HOME}"
printf "${command}" | pbcopy
echo
echo "Execute the following command (it's in your clipboard!):"
echo "cd \${DEMO_TEMP}; source demorunner.sh \${DEMO_SCRIPT} 1; cd \${DEMO_HOME}"
echo
echo "Expanded form:"
echo "cd ${DEMO_TEMP}; source demorunner.sh ${DEMO_SCRIPT} 1; cd ${DEMO_HOME}"
echo