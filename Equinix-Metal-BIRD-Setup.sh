#!/bin/sh

# !!! Set your Equinix Metal API Token !!!

auth_token=EM-API-TOKEN

# NOTE: Make sure you have BGP enabled for the Equinix Metal project..

# NOTE: This script currently only works for Ubuntu / Debian / CentOS / AlmaLinux / Rocky Linux

#Example on adding/deleting IPs that you're announcing to the loopback interface:
#ip addr add x.x.x.x/xx dev lo
#ip addr del x.x.x.x/xx dev lo

# Detect Operating System
function distcheck() {
  # shellcheck disable=SC1090
  if [ -e /etc/os-release  ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO=$ID
    # shellcheck disable=SC2034
    DISTRO_VERSION=$VERSION_ID
  fi
}

# Check Operating System
distcheck

# Install prerequisites (parted and filesystem packages)
  function installprerequisites() {
    # Installation begins here
    # shellcheck disable=SC2235
    if [ "$DISTRO" == "ubuntu" ]; then
      apt-get update
      apt-get install bird jq -y
      if [ "$DISTRO_VERSION" == "16.04" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      elif [ "$DISTRO_VERSION" == "18.04" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      elif [ "$DISTRO_VERSION" == "20.04" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      elif [ "$DISTRO_VERSION" == "21.04" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      elif [ "$DISTRO_VERSION" == "22.04" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      fi
    # shellcheck disable=SC2235
    elif [ "$DISTRO" == "debian" ]; then
      apt-get update
      apt-get install bird jq -y
      if [ "$DISTRO_VERSION" == "8" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      elif [ "$DISTRO_VERSION" == "9" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      elif [ "$DISTRO_VERSION" == "10" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      elif [ "$DISTRO_VERSION" == "11" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird/bird.conf
      fi
    # shellcheck disable=SC2235
    elif [ "$DISTRO" == "centos" ]; then
      yum install epel-release -y
      yum install bird jq -y
      if [ "$DISTRO_VERSION" == "7" ]; then
        BIRD_VERSION=1
        BIRD_CONFIG_PATH=/etc/bird.conf
      elif [ "$DISTRO_VERSION" == "8" ]; then
        BIRD_VERSION=2
        BIRD_CONFIG_PATH=/etc/bird.conf
      fi
    elif [ "$DISTRO" == "almalinux" ]; then
      yum install epel-release -y
      yum install bird jq -y
      if [ "$DISTRO_VERSION" == "8.5" ]; then
        BIRD_VERSION=2
        BIRD_CONFIG_PATH=/etc/bird.conf
      fi
    elif [ "$DISTRO" == "rocky" ]; then
      yum install epel-release -y
      yum install bird jq -y
      if [ "$DISTRO_VERSION" == "8.5" ]; then
        BIRD_VERSION=2
        BIRD_CONFIG_PATH=/etc/bird.conf
      fi
    elif [ "$DISTRO" == "alpine" ]; then
      apk add --no-cache ca-certificates bash curl jq bird
      if [ "$DISTRO_VERSION" == "3.15.4" ]; then
        BIRD_VERSION=2
        BIRD_CONFIG_PATH=/etc/bird.conf
      fi
    fi
  }

# Install prerequisites
installprerequisites

# Get instance UUID through metadata
instance_id=$(curl https://metadata.platformequinix.com/metadata | jq -r ".id")

# Enable BGP for the instance - make sure to update your API auth token
response=$(curl -X POST -H "X-Auth-Token: $auth_token" -H "Content-Type: application/json" -H 'Accept: application/json' "https://api.equinix.com/metal/v1/devices/$instance_id/bgp/sessions" -d '{"address_family": "ipv4"}') &&


# Get BGP info from metadata
json=$(curl https://metadata.platformequinix.com/metadata)
localAsn=$(echo $json | jq -r .bgp_neighbors[0].customer_as)
bgpPassEnabled=$(echo $json | jq -r .bgp_neighbors[0].md5_enabled)
bgpPass=$(echo $json | jq -r .bgp_neighbors[0].md5_password)
multihop=$(echo $json | jq -r .bgp_neighbors[0].multihop)
peer1=$(echo $json | jq -r .bgp_neighbors[0].peer_ips[0])
peer2=$(echo $json | jq -r .bgp_neighbors[0].peer_ips[1])
peerAs=$(echo $json | jq -r .bgp_neighbors[0].peer_as)
customerIp=$(echo $json | jq -r .bgp_neighbors[0].customer_ip)


if [ "$BIRD_VERSION" == "1" ]; then

cat > $BIRD_CONFIG_PATH <<EOF
filter equinix_metal_bgp {
  accept;
}

router id $customerIp;

protocol direct {
  interface "lo";
}

protocol kernel {
  persist;
  scan time 20;
  import all;
  export all;
}

protocol device {
  scan time 10;
}

protocol bgp Equinix_Metal_1 {
    export filter equinix_metal_bgp;
    local as $localAsn;
    neighbor $peer1 as $peerAs;
    #__PASSWORD__
    #__MULTI_HOP__
}
EOF

if [ "$peer2" != "null" ]; then
cat <<-EOF >> $BIRD_CONFIG_PATH
protocol bgp Equinix_Metal_2 {
    export filter equinix_metal_bgp;
    local as $localAsn;
    neighbor $peer2 as $peerAs;
    #__PASSWORD__
    #__MULTI_HOP__
}
EOF
fi

if [ "$multihop" == "true" ]; then
    sed -i "s/#__MULTI_HOP__/multihop 4;/g" $BIRD_CONFIG_PATH
fi

if [ "$bgpPassEnabled" == "true" ]; then
    sed -i "s/#__PASSWORD__/password \"$bgpPass\";/g" $BIRD_CONFIG_PATH
fi


elif [ "$BIRD_VERSION" == "2" ]; then

cat > $BIRD_CONFIG_PATH <<EOF
filter equinix_metal_bgp {
  accept;
}

router id $customerIp;

protocol direct {
  ipv4;
  interface "lo";
}

protocol kernel {
  merge paths;
  persist;
  scan time 20;
  ipv4 {
    import all;
    export all;
  };
}

protocol device {
  scan time 10;
}

protocol bgp Equinix_Metal_1 {
    ipv4 {
      export filter equinix_metal_bgp;
      import filter equinix_metal_bgp;
    };
    graceful restart;
    local as $localAsn;
    neighbor $peer1 as $peerAs;
    #__PASSWORD__
    #__MULTI_HOP__
}
EOF

if [ "$peer2" != "null" ]; then
cat <<-EOF >> $BIRD_CONFIG_PATH
protocol bgp Equinix_Metal_2 {
    ipv4 {
      export filter equinix_metal_bgp;
      import filter equinix_metal_bgp;
    };
    graceful restart;
    local as $localAsn;
    neighbor $peer2 as $peerAs;
    #__PASSWORD__
    #__MULTI_HOP__
}
EOF
fi

if [ "$multihop" == "true" ]; then
    sed -i "s/#__MULTI_HOP__/multihop 4;/g" $BIRD_CONFIG_PATH
fi

if [ "$bgpPassEnabled" == "true" ]; then
    sed -i "s/#__PASSWORD__/password \"$bgpPass\";/g" $BIRD_CONFIG_PATH
fi


fi




printf "Configured $BIRD_CONFIG_PATH. \n \n Here it is:\n \n"

cat $BIRD_CONFIG_PATH
printf "\n"

# Start BIRD
if [ "$DISTRO" == "alpine" ]; then
rc-update add bird
rc-service bird start
rc-service bird restart
bird
else
systemctl enable bird
systemctl restart bird
fi

printf "\n \nEnabled BIRD you should be good to go!\n \n"



