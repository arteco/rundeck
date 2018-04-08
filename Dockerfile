# Dockerfile for rundeck
# https://github.com/jjethwa/rundeck

FROM debian:stretch

MAINTAINER Jordan Jethwa

ENV SERVER_URL=https://localhost:4443 \
    RUNDECK_STORAGE_PROVIDER=file \
    RUNDECK_PROJECT_STORAGE_TYPE=file \
    NO_LOCAL_MYSQL=false \
    LOGIN_MODULE=RDpropertyfilelogin \
    JAAS_CONF_FILE=jaas-loginmodule.conf \
    KEYSTORE_PASS=adminadmin \
    TRUSTSTORE_PASS=adminadmin

RUN export DEBIAN_FRONTEND=noninteractive && \
    echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list && \
    apt-get -qq update && \
    apt-get -qqy install -t stretch-backports --no-install-recommends bash openjdk-8-jre-headless ca-certificates-java supervisor procps sudo ca-certificates openssh-client mysql-server mysql-client pwgen curl git uuid-runtime parallel && \
    cd /tmp/ && \
    curl -Lo /tmp/rundeck.deb http://dl.bintray.com/rundeck/rundeck-deb/rundeck_2.10.8-1-GA_all.deb && \
    echo 'c23ac39d9a712652a78e2c27de407408ca7473b338a8b3a41de16ec4eb3f202e  rundeck.deb' > /tmp/rundeck.sig && \
    shasum -a256 -c /tmp/rundeck.sig && \
    curl -Lo /tmp/rundeck-cli.deb https://github.com/rundeck/rundeck-cli/releases/download/v1.0.23/rundeck-cli_1.0.23-1_all.deb && \
    echo 'a46282aec09d969fc4dc1d7c48669c75f791f1b030ccd2f1f15fc149904ea3df  rundeck-cli.deb' > /tmp/rundeck-cli.sig && \
    shasum -a256 -c /tmp/rundeck-cli.sig && \
    cd - && \
    dpkg -i /tmp/rundeck*.deb && rm /tmp/rundeck*.deb && \
    chown rundeck:rundeck /tmp/rundeck && \
    mkdir -p /var/lib/rundeck/.ssh && \
    chown rundeck:rundeck /var/lib/rundeck/.ssh && \
    sed -i "s/export RDECK_JVM=\"/export RDECK_JVM=\"\${RDECK_JVM} /" /etc/rundeck/profile && \
    curl -Lo /var/lib/rundeck/libext/rundeck-slack-incoming-webhook-plugin-0.6.jar https://github.com/higanworks/rundeck-slack-incoming-webhook-plugin/releases/download/v0.6.dev/rundeck-slack-incoming-webhook-plugin-0.6.jar && \
    echo 'd23b31ec4791dff1a7051f1f012725f20a1e3e9f85f64a874115e46df77e00b5  rundeck-slack-incoming-webhook-plugin-0.6.jar' > /tmp/rundeck-slack-plugin.sig && \
    cd /var/lib/rundeck/libext/ && \
    shasum -a256 -c /tmp/rundeck-slack-plugin.sig && \
    cd - && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD content/ /
RUN chmod u+x /opt/run && \
    mkdir -p /var/log/supervisor && mkdir -p /opt/supervisor && \
    chmod u+x /opt/supervisor/rundeck && chmod u+x /opt/supervisor/mysql_supervisor && chmod u+x /opt/supervisor/fatalservicelistener && \
    apt-get -qq update && apt-get -qqy install lsb-release gnupg && \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    apt-get -qq update && apt-get -qqy install google-cloud-sdk



EXPOSE 4440 4443

VOLUME  ["/etc/rundeck", "/var/rundeck", "/var/lib/rundeck", "/var/lib/mysql", "/var/log/rundeck", "/opt/rundeck-plugins", "/var/lib/rundeck/logs", "/var/lib/rundeck/var/storage"]

ENTRYPOINT ["/opt/run"]
