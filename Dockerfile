# Backup tools based on openSUSE Leap 15.2
FROM fcrespel/base-image:opensuse15.2

# Packages
RUN zypper in -y rclone rsync xz \
	python3-pip python3-swiftclient python3-keystoneclient \
	mariadb-client \
	openldap2 openldap2-client &&\
	zypper clean -a

# Files
COPY ./root /
RUN groupadd backup &&\
	useradd -d /home/backups -g backup -s /bin/bash backup &&\
	chown -R backup:backup /home/backups &&\
	confd -onetime -backend env &&\
	chmod -R a+rX /etc/openldap

# Execution
USER backup
WORKDIR /home/backups
