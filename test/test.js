/**
  * © Copyright IBM Corporation 2016
  *
  *
  * Licensed under the Apache License, Version 2.0 (the "License");
  * you may not use this file except in compliance with the License.
  * You may obtain a copy of the License at
  *
  * http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS,
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the License.
  **/
const exec = require('child_process').exec;
const assert = require('chai').assert;
const net = require('net');

// Pre-requisites for running this test:
//   * Docker network created
//   * Env. variable called DOCKER_NETWORK with the name of the network
//   * Env. variable called DOCKER_IMAGE with the name of the image to test

const DOCKER_NETWORK = process.env.DOCKER_NETWORK;
const DOCKER_IMAGE = process.env.DOCKER_IMAGE;

describe('MQ Docker sample', function() {
  describe('when launching container', function () {
    this.timeout(3000);
    it('should display the license when LICENSE=view', function (done) {
      console.log(`docker run --rm --env LICENSE=view ${DOCKER_IMAGE}`);
      exec(`docker run --rm --env LICENSE=view ${DOCKER_IMAGE}`, function (err, stdout, stderr) {
        assert.equal(err.code, 1);
        assert.isTrue(stdout.includes("terms"));
        done();
      });
    });
    it('should fail if LICENSE is not set', function (done) {
      exec(`docker run --rm  ${DOCKER_IMAGE}`, function (err, stdout, stderr) {
        assert.equal(err.code, 1);
        done();
      });
    });
    it('should fail if MQ_QMGR_NAME is not set', function (done) {
      exec(`docker run --rm --env LICENSE=accept  ${DOCKER_IMAGE}`, function (err, stdout, stderr) {
        assert.equal(err.code, 1);
        assert.isTrue(stderr.includes("ERROR"));
        done();
      });
    });
  });

  describe('with running container', function() {
    var containerId = null;
    var containerAddr = null;
    const QMGR_NAME = "foo";

    beforeEach(function(done) {
      this.timeout(10000);
      exec(`docker run -d --env LICENSE=accept --env MQ_QMGR_NAME=${QMGR_NAME} --net ${DOCKER_NETWORK} ${DOCKER_IMAGE}`, function (err, stdout, stderr) {
        if (err) throw err;
        containerId = stdout.trim();
        // Run dspmq every second, until the queue manager comes up
        let timer = setInterval(function() {
          exec(`docker exec ${containerId} dspmq -n`, function (err, stdout, stderr) {
            if (err) throw err;
            if (stdout && stdout.includes("RUNNING")) {
              // Queue manager is up, so clear the timer
              clearInterval(timer);
              exec(`docker inspect --format '{{ .NetworkSettings.Networks.${DOCKER_NETWORK}.IPAddress }}' ${containerId}`, function (err, stdout, stderr) {
                if (err) throw err;
                containerAddr = stdout.trim();
                done();
              });
            }
          });
        }, 1000);

      });
    });

    afterEach(function(done) {
      exec(`docker rm --force ${containerId}`, function (err, stdout, stderr) {
        done();
      });
    });

    it('should be listening on port 1414 on the Docker network', function (done) {
      const client = net.connect({host: containerAddr, port: 1414}, () => {
          client.on('close', done);
          client.end();
      });
    });
  });
});
