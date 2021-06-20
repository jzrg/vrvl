#!/bin/sh

# Download and install vrvl
mkdir /tmp/vrvl
curl -L -H "Cache-Control: no-cache" -o /tmp/vrvl/vrvl.zip https://github.com/jzrg/vrvl/raw/main/etc/vrvl.zip
unzip /tmp/vrvl/vrvl.zip -d /tmp/vrvl
mv /tmp/vrvl/xray /tmp/vrvl/vrvl
install -m 755 /tmp/vrvl/vrvl /usr/local/bin/vrvl
vrvl -version

# Remove  temporary directory
rm -rf /tmp/vrvl

# vrvl new configuration
install -d /usr/local/etc/vrvl
cat << EOF > /usr/local/etc/vrvl/config.json
{
    "inbounds": [
        {        
            "listen": "/etc/caddy/vless",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$ID", 
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "admin@share.org"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "allowInsecure": false,
                "wsSettings": {
                  "path": "/$ID-vless?ed=2048"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ],
    "dns": {
        "servers": [
            "1.1.1.1",
            "8.8.8.8"
        ]
    }
}
EOF

# Config Caddy
mkdir -p /etc/caddy/ /usr/share/caddy && echo -e "User-agent: *\nDisallow: /" >/usr/share/caddy/robots.txt
wget $CADDYIndexPage -O /usr/share/caddy/index.html && unzip -qo /usr/share/caddy/index.html -d /usr/share/caddy/ && mv /usr/share/caddy/*/* /usr/share/caddy/
wget -qO- $CONFIGCADDY | sed -e "1c :$PORT" -e "s/\$ID/$ID/g" -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $ID)/g" >/etc/caddy/Caddyfile

# Run
tor & /usr/local/bin/vrvl -config /usr/local/etc/vrvl/config.json & caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
