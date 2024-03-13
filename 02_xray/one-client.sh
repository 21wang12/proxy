brew install xray

rm -rf /usr/local/etc/xray/config.json
cp ./misc/config-client.json /usr/local/etc/xray/config.json

brew services run xray

# 该文件每12小时更新一次
wget https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat -O ./misc/geoip.dat
wget https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat -O ./misc/geosite.dat
cp -rf ./misc/geoip.dat /usr/local/share/xray/
cp -rf ./misc/geosite.dat /usr/local/share/xray
