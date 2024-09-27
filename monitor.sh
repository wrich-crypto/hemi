#!/bin/bash

check_and_restart_memory() {
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
    if awk "BEGIN {exit !($mem_usage > 90)}"; then
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
    elif awk "BEGIN {exit !($mem_usage > 70)}"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 内存使用率偏高。"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 内存使用率正常。"
    fi
}

check_and_restart_containers() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始检查Docker容器状态..."
    
    # 获取所有容器的ID和状态
    docker ps -a --format "{{.ID}}:{{.Status}}" | while IFS=':' read -r id status; do
        # 检查容器是否处于退出状态
        if [[ $status == Exited* ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 容器 $id 处于退出状态，正在重启..."
            docker start $id
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 容器 $id 已重启。"
        fi
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Docker容器状态检查完成。"
}

# 主循环
while true; do
    check_and_restart_memory
    check_and_restart_containers
    # 等待60秒
    sleep 60
done