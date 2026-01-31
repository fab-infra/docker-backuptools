# Backup tools based on openSUSE Leap 16.0
FROM ghcr.io/fab-infra/base-image:opensuse16.0

# Arguments
ARG GSUTIL_VERSION=5.35
ARG KEYSTONE_VERSION=5.7.0
ARG SWIFTCLIENT_VERSION=4.9.0
ARG S3CMD_VERSION=2.4.0

# Packages
RUN zypper in -y rclone rsync xz zip \
	python313-pip \
	mariadb-client \
	openldap2_6 openldap2_6-client &&\
	zypper clean -a

# Python packages
RUN pip install --no-cache-dir \
	python-keystoneclient==${KEYSTONE_VERSION} \
	python-swiftclient==${SWIFTCLIENT_VERSION} \
	s3cmd==${S3CMD_VERSION}

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
