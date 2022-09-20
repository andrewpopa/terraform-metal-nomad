#!/usr/bin/env bash

which nomad &>/dev/null || {

  which curl wget unzip jq &>/dev/null || {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install --no-install-recommends -y curl wget unzip jq
  }

  wget -q -O /tmp/nomad.zip https://releases.hashicorp.com/nomad/${NOMADVER}/nomad_${NOMADVER}_linux_amd64.zip
  unzip -d /usr/local/bin /tmp/nomad.zip

  [ -d /etc/nomad.d ] || {
    mkdir --parents /etc/nomad.d
  }

  tee -a /etc/nomad.d/nomad.hcl <<EOF
datacenter = "dc1"
region     = "global"
bind_addr  = "0.0.0.0"
data_dir   = "/var/lib/nomad"

advertise {
  http = "{{ GetInterfaceIP \"bond0\" }}"
  rpc  = "{{ GetInterfaceIP \"bond0\" }}"
  serf = "{{ GetInterfaceIP \"bond0\" }}"
}

server {
  enabled = true
  bootstrap_expect = ${cluster_size}
  server_join {
    retry_max      = 10
    retry_interval = "15s"
    retry_join = [ 
      "provider=packet auth_token=${metal_token} project=${project_id}  address_type=public_v4" 
    ]
  }
}


EOF

  tee -a /etc/systemd/system/nomad.service <<EOF
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=10

# If you are running Consul, please uncomment following Wants/After configs.
# Assuming your Consul service unit name is "consul"
Wants=consul.service
After=consul.service

[Service]
KillMode=process
KillSignal=SIGINT
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d/
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=2
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

}

which consul &>/dev/null || {
  pushd /var/tmp
  echo Installing consul ${CONSULVER}
  wget https://releases.hashicorp.com/consul/${CONSULVER}/consul_${CONSULVER}_linux_amd64.zip
  unzip consul_${CONSULVER}_linux_amd64.zip
  chown root:root consul
  mv consul /usr/local/bin
  consul -autocomplete-install
  complete -C /usr/local/bin/consul consul
  
  # create consul user
  useradd --system --home /opt/consul --shell /bin/false consul
  
  # consul data directory
  [ -d /opt/consul ] || {
    mkdir --parents /opt/consul
    chown --recursive consul:consul /opt/consul
  }
  
  # copy consul configuration 
  [ -d /etc/consul.d ] || {
    mkdir --parents /etc/consul.d
    tee -a /etc/consul.d/consul.hcl <<EOF
client_addr        = "127.0.0.1"
bind_addr          = "{{ GetInterfaceIP \"bond0\" }}"
data_dir           = "/opt/consul"
datacenter         = "east"
log_level          = "DEBUG"
server             = false
enable_syslog      = true
retry_join         = [ "provider=packet auth_token=${metal_token} project=${project_id}  address_type=public_v4" ]

EOF
    chown --recursive consul:consul /etc/consul.d
    chmod 640 /etc/consul.d/consul.hcl
  }
  
  cp /vagrant/conf/consul_client.hcl /etc/consul.d/consul.hcl

  
  # copy service definition
  cp /vagrant/conf/consul_client.service /etc/systemd/system/consul.service

  tee -a /etc/systemd/system/consul.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
ExecStop=/usr/local/bin/consul leave
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF
   
  # enable and start service
  systemctl enable consul
  systemctl start consul
  
}


sudo systemctl enable nomad.service
sudo systemctl start nomad.service