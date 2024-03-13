# Trojan 无域名配置教程

## 一键脚本
```bash
chmod 777 one.sh
sudo ./one.sh
```

## 环境说明

- 服务端使用 Ubuntu 20.04 + [Trojan](https://github.com/trojan-gfw/trojan)
- 海外服务器供应商为[Cloudsilk](https://cloudsilk.io/)
- 客户端使用 Macos + ClashX

## 服务端配置

### 准备工作

首先需要准备好自签证书[<sup>1</sup>](#ref1)，通过以下运行命令可以在当前目录下创建`cert.pem` 和 `key.pem`文件[<sup>2</sup>](#ref2)。该文件所在路径需要填入 trojan 的配置文件当中。

```bash
# interactive
openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365

# non-interactive and 10 years expiration
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname"
```

其次需要开启 apache 服务程序安装 apache 服务器的命令如下，apache 的默认根目录为`/var/www/html`：

```bash
sudo apt-get install apache2
```

服务器安装 apache 服务程序之后，apache 会自动开启。为了测试是否成功开启，可以在客户端的浏览器的地址栏中输入`http://ipaddr`。其中`ipaddr`是服务器供应商提供的访问服务器的 ip 地址。


### 安装 Trojan 程序

```bash
sudo apt-get update
sudo apt-get install trojan
```

安装 trojan 程序之后。可以通过`命令行`的方式启动 `trojan 服务程序`，也可使用`systemctl`控制 `trojan 服务程序`的启动。

启动`trojan服务程序`需要一份`json`格式的配置文件，该配置文件会在安装 trojan 程序之后，自动生成一份名为`/etc/trojan/config.json`的 trojan 服务程序配置文件。我们需要将该配置文件修改为如下内容后才可正常使用：

```json
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443, // TODO (Optinal): server port used to run trojan server program
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": ["qwerty"], // TODO (Optional): password used in trojan client program
  "log_level": 1,
  "ssl": {
    "cert": "/path/to/cert.pem", // TODO: Modify path to your cert file
    "key": "/path/to/key.pem", // TODO: Modify path to your key file
    "key_password": "",
    "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
    "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
    "prefer_server_cipher": true,
    "alpn": ["http/1.1"],
    "reuse_session": true,
    "session_ticket": false,
    "session_timeout": 600,
    "plain_http_response": "",
    "curves": "",
    "dhparam": ""
  },
  "tcp": {
    "prefer_ipv4": false,
    "no_delay": true,
    "keep_alive": true,
    "reuse_port": false,
    "fast_open": false,
    "fast_open_qlen": 20
  },
  "mysql": {
    "enabled": false,
    "server_addr": "127.0.0.1",
    "server_port": 3306,
    "database": "trojan",
    "username": "trojan",
    "password": ""
  }
}
```

其中我们需要将改配置文件中的`ssl.cert`字段填入**准备工作**当中生成的`cert.pem`所在路径，`ssl.key`字段填入**准备工作**当中生成的`key.pem`所在路径。

### 启动 Trojan 服务程序

在命令行中输入以下命令，即可启动程序

```bash
trojan -c /etc/trojan/config.json
```

我们也可以通过 systemctl 来启动 trojan。此时`systemctl`会载入 trojan 服务文件`/lib/systemd/system/trojan.service`。torjan 服务文件会默认使用路径为`/etc/trojan/config.json`的配置文件作为 trojan 服务程序的启动配置。

Trojan 的作者为了安全起见，将`/lib/systemd/system/trojan.service`中的`User`设置为了`nobody`，因此需要将该字段修改为登陆用户或者`root`用户，否则该服务会无法启动。修改后的`/lib/systemd/system/trojan.service`如下所示。

```bash
[Unit]
Description=trojan
Documentation=man:trojan(1) https://trojan-gfw.github.io/trojan/config https://trojan-gfw.github.io/trojan/
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service

[Service]
Type=simple
StandardError=journal
User=root   # TODO: Modifiy to current user
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/bin/trojan /etc/trojan/config.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
```

对`trojan.service`进行修改后，通过运行如下命令行重新启动`systemctl`服务。

```bash
systemctl daemon-reload
```

使用如下命令查看 trojan 的状态

```bash
systemctl status trojan
```

如果 trojan 显示的状态为`inactive`，则通过如下命令启动 trojan 服务程序

```bash
systemctl strat trojan
```

# 设置伪动态端口

1. 使用 iptables 设置规则进行端口转发：https://zgao.top/trojan-443端口被封的简单解决思路/
2. iptable 如何删除设置的规则: https://www.cyberciti.biz/faq/linux-iptables-delete-prerouting-rule-command/

# 客户端配置
## macos
导入`misc/clash.yaml`文件至clash，或将该文件放入apache服务器的根目录`/var/www/html/clash.yaml`后，在clash当中订阅`<ipaddr>/clash.yaml`。eg:`185.148.13.236/clash.yaml`
## shadowrocket
地址: 本机ip地址
端口: 444
密码: qwerty


# 参考文献
<a id="ref1"  href="https://github.com/trojan-gfw/trojan/issues/635#issuecomment-1146872828">Github: 有无自签名证书使用成功的例子?</a>

<a id="ref2"  href="https://stackoverflow.com/questions/51340872/can-i-certify-website-without-domain-name">Stackoverflow: Can I certify website without domain name?</a>


