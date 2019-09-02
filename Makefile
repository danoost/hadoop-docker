
REPOSITORY=cybermaggedon/hadoop
VERSION=$(shell git describe | sed 's/^v//')
HADOOP_VERSION=2.8.2

SUDO=
BUILD_ARGS=--build-arg HADOOP_VERSION=${HADOOP_VERSION}

all: hadoop-${HADOOP_VERSION}.tar.gz
	${SUDO} docker build ${BUILD_ARGS} -t ${REPOSITORY}:${VERSION} .

# FIXME: May not be the right mirror for you.
hadoop-${HADOOP_VERSION}.tar.gz:
	wget -q -O $@ 'https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz'

push:
	${SUDO} docker push ${REPOSITORY}:${VERSION}

# Continuous deployment support
BRANCH=master
FILE=hadoop-version
REPO=git@github.com:trustnetworks/gaffer

tools: phony
	if [ ! -d tools ]; then \
		git clone git@github.com:trustnetworks/cd-tools tools; \
	fi; \
	(cd tools; git pull)

phony:

bump-version: tools
	tools/bump-version

update-cluster-config: tools
	tools/update-version-file ${BRANCH} ${VERSION} ${FILE} ${REPO}

