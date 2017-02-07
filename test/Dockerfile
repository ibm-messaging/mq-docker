# © Copyright IBM Corporation 2015, 2016
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

FROM ubuntu:16.04

MAINTAINER Arthur Barr <arthur.barr@uk.ibm.com>

ENV NODE_VERSION 6.9.5

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update -y \
  && apt-get install -y \
    curl \
    docker.io \
    tar \
  && curl -LO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" \
  && mkdir -p /usr/src/mq-docker-test

WORKDIR /usr/src/mq-docker-test

COPY package.json /usr/src/mq-docker-test/

RUN npm install

COPY . /usr/src/mq-docker-test

ENTRYPOINT [ "npm", "start" ]
