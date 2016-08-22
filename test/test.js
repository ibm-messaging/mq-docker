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
const assert = require('chai').assert;
const exec = require('child_process').exec;
const fs = require('fs');
const net = require('net');

// Pre-requisites for running this test:
//   * Docker network created
//   * Env. variable called DOCKER_NETWORK with the name of the network
//   * Env. variable called DOCKER_IMAGE with the name of the image to test

const DOCKER_NETWORK = process.env.DOCKER_NETWORK;
const DOCKER_IMAGE = process.env.DOCKER_IMAGE;
const QMGR_NAME = "qm1";
const VOLUME_PREFIX = process.env.TEMP_DIR + "/tmp";

describe('MQ Docker sample', function() {
  describe('when launching container', function () {
    this.timeout(3000);
    it('should display the license when LICENSE=view', function (done) {
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

  // Utility function to run a container and wait until MQ starts
  let runContainer = function(options) {
    return new Promise((resolve, reject) => {
      let cmd = `docker run -d --env LICENSE=accept --env MQ_QMGR_NAME=${QMGR_NAME} --net ${DOCKER_NETWORK} ${options} ${DOCKER_IMAGE}`;
      exec(cmd, function (err, stdout, stderr) {
        if (err) reject(err);
        let containerId = stdout.trim();
        // Run dspmq every second, until the queue manager comes up
        let timer = setInterval(function() {
          exec(`docker exec ${containerId} dspmq -n`, function (err, stdout, stderr) {
            if (err) reject(err);
            if (stdout && stdout.includes("RUNNING")) {
              // Queue manager is up, so clear the timer
              clearInterval(timer);
              exec(`docker inspect --format '{{ .NetworkSettings.Networks.${DOCKER_NETWORK}.IPAddress }}' ${containerId}`, function (err, stdout, stderr) {
                if (err) reject(err);
                resolve({id: containerId, addr: stdout.trim()});
              });
            }
          });
        }, 1000);
      });
    });
  };

  describe('with running container', function() {
    let container = null;

    describe('and implicit volume', function() {
      before(function() {
        this.timeout(20000);
        return runContainer("")
        .then((details) => {
          container = details;
        });
      });
      it('should be listening on port 1414 on the Docker network', function (done) {
        const client = net.connect({host: container.addr, port: 1414}, () => {
            client.on('close', done);
            client.end();
        });
      });
    });

    describe('and an empty bind-mounted volume', function() {
      let volumeDir = null;
      before(function() {
        volumeDir = fs.mkdtempSync(VOLUME_PREFIX);
      });

      before(function() {
        this.timeout(20000);
        return runContainer(`--volume ${volumeDir}:/var/mqm`)
        .then((details) => {
          container = details;
        });
      });

      after(function(done) {
        exec(`rm -rf  ${volumeDir}`, function (err, stdout, stderr) {
          if (err) throw err;
          done();
        });
      });

      it('should be listening on port 1414 on the Docker network', function (done) {
        const client = net.connect({host: container.addr, port: 1414}, () => {
            client.on('close', done);
            client.end();
        });
      });
    });

    // This can happen if the entire volume directory is actually a filesystem.
    // See https://github.com/ibm-messaging/mq-docker/issues/29
    describe('and a non-empty bind-mounted volume', function() {
      let volumeDir = null;
      before(function() {
        volumeDir = fs.mkdtempSync(VOLUME_PREFIX);
        fs.writeFileSync(`${volumeDir}/foo.txt`, 'Hello world');
      });

      before(function() {
        this.timeout(20000);
        return runContainer(`--volume ${volumeDir}:/var/mqm`)
        .then((details) => {
          container = details;
        });
      });

      after(function(done) {
        exec(`rm -rf  ${volumeDir}`, function (err, stdout, stderr) {
          if (err) throw err;
            done();
          });
      });

      it('should be listening on port 1414 on the Docker network', function (done) {
        const client = net.connect({host: container.addr, port: 1414}, () => {
            client.on('close', done);
            client.end();
        });
      });
    });

    afterEach(function(done) {
      exec(`docker rm --force ${container.id}`, function (err, stdout, stderr) {
        done();
      });
    });
  });
});
