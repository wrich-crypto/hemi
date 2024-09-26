#!/bin/bash

check_and_restart() {
    # 获取内存信息
    mem_info=$(free | grep Mem)

    # 提取总内存和已用内存
    total_mem=$(echo $mem_info | awk '{print $2}')
    used_mem=$(echo $mem_info | awk '{print $3}')

    # 计算内存使用率
    mem_usage=$(awk "BEGIN {printf \"%.2f\", $used_mem/$total_mem*100}")

    # 输出结果
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 内存使用率: $mem_usage%"

    # 检查内存使用率并采取相应操作
    if (( $(echo "$mem_usage > 90" | bc -l) )); then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 内存使用率严重偏高！正在重启所有Docker容器..."
        
        # 停止所有Docker容器
        echo "正在停止所有Docker容器..."
        docker stop $(docker ps -aq)
        
        # 等待几秒钟确保所有容器都已停止
        sleep 5
        
        # 启动所有Docker容器
        echo "正在启动所有Docker容器..."
        docker start $(docker ps -aq)
        
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Docker容器重启完成。"
    elif (( $(echo "$mem_usage > 70" | bc -l) )); then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 内存使用率偏高。"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 内存使用率正常。"
    fi
}

# 主循环
while true; do
    check_and_restart
    # 等待60秒
    sleep 60
done