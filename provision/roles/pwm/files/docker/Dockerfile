FROM tomcat:8.5

# Base image is running tomcat as root
# make sure run as own account
RUN useradd \
    --system \
    --home-dir "$CATALINA_HOME" \
    --shell /bin/false \
    --uid 999 \
    tomcat

RUN set -eux && \
    cd "$CATALINA_HOME" && \
    install -d -o root -g root -m 755 "$CATALINA_HOME" && \
    install -d -o root -g root -m 755 bin lib conf && \
    install -d -o root -g tomcat -m 775 conf/Catalina && \
    install -d -o root -g tomcat -m 775 logs temp work webapps && \
    chmod -R o+r bin/* && \
    chmod -R o+x bin/*.sh && \
    chmod -R 644 lib/* && \
    chmod 644 conf/* && \
    chown root:tomcat conf/tomcat-users.xml && \
    chmod 640 conf/tomcat-users.xml && \
    find webapps/ -mindepth 1 -delete

ARG PWM_ARTIFACT_URL="https://www.pwm-project.org/artifacts/pwm/pwm-1.8.0-SNAPSHOT-2018-02-07T10:14:54Z-release-bundle.zip"
ARG PWM_ARTIFACT_SHA256="e432f75e781a66d603e31c814450cc0a6db06137a4fb79585a231f2cd316e573"

RUN set -eux && \
    cd /tmp && \
    curl -sL -o pwm.zip "$PWM_ARTIFACT_URL" && \
    echo "${PWM_ARTIFACT_SHA256}  pwm.zip" | sha256sum -c && \
    \
    unzip pwm.zip pwm.war && \
    unzip pwm.war -d /usr/local/tomcat/webapps/ROOT && \
    rm -f pwm.zip pwm.war

ARG JDBC_POSTGRES_VERSION=42.1.4

RUN set -eux && \
    curl -sL -o "${CATALINA_HOME}/webapps/ROOT/WEB-INF/lib/postgresql-jdbc.jar" "http://central.maven.org/maven2/org/postgresql/postgresql/${JDBC_POSTGRES_VERSION}/postgresql-${JDBC_POSTGRES_VERSION}.jar"

ENV PWM_APPLICATIONPATH=/data
VOLUME [ "/data" ]

RUN install -d -o root -g tomcat -m 775 "$PWM_APPLICATIONPATH"

USER tomcat

