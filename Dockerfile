FROM ghcr.io/nestybox/ubuntu-jammy-systemd:latest

ENV PATH="/home/admin/.local/bin:${PATH}"

# Install Docker
RUN apt-get update && apt-get install -y curl wget git cmake build-essential nano python3 python3-pip python-is-python3 npm at\
    && npm install pm2 -g \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh \
    && usermod -a -G docker admin
ADD https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker /etc/bash_completion.d/docker.sh
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

WORKDIR /home/admin

# Set up subtensor
RUN sudo mkdir -p /home/admin/subtensor && \
    sudo chown -R admin:admin /home/admin/subtensor && \
    git clone https://github.com/opentensor/subtensor.git /home/admin/subtensor && \
    cd /home/admin/subtensor && \
    chmod +x scripts/run/subtensor.sh

# Add systemd service file
COPY subtensor.service /etc/systemd/system/subtensor.service
COPY 10-custom-message /etc/update-motd.d/10-custom-message
# Make the script executable
RUN chmod +x /etc/update-motd.d/10-custom-message
# Enable and start the subtensor service
RUN systemctl enable subtensor.service


RUN mkdir -p /home/admin/.bittensor/bittensor && \
    git clone https://github.com/opentensor/bittensor.git /home/admin/.bittensor/bittensor/ 2> /dev/null || (cd /home/admin/.bittensor/bittensor/ ; git fetch origin master ; git checkout master) && \
    python3 -m pip install -e /home/admin/.bittensor/bittensor/  && \
    sudo chown -R admin:admin /home/admin/.bittensor


RUN wget https://raw.githubusercontent.com/cisterciansis/Bittensor-Compute-Subnet-Installer-Script/main/install_sn27.sh
RUN chmod 755 /home/admin/install_sn27.sh
RUN wget https://hashcat.net/files/hashcat-6.2.6.tar.gz && \
    tar xzvf hashcat-6.2.6.tar.gz && \
    cd hashcat-6.2.6/ && \
    make && \
    make install && \
    cd ..

RUN mkdir -p /home/admin/compute-subnet && \
    git clone https://github.com/neuralinternet/Compute-Subnet.git /home/admin/compute-subnet/ && \
    cd /home/admin/compute-subnet/ && \
    pip install --upgrade pip setuptools && \
    python -m pip install -r requirements.txt && \
    python -m pip install --no-deps -r requirements-compute.txt && \
    python -m pip install -e . && \
    apt-get install -y ocl-icd-libopencl1 pocl-opencl-icd

# Configure wandb API key
RUN echo "Configuring wandb API key" && \
    cp /home/admin/compute-subnet/.env.example /home/admin/compute-subnet/.env && \
    sed -i "s/WANDB_API_KEY=\"your_api_key\"/WANDB_API_KEY=\"12345Qwq@\"/" /home/admin/compute-subnet/.env

# Set systemd as entrypoint.
ENTRYPOINT [ "/sbin/init", "--log-level=err" ]
