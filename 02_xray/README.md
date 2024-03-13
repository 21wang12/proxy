
# Xray标准配置文件
参考[chika0801](https://github.com/chika0801/Xray-examples)的配置文件

服务端配置
```json
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "ip": [
                    "geoip:cn",
                    "geoip:private"
                ],
                "outboundTag": "block"
            }
        ]
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "heisenberg",  // 长度为 1-30 字节的任意字符串，或执行 xray uuid 生成
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "dest": "www.lovelive-anime.jp:443", // 目标网站最低标准：国外网站，支持 TLSv1.3、X25519 与 H2，域名非跳转用（主域名可能被用于跳转到 www）
                    "serverNames": [ 
                        "www.lovelive-anime.jp", // 客户端可用的 serverName 列表，暂不支持 * 通配符
                        "lovelive-anime.jp" // Chrome - 输入 "dest" 的网址 - F12 - 安全 - F5 - 主要来源（安全），填 证书 SAN 的值
                    ],
                    "privateKey": "4ANjE1OpPMwMPKmldTiNdhImqtQCk1cfAGpmRpAAkyE", // 执行 xray x25519 生成，填 "Private key" 的值
                    "shortIds": [  // 客户端可用的 shortId 列表，可用于区分不同的客户端
                        "7595346f373cf8a2", // 0 到 f，长度为 2 的倍数，长度上限为 16，可留空，或执行 openssl rand -hex 8 生成
                        "0c2c447802246934",
                        "100d3780208d3925"
                    ]
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls",
                    "quic"
                ]
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
```

客户端配置
```json
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
    "rules": [
      {
        "type": "field",
        "outboundTag": "block",
        "domain": ["geosite:category-ads-all"]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
            "geosite:tld-cn",
            "geosite:icloud",
            "geosite:category-games@cn",
            "geosite:cn",
            "geosite:private"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
            "geoip:cn", 
            "geoip:private"
        ]
      },
      {
        "type": "field",
        "outboundTag": "proxy",
        "domain": [
            "geosite:geolocation-!cn",
            "full:www.icloud.com",
            "domain:icloud-content.com",
            "geosite:google"
        ]
      }
    ]
  },
    "inbounds": [
        {
            "listen": "127.0.0.1",
            "port": 10808,
            "protocol": "socks"
        },
        {
            "listen": "127.0.0.1",
            "port": 10809,
            "protocol": "http"
        }
    ],
    "outbounds": [
        {
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": "185.148.13.236",  // 服务端ip地址
                        "port": 443,
                        "users": [
                            {
                                "id": "heisenberg", // 与服务端的uuid一致
                                "encryption": "none",
                                "flow": "xtls-rprx-vision"
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "fingerprint": "chrome",
                    "serverName": "www.lovelive-anime.jp", // 与服务端一致
                    "publicKey": "sbfXNqEarzFSmDKBR3pewl2k1tBGaWiVQXogRfPqMg8", // 服务端执行 xray x25519 生成，私钥对应的公钥，填 "Public key" 的值
                    "shortId": "7595346f373cf8a2" // 与服务端一致
                }
            },
            "tag": "proxy"
        },
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
```

# 服务端安装Xray
使用[该项目](https://github.com/XTLS/Xray-install)的脚本进行安装

```bash
mkdir xray && cd xray
wget https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh -O install.sh

chmod 777 ./install.sh
./install.sh help #查看帮助文档
./install.sh install # 安装xray
```
安装完成后将`/etc/systemd/system/xray.service` 文件中的`User`字段修改为当前用户或`root`用户

```bash
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root   #TODO: Modify
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
```

安装过程中会产生如下文件
```bash
# 守护进程描述文件（由systemctl进行控制）
installed: /etc/systemd/system/xray.service
installed: /etc/systemd/system/xray@.service

# Xray程序
installed: /usr/local/bin/xray
# Xray守护进程使用的配置文件
installed: /usr/local/etc/xray/config.json

# 分流文件，可参考 
# 1. https://xtls.github.io/document/level-1/routing-lv1-part2.html#_5-攻城略池-多种路由匹配条件
# 2. https://xtls.github.io/config/routing.html#ruleobject
## 基于ip的分流文件（config.json会默认从此路径中查找）
installed: /usr/local/share/xray/geoip.dat
## 基于域名的分流文件（config.json会默认从此路径中查找）
installed: /usr/local/share/xray/geosite.dat

# 日志文件
installed: /var/log/xray/access.log
installed: /var/log/xray/error.log
```


# 客户端安装Xray
## Macos安装方式
```bash
brew install xray
```

安装过程中会产生如下文件
```bash
配置文件: /usr/local/etc/xray/config.json
主程序: /usr/local/opt/xray/bin/xray
路由ip: /usr/local/share/xray/geoip.dat
路由域名: /usr/local/share/xray/geosite.dat
```

<!-- TODO: 直接运行会报错，无法找到配置文件 -->
安装之后通过以下命令启动Xray
```bash
# 使用brew以守护进程方式运行Xray
brew services run xray
# 设置开机自启动Xray
brew services start xray
# 以普通程序的方式运行Xray
/usr/local/opt/xray/bin/xray run --config /usr/local/etc/xray/config.json
```


# 启动

服务端启动方式
修改好配置后，请通过systemctl重新启动xray

```bash
systemctl status xray
```

客户端启动方式



# 附录
## shadowrocket配置
| 名称 | 值 |
| :--- | :--- |
| 类型 | VLESS |
| 地址 | 服务端的 IP |
| 端口 | 443 |
| UUID | chika |
| TLS | 选上 |
| XTLS | xtls-rprx-vision |
| 允许不安全 | 不选 |
| SNI | `www.lovelive-anime.jp` |
| ALPN | 留空 |
| 公钥 | Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw |
| 短 ID | 6ba85179e30d4fc2 |
| 传输方式 | none |
| 多路复用 | 不选 |
| TCP 快速打开 | 不选 |
| UDP 转发 | 选上 |
| 代理通过 | 不选 |

## 杂项
终端代理
```bash
export all_proxy=socks5://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10809 
export http_proxy=http://127.0.0.1:10809
```

macos系统代理，参考[How to set proxy on OS X Terminal permanently?](https://apple.stackexchange.com/questions/226544/how-to-set-proxy-on-os-x-terminal-permanently)
```bash
networksetup -setwebproxy wi-fi localhost 10809
networksetup -setwebproxystate wi-fi on
networksetup -setwebproxystate wi-fi off

networksetup -setsocksfirewallproxy wi-fi localhost 10808
networksetup -setsocksfirewallproxystate wi-fi on
networksetup -setsocksfirewallproxystate wi-fi off

scutil --nwi | awk -F': ' '/Network interfaces/ {print $2;exit;}'
```

路由文件
geoip: https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat
getsite: https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat