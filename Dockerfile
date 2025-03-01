# Backup tools based on openSUSE Leap 15.6
FROM ghcr.io/fab-infra/base-image:opensuse15.6

# Arguments
ARG GSUTIL_VERSION=5.31
ARG S3CMD_VERSION=2.4.0

# Packages
RUN zypper in -y rclone rsync xz zip \
	python3-pip python3-swiftclient python3-keystoneclient \
	mariadb-client \
	openldap2 openldap2-client &&\
	zypper clean -a

# S3cmd
RUN pip install --no-cache-dir s3cmd==${S3CMD_VERSION}

# GSUtil
RUN wget -q https://storage.googleapis.com/pub/gsutil_${GSUTIL_VERSION}.tar.gz &&\
	tar -xf gsutil_${GSUTIL_VERSION}.tar.gz -C /opt &&\
	rm gsutil_${GSUTIL_VERSION}.tar.gz &&\
	ln -s /opt/gsutil/gsutil /usr/local/bin/gsutil &&\
	ln -s /usr/bin/python3 /usr/bin/python

# Files
COPY ./root /
RUN groupadd backup &&\
	useradd -d /home/backups -g backup -s /bin/bash backup &&\
	chown -R backup:backup /home/backups &&\
	confd -onetime -backend env &&\
	chmod -R a+rwX /home/backups /etc/openldap /var/lib/ldap

# Execution
USER backup
WORKDIR /home/backups
