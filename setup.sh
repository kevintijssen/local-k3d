#!/bin/bash

set -eo pipefail

# # Always execute from repo root
# ROOT_DIR=$(dirname "$0")
# cd "$(ROOT_DIR)/.."

# This passes DNS request on through Docker's DNS into the Local machine's DNS resolver
declare -rx K3D_FIX_DNS=1

# Default Variables
VERBOSE="false"
PREFLIGHT_CHECK="false"
DESTROY="false"
DEPLOY_MODE="single"

function main() {
  while getopts ":m:pdvh" flag; do
    case "${flag}" in
      v) VERBOSE="true" ;;
      d) DESTROY="true" ;;
      m) DEPLOY_MODE="${OPTARG}" ;;
      h) usage ;;
      *) error "Unexpected flag ${OPTARG}"
         usage ;;
    esac
  done

  readonly VERBOSE
  readonly DEPLOY_MODE

  if [[ "${VERBOSE}" == "true" ]]; then
    set -x
  fi

  case "${DEPLOY_MODE}" in
    single)
      deploy_single ;;
    ha)
      deploy_ha ;;
    *)
      error "Deploy mode ${DEPLOY_MODE} is incorrect" ;;
  esac

}

function error() {
  local err_message
  err_message="$1"

  echo "${err_message}" >&2
  exit 1

}

function usage() {
  printf '
setup.sh

Deploys a k3s based kubernetes c;luster locally with some tools pre-deployed.

use the "-m MODE" flag to select the k3d configuration.

Currently supported are:

  - single (default): A single node cluster
  - ha:               A 3 node cluster

Usage: setup.sh [options]

Options:
  -h        Shows this screen
  -v        Prints every line this script executes
  -p        Executes the pre-flight check
  -m MODE   Select the deploy mode (single|ha) [default: single]
'
}

function deploy_single() {
  if [[ "${DESTROY}"  == "true" ]]; then
    k3d cluster delete single
    rm -f kubeconfig.yaml
    exit 0
  fi

  if [[ -z "$(k3d cluster get single --no-headers)" ]]; then
    if ! k3d cluster create --config=k3d-single.yaml --wait; then
      error "Failed to create cluster"
    fi

    if ! k3d kubeconfig get single > kubeconfig.yaml; then
      error "Failed to get kubeconfig"
    fi

    exit 0
  fi

  error "Cluster already exists, use the flag \"-d\" to destroy the cluster and run this script again"
  exit 1
}

function deploy_ha() {
  if [[ "${DESTROY}"  == "true" ]]; then
    k3d cluster delete ha
    rm -f kubeconfig.yaml
    exit 0
  fi

  if [[ -z "$(k3d cluster get ha --no-headers)" ]]; then
    if ! k3d cluster create --config=k3d-ha.yaml --wait; then
      error "Failed to create cluster"
    fi
    
    if ! k3d kubeconfig get ha > kubeconfig.yaml; then
      error "Failed to get kubeconfig"
    fi

    exit 0
  fi

  error "Cluster already exists, use the flag \"-d\" to destroy the cluster and run this script again"
  exit 1

}

main "$@"