#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

NETWORK=mqtest
IMAGE=${1:-"mq:9"}
set -x
# Build a container image with the tests
docker build -t mq-docker-test .
# Create a network for the tests.  The test container will run in this network,
# as well as any containers the tests run.
docker network create ${NETWORK}
# Run the tests
docker run \
  --tty \
  --interactive \
  --rm \
  --name mq-docker-test \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --net ${NETWORK} \
  --env DOCKER_NETWORK=${NETWORK} \
  --env DOCKER_IMAGE=$1 \
  mq-docker-test
# Clean up the network
docker network rm ${NETWORK}
