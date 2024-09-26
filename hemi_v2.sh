#!/bin/bash

# 定义静态环境变量
POPM_BFG_URL="wss://testnet.rpc.hemi.network/v1/ws/public"
POPM_STATIC_FEE="10"

# 读取bitcoin.txt文件，每行包含一个私钥
mapfile -t btc_privkeys < bitcoin.txt

# 读取proxy.txt文件，每行包含一个代理
mapfile -t proxies < proxy.txt

# 检查私钥和代理数量是否匹配
if [ ${#btc_privkeys[@]} -ne ${#proxies[@]} ]; then
    echo "错误：私钥数量与代理数量不匹配。请确保两个文件中的行数相同。"
    exit 1
fi

# 获取总行数
total_lines=${#btc_privkeys[@]}

# 循环启动容器
for i in $(seq 1 $total_lines); do
    # 获取当前的私钥和代理
    POPM_BTC_PRIVKEY="${btc_privkeys[$((i-1))]}"
    proxy="${proxies[$((i-1))]}"
    
    # 解析代理信息
    IFS=':' read -r proxy_ip proxy_port proxy_user proxy_pass <<< "$proxy"
    HTTP_PROXY="http://${proxy_user}:${proxy_pass}@${proxy_ip}:${proxy_port}"
    
    # 定义容器名称
    container_name="popmd_container_$i"
    
    # 打印当前启动的容器和对应的私钥和代理
    echo "正在启动容器 $container_name，BTC私钥: $POPM_BTC_PRIVKEY，HTTP代理: $HTTP_PROXY"
    
    # 拉取指定版本的Docker镜像
    docker pull hemilabs/popmd:0.4.3
    
    # 启动 Docker 容器并设置 HTTP_PROXY 和其他环境变量
    docker run -d \
      --name "$container_name" \
      -e POPM_BTC_PRIVKEY="$POPM_BTC_PRIVKEY" \
      -e POPM_BFG_URL="$POPM_BFG_URL" \
      -e POPM_STATIC_FEE="$POPM_STATIC_FEE" \
      -e HTTP_PROXY="$HTTP_PROXY" \
      -e HTTPS_PROXY="$HTTP_PROXY" \
      hemilabs/popmd:0.4.3
    
    # 检查容器是否启动成功
    if [ $? -eq 0 ]; then
        echo "容器 $container_name 启动成功。"
    else
        echo "容器 $container_name 启动失败。"
    fi
    
    # 可根据需要在容器启动之间设置延时
    # sleep 1
done

echo "所有 $total_lines 个容器已启动。"