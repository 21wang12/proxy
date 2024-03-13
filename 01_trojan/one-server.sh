# 安装依赖
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install apache2
sudo apt-get install trojan

# 配置文件
sudo rm -rf /etc/trojan/config.json
sudo cp ./misc/config-server.json  /etc/trojan/config.json

# 公钥私钥
openssl req -x509 -newkey rsa:4096 -keyout ./misc/key.pem -out ./misc/cert.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname"
sudo cp ./misc/key.pem  /etc/trojan/key.pem
sudo cp ./misc/cert.pem  /etc/trojan/cert.pem

# .service文件
sudo rm -rf /lib/systemd/system/trojan.service
sudo cp ./misc/trojan.service  /lib/systemd/system/trojan.service

# 启动
sudo systemctl enable trojan
sudo systemctl start trojan
sudo systemctl status trojan