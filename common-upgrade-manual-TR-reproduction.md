# Manual TR reproduction for common upgrade Jenkins jobs

The following steps need to be executed on one of the jenkins worker nodes or on a VM wich has similar properties

## Pre-requisites

* A cluster needs to be reserved manually
* Dedicated folder for the docker jenkins workspace need to be created (JENKINS_DOCKER_WORKSPACE) with read and write access

## Start docker Jenkins

* Create a docker network:
  * DOCKER_NETWORK_NAME: Uniq name of the docker network

```
    docker network create ${DOCKER_NETWORK_NAME}
```

* Run the Docker in docker image with the following parameters:
  * DIND_CONTAINER_NAME: Uniq name of the container
  * DOCKER_NETWORK_NAME: The same uniq name of the docker network that defined in the previous step
  * DIND_DATA_VOLUME: Uniq name of the DIND data docker volume
  * DIND_CERTS_VOLUME_NAME: Uniq name of the DIND certs docker volume
  * JENKINS_DATA_VOLUME: Uniq name of the Jenkins data docker volume
  * DIND_CERTS_VOLUME_NAME: Uniq volume for DIND certs
  * K8S_REGISTRY_CERT_VOLUME_NAME: Uniq name of the K8S Registry cert docker volume

```
docker run \
--name ${DIND_CONTAINER_NAME} \
--rm --detach --privileged \
--network ${DOCKER_NETWORK_NAME} \
--network-alias docker \
--env DOCKER_TLS_CERTDIR=/certs \
--volume ${DIND_DATA_VOLUME}:/var/lib/docker \
--volume ${DIND_CERTS_VOLUME_NAME}:/certs/client \
--volume ${JENKINS_DATA_VOLUME}:/var/jenkins_home \
--volume ${WORKSPACE}/hosts:/etc/hosts \
--volume ${K8S_REGISTRY_CERT_VOLUME_NAME}:/etc/docker/certs.d \
armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/docker:dind
```

* Run the Jenkins docker with the following parameters:
  * JENKINS_CONTAINER_NAME: Uniq name of the Jenkins docker
  * DOCKER_NETWORK_NAME: The same uniq name of the docker network that defined in the previous step
  * KUBECONFIG: the kube config of the reserved cluster
  * DIND_CERTS_VOLUME_NAME: The same as in the previous step
  * WORKSPACE: Path to the cdd-workspace folder
  * JENKINS_DOCKER_WORKSPACE: The previously created dedicated folder for docker jenkins workspace
  * JENKINS_HOSTPORT: Uniq port for the docker Jenkins UI
  * DOCKER_EXECUTOR_IMAGE_NAME: The docker Jenkins image name
  * DOCKER_EXECUTOR_IMAGE_VERSION: The docker Jenkins image version
  * JENKINS_DATA_VOLUME: The same as in the previous step
  * K8S_REGISTRY_CERT_VOLUME_NAME: The same as in the previous step

```
docker run --name ${JENKINS_CONTAINER_NAME} \
--rm --detach --network ${DOCKER_NETWORK_NAME} \
--env DOCKER_HOST=tcp://docker:2376 \
--env DOCKER_CERT_PATH=/certs/client \
--env DOCKER_TLS_VERIFY=1 \
--env KUBECONFIG=/local/.kube/config \
--volume ${KUBECONFIG}:/local/.kube/config:ro \
--volume ${DIND_CERTS_VOLUME_NAME}:/certs/client:ro \
--volume ${JENKINS_DATA_VOLUME}:/var/jenkins_home \
--volume ${WORKSPACE}/cdd-workspace:/cdd-workspace:ro \
--volume ${WORKSPACE}/hosts:/etc/hosts \
--volume ${K8S_REGISTRY_CERT_VOLUME_NAME}:/etc/docker/certs.d \
--publish ${JENKINS_HOSTPORT}:8080 \
${DOCKER_EXECUTOR_IMAGE_NAME}:${DOCKER_EXECUTOR_IMAGE_VERSION}
```

You might need to create an ssh tunnel to the host node to access the docker Jenkins UI from your laptop.

## Download Jenkins-CLI

When the docker Jenkins has started download the Jenkins-cli from that:

```
wget -O jenkins-cli.jar http://127.0.0.1:${JENKINS_HOSTPORT}/jnlpJars/jenkins-cli.jar
```

## Upload the Jenkins jobs

Upload the Jenkins jobs and start a dry-run on them, where:

* JENKINS_EXECUTOR_USER: Jenkins username in the docker Jenkins
* JENKINS_EXECUTOR_PASSWORD: Password for the Jenkins user in the docker Jenkins
* JENKINS_JOB_NAME: The name of the Jenkins job file

```
java -jar jenkins-cli.jar -s http://127.0.0.1:${JENKINS_HOSTPORT}/ \
-webSocket -auth ${JENKINS_EXECUTOR_USER}:${JENKINS_EXECUTOR_PASSWORD} \
create-job ${JENKINS_JOB_NAME} < $WORKSPACE/jenkins-jobs/${JENKINS_JOB_NAME}.xml

java -jar jenkins-cli.jar -s http://127.0.0.1:${JENKINS_HOSTPORT}/ \
-webSocket -auth ${JENKINS_EXECUTOR_USER}:${JENKINS_EXECUTOR_PASSWORD} \
build ${JENKINS_JOB_NAME} -s -v -p DRY_RUN=true
```

## Ready for manual job execution

Now the Jenkins job can be parametrized and started from the docker Jenkins UI manually.

## Clean up after troubleshooting

When the troubleshooting has been finished please cleanup the system.

Steps:

* Stop the docker containers:

 ```
 docker stop ${JENKINS_CONTAINER_NAME}
 docker stop ${DIND_CONTAINER_NAME}
 ```

* Delete docker volumes:

```
docker volume rm $DIND_CERTS_VOLUME_NAME $K8S_REGISTRY_CERT_VOLUME_NAME $JENKINS_DATA_VOLUME $DIND_DATA_VOLUME
```

* Delete docker network:

```
docker network rm ${DOCKER_NETWORK_NAME}
```

* Delete docker images:

```
docker image rm ${DOCKER_EXECUTOR_IMAGE_NAME}:${DOCKER_EXECUTOR_IMAGE_VERSION} armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/docker:dind
```
