#!/bin/bash

# 定义项目的最新发布页面 URL
release_url="https://git.songwqs.top/https://github.com/AlistGo/alist/releases/latest"

# 获取最新发布页面内容
releases_page=$(curl -sL "$release_url")

# 检查 curl 是否成功获取内容
if [[ $? -ne 0 || -z "$releases_page" ]]; then
    echo "无法访问 $release_url，请检查网络连接或代理设置。"
    exit 1
fi

# 使用正则表达式从页面内容中提取版本号
if [[ $releases_page =~ (v[0-9]+\.[0-9]+\.[0-9]+) ]]; then
    latest_version=${BASH_REMATCH[1]}
    echo "AlistGo/alist的最新版本号是: $latest_version"

    # 自动检测架构
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCHIVE_NAME="alist-linux-musl-amd64.tar.gz" ;;
        aarch64) ARCHIVE_NAME="alist-linux-musl-arm64.tar.gz" ;;
        armv7l) ARCHIVE_NAME="alist-linux-musl-armv7.tar.gz" ;;
        *)
            echo "不支持的架构: $ARCH"
            exit 1
            ;;
    esac

    # 构造下载链接
    download_url="https://git.songwqs.top/https://github.com/AlistGo/alist/releases/download/$latest_version/$ARCHIVE_NAME"
    echo "即将下载最新版本: $download_url"

    # 下载并解压
    temp_dir=$(mktemp -d)
    wget -qO- "$download_url" | tar xz -C "$temp_dir"
    if [[ -f "$temp_dir/alist" ]]; then
        echo "下载成功，正在替换旧版本..."
        mv "$temp_dir/alist" /usr/bin/alist
        chmod +x /usr/bin/alist

        # 验证版本
        installed_version=$(/usr/bin/alist version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
        echo "检测到已安装版本: $installed_version"

        if [[ $installed_version == "$latest_version" ]]; then
            echo "Alist 已成功更新到版本 $latest_version"
        else
            echo "更新失败，请检查替换流程。"
            echo "期望版本: $latest_version"
            echo "已安装版本: $installed_version"
        fi
    else
        echo "下载或解压失败，请检查下载链接或代理配置。"
        exit 1
    fi

    # 清理临时目录
    rm -rf "$temp_dir"
else
    echo "无法从页面中提取版本号，请检查正则表达式或页面格式。"
    exit 1
fi
