# rootfs-java21 — Eclipse Temurin JDK 21 + Gradle + Maven, for Spring Boot and friends.
# Detector: sandbox-engine/internal/detect/java.go
# syntax=docker/dockerfile:1.6
FROM eclipse-temurin:21-jdk-jammy

ARG AGENT_BIN=dist/sandbox-agent
ARG GRADLE_VERSION=8.12
ARG MAVEN_VERSION=3.9.9

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    GRADLE_HOME=/opt/gradle \
    MAVEN_HOME=/opt/maven \
    PATH=/opt/gradle/bin:/opt/maven/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv ca-certificates curl git unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip \
    && unzip -q /tmp/gradle.zip -d /opt \
    && mv "/opt/gradle-${GRADLE_VERSION}" /opt/gradle \
    && rm /tmp/gradle.zip

RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o /tmp/maven.tgz \
    && tar -C /opt -xzf /tmp/maven.tgz \
    && mv "/opt/apache-maven-${MAVEN_VERSION}" /opt/maven \
    && rm /tmp/maven.tgz

COPY ${AGENT_BIN} /tmp/sandbox-agent
COPY images/_common/sandbox-agent.service /tmp/sandbox-agent.service
COPY images/_common/install-agent.sh /tmp/install-agent.sh
RUN sh /tmp/install-agent.sh && rm -f /tmp/sandbox-agent /tmp/sandbox-agent.service /tmp/install-agent.sh
