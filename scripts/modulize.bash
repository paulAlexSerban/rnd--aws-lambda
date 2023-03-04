#!/bin/bash
set -eo pipefail
MODULIZE_VERSION="1.0.3"
# makes sure the folder containing the script will be the root folder
cd "$(dirname "$0")" || exit

. ../config/config.common.env

print_info() {
  echo -e "${GREEN} [ info ] ${NC}" "$1"
}

print_error() {
  echo -e "${RED} [ error ] ${NC}" "$1" >&2
}

usage() {
  print_error "Usage: $(basename "$0") [-e ENV] [-p PHASE] [-m MODULE]"
  print_error "   - mandatory: -p PHASE"
  print_error "   - mandatory: -e ENV"
  print_error "   - optional:  -m MODULE"
  exit 1
}

print_header() {
  echo "================================================"
  echo -e "   Modulze Project Automation"
  echo -e "   Version: ${BLUE}${MODULIZE_VERSION}${NC}"
  echo -e "   Author:  ${BLUE}Paul Serban${NC}"
  echo "================================================"
}

# Parse command-line options
while getopts ":m:p:e:" opt; do
  case $opt in
  m) MODULE="$OPTARG" ;;
  p) PHASE="$OPTARG" ;;
  e) ENV="$OPTARG" ;;
  *) usage ;;
  esac
done

# Shift the options and arguments so that $1 refers to the first non-option argument
shift $((OPTIND - 1))

print_header
# Validate command-line options
if [[ -z $PHASE ]]; then
  usage
fi
if [[ -z $ENV ]]; then
  ENV=dev
fi

. "../config/config.${ENV}.env"
export $NODE_ENV
print_info "Running in ${BLUE} ${NODE_ENV} ${NC} mode"

init() {
  phase() {
    local PHASE_PATH=${1}
    local PHASE_NAME=${2}
    local PHASE_DIR=${3}

    if [[ -f "${PHASE_PATH}/scripts/${PHASE_NAME}.bash" ]]; then
      print_info "${PHASE_NAME}ing ${BLUE}${PHASE_DIR}${NC}"
      bash "${PHASE_PATH}/scripts/${PHASE_NAME}.bash" -e $ENV

      # Print a message indicating that the module has been installed and how long it took
      print_info "${PHASE_NAME}ed ${BLUE}${PHASE_DIR}${NC}"
    fi
  }

  init_submodules() {

    local MODULE_NAME=$1

    for i in "${PROJECT_MODULES[@]}"; do
      local MODULE_DIR=../${i}
      # Find all submodules inside the module directory and save them to an array
      local SUBMODULES=($(find "${MODULE_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))

      # Loop through the array and print each directory
      for DIR in "${SUBMODULES[@]}"; do
        if [[ "$DIR" == "scripts" ]]; then
          phase ../${i} ${PHASE} ${i}
        fi

        if [[ ! -f "../${i}/config.env" ]]; then
          phase ../${i}/${DIR} ${PHASE} ${DIR}
        fi
      done

      if [[ -f "../${i}/config.env" ]]; then
        . "../${i}/config.env"

        for j in "${INSTALL_MODULE_SUBPROJECTS[@]}"; do
          phase ../${i}/${j} ${PHASE} ${j}
        done
      else
        local SUBMODULES=($(find "../${i}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))
        for DIR in "${SUBMODULES[@]}"; do
          phase ../${i}/${DIR} ${PHASE} ${DIR}
        done
      fi
    done
  }

  if [[ -n "${MODULE}" ]]; then
    # Loop through the PROJECT_MODULES array and check if the MODULE exists
    for i in "${PROJECT_MODULES[@]}"; do
      if [[ "$i" = "${MODULE}" ]]; then
        # if the MODULE exists then execute the PHASE script
        phase ../${MODULE} ${PHASE} ${MODULE}
        exit 0
      fi

      # if the MODULE does not exists check each existing module if there is an existing MODULE inside
      local MODULE_DIR=../${i}
      # Find all submodules inside the module directory and save them to an array
      local SUBMODULES=($(find "${MODULE_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))
      # Loop through the array and print each directory
      for DIR in "${SUBMODULES[@]}"; do
        # If any of the submodules is the same as the specified module execute phase script
        if [[ "${DIR}" == "${MODULE}" ]]; then
          phase ../${i}/${DIR} $PHASE $MODULE
        fi
      done
    done
  else
    print_info "No module selected - Running ${BLUE} ${NODE_ENV} ${NC} on all modules"
    init_submodules
  fi
}

# Run the initialization function
init
