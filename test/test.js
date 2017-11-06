/**
  * © Copyright IBM Corporation 2016, 2017
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
const tls = require('tls');

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
      exec(`docker run --rm --env LICENSE=view ${DOCKER_IMAGE}`, {maxBuffer: 1024 * 500}, function (err, stdout, stderr) {
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
  });

  // Utility function to run a container and wait until MQ starts
  let runContainer = function(options, unsetQMName, hostname) {
    return new Promise((resolve, reject) => {
      let cmd = "";
      let qmName = "";
      if(!unsetQMName){
        cmd = `docker run -d --env LICENSE=accept --env MQ_QMGR_NAME=${QMGR_NAME} --net ${DOCKER_NETWORK} ${options} ${DOCKER_IMAGE}`;
        qmName=QMGR_NAME
      } else{
        cmd = `docker run -d --env LICENSE=accept --net ${DOCKER_NETWORK} ${options} ${DOCKER_IMAGE}`;
        qmName=hostname
      }
      exec(cmd, function (err, stdout, stderr) {
        if (err) reject(err);
        let containerId = stdout.trim();
        let startStr = `IBM MQ Queue Manager ${qmName} is now fully running`;
        // Run dspmq every second, until the queue manager comes up
        let timer = setInterval(function() {
          exec(`docker logs ${containerId}`, function (err, stdout, stderr) {
            if (err) reject(err);
            if (stdout && stdout.includes(startStr)) {
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

  // Utility function to wait for the HTTPS web interface to become available
  let waitForWeb = function(addr, port = 9443, timeout = 60000) {
    return new Promise((resolve, reject) => {
      const INTERVAL = 3000; //ms
      let count = 0;
      let timer = setInterval(() => {
        count++;
        if ((count * INTERVAL) >= timeout) {
          clearInterval(timer);
          reject(new Error(`Timed out connecting to port ${port}`));
        }
        else {
          let socket = new tls.TLSSocket();
          socket.on('connect', () => {
            clearInterval(timer);
            resolve();
          });
          socket.connect(port, addr);
        }
      }, INTERVAL);
    });
  };

  // Utility function to delete a container
  let deleteContainer = function(id) {
    return new Promise((resolve, reject) => {
      exec(`docker rm --force ${id}`, function (err, stdout, stderr) {
        if (err) reject(err);
        resolve();
      });
    });
  };

  describe('with running container', function() {
    let container = null;
    this.timeout(10000);

    describe('and no queue manager variable supplied', function(){
      let containerName="MQTestQM"

      before(function() {
        this.timeout(20000);
        return runContainer("-h " + containerName, true, containerName)
        .then((details) => {
          container = details;
        });
      });
      after(function() {
        return deleteContainer(container.id);
      });
      it('should be using the hostname as the queue manager name', function (done) {
        exec(`docker exec ${container.id} dspmq`, function (err, stdout, stderr) {
          if (err) throw(err);
          if (stdout && stdout.includes(containerName)) {
            // Queue manager is up, so clear the timer
            done();
          }
        });
      });
    });

    describe('and no queue manager variable supplied but the hostname has invalid characters', function(){
      let containerName="MQ-Test-QM"
      let containerValidName="MQTestQM"

      before(function() {
        this.timeout(20000);
        return runContainer("-h " + containerName, true, containerValidName)
        .then((details) => {
          container = details;
        });
      });
      after(function() {
        return deleteContainer(container.id);
      });
      it('should be using the hostname as the queue manager name without the invalid characters', function (done) {
        exec(`docker exec ${container.id} dspmq`, function (err, stdout, stderr) {
          if (err) throw(err);
          if (stdout && stdout.includes(containerValidName)) {
            // Queue manager is up, so clear the timer
            done();
          }
        });
      });
    });

    describe('with the web console disabled', function() {
      before(function() {
        this.timeout(20000);
        return runContainer("--env MQ_DISABLE_WEB_CONSOLE=true")
        .then((details) => {
          container = details;
        });
      });
      after(function() {
        return deleteContainer(container.id);
      });
      it('should be listening on port 1414 on the Docker network', function (done) {
        const client = net.connect({host: container.addr, port: 1414}, () => {
          client.on('close', done);
          client.end();
        });
      });
      // Only run this test once, as it's quite slow
      it('should not be listening on port 9443 on the Docker network', function (done) {
        this.timeout(120000);
        waitForWeb(container.addr, 9443, 30000).then(() => {
          // We connected... so errored
          throw new Error(`Connected to port 9443 when the console should not of been running`)
        },(err) => {
          //We errored which means we couldn't connect, which means the console isn't running!
          done();
        });
      });
    });

    describe('and implicit volume', function() {
      before(function() {
        this.timeout(20000);
        return runContainer("")
        .then((details) => {
          container = details;
        });
      });
      after(function() {
        return deleteContainer(container.id);
      });
      it('should be listening on port 1414 on the Docker network', function (done) {
        const client = net.connect({host: container.addr, port: 1414}, () => {
          client.on('close', done);
          client.end();
        });
      });
      // Only run this test once, as it's quite slow
      it('should be listening on port 9443 on the Docker network', function () {
        this.timeout(120000);
        return waitForWeb(container.addr);
      });
    });

    describe('and an empty bind-mounted volume', function() {
      this.timeout(20000);
      let volumeDir = null;
      before(function() {
        volumeDir = fs.mkdtempSync(VOLUME_PREFIX);
      });

      before(function() {
        return runContainer(`--volume ${volumeDir}:/var/mqm`)
        .then((details) => {
          container = details;
        });
      });

      after(function(done) {
        deleteContainer(container.id)
        .then(() => {
          exec(`rm -rf  ${volumeDir}`, function (err, stdout, stderr) {
            if (err) throw err;
            done();
          });
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
      this.timeout(20000);
      let volumeDir = null;
      before(function() {
        volumeDir = fs.mkdtempSync(VOLUME_PREFIX);
        fs.writeFileSync(`${volumeDir}/foo.txt`, 'Hello world');
      });

      before(function() {
        return runContainer(`--volume ${volumeDir}:/var/mqm`)
        .then((details) => {
          container = details;
        });
      });

      after(function(done) {
        deleteContainer(container.id)
        .then(() => {
          exec(`rm -rf  ${volumeDir}`, function (err, stdout, stderr) {
            if (err) throw err;
            done();
          });
        });
      });

      it('should be listening on port 1414 on the Docker network', function (done) {
        const client = net.connect({host: container.addr, port: 1414}, () => {
            client.on('close', done);
            client.end();
        });
      });
    });

    // Bluemix presented a new challenge when attempting to use it's volumes
    // Because Bluemix is more secure and only allows root users to edit mounted
    // volumes (and MQ runs as mqm) we have to mount the volume at another directory
    // and then mount /var/mqm to a folder within that which has the correct owner.
    describe('and a mounted volume in a different location', function() {
      this.timeout(20000);
      let volumeDir = null;
      before(function() {
        volumeDir = fs.mkdtempSync(VOLUME_PREFIX);
      });

      before(function() {
        return runContainer(`--volume ${volumeDir}:/mnt/mqm`)
        .then((details) => {
          container = details;
        });
      });

      after(function(done) {
        deleteContainer(container.id)
        .then(() => {
          exec(`rm -rf  ${volumeDir}`, function (err, stdout, stderr) {
            if (err) throw err;
            done();
          });
        });
      });

      it('should be listening on port 1414 on the Docker network', function (done) {
        const client = net.connect({host: container.addr, port: 1414}, () => {
            client.on('close', done);
            client.end();
        });
      });
    });

    // Tests that we can stop and start a container without it failing. This Test
    // makes sure that the scripts we set to run on every start can be ran when
    // MQ data is already present.
    describe('and can be started multiple times', function() {
      this.timeout(20000);
      before(function() {
        return runContainer(``)
        .then((details) => {
          container = details;
        });
      });

      after(function() {
        return deleteContainer(container.id);
      });

      it('should not fail', function (done) {
        exec(`docker stop ${container.id}`, function (err, stdout, stderr) {
          if (err) throw err;
          exec(`docker start ${container.id}`, function (err, stdout, stderr) {
            if (err) throw err;
            let startStr = `IBM MQ Queue Manager ${QMGR_NAME} is now fully running`;
            let timer = setInterval(function() {
              exec(`docker logs --tail 3 ${container.id}`, function (err, stdout, stderr) {
                if (err) throw(err);
                if (stdout && stdout.includes(startStr)) {
                  // Queue manager is up, so clear the timer
                  clearInterval(timer);
                  done();
                }
              });
            }, 1000);
          });
        });
      });
    });
    describe('and can be created multiple times with a mounted volume', function() {
      this.timeout(20000);
      let volumeDir = null;
      before(function() {
        volumeDir = fs.mkdtempSync(VOLUME_PREFIX);
      });
      before(function() {
        return runContainer(`--volume ${volumeDir}:/var/mqm`)
        .then((details) => {
          container = details;
        });
      });

      after(function(done) {
        deleteContainer(container.id)
        .then(() => {
          exec(`rm -rf  ${volumeDir}`, function (err, stdout, stderr) {
            if (err) throw err;
            done();
          });
        });
      });

      it('should not fail', function (done) {
        deleteContainer(container.id)
          .then(() => {
            runContainer(`--volume ${volumeDir}:/var/mqm`)
            .then((details) => {
              container = details;
              done();
            });
          });
      });
    });
  });
});
