FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Update package list and install dependencies
RUN apt-get update && apt-get install -y \
	apt-utils \
	python3 \
	python3-pip \
	python3-venv \
	openssh-client \
	sshpass \
	git \
	curl \
	wget \
	vim \
	nano \
	tree \
	jq \
	iputils-ping \
	&& rm -rf /var/lib/apt/lists/*

# For Debian/Ubuntu-based images
RUN apt-get update && apt-get install -y \
	iputils-ping \
	net-tools

RUN chmod 4755 /usr/bin/ping
RUN setcap cap_net_raw+p /usr/bin/ping

# Create symbolic link for python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install Ansible and useful Python packages
RUN pip3 install \
	ansible \
	ansible-core \
	paramiko \
	PyYAML \
	jinja2 \
	netaddr \
	dnspython \
	boto3 \
	botocore

# Create ansible directory
RUN mkdir -p /ansible

# Create SSH directory and set permissions
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Add ansible user (optional, for non-root operations)
RUN useradd -m -s /bin/bash ansible && \
	echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set working directory
WORKDIR /ansible

# RUN export EDITOR=nano && \
# 	export VISUAL=nano

RUN echo "export EDITOR=nano" >> /root/.bashrc && \
	echo "export VISUAL=nano" >> /root/.bashrc && \
	echo "export EDITOR=nano" >> /etc/bash.bashrc && \
	echo "export VISUAL=nano" >> /etc/bash.bashrc

# Default command
CMD ["/bin/bash"]

