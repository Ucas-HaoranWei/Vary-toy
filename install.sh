#!/bin/bash

# 安装所需依赖
install_dependencies() {
    # 检查并安装 jq, curl, tar, bzip2
    for dep in jq curl tar bzip2; do
        if ! command -v $dep >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y $dep
        fi
    done
}

# 在脚本开始时调用依赖安装函数
install_dependencies

# 默认的MAMBA_ROOT_PREFIX路径
DEFAULT_MAMBA_ROOT_PREFIX="/usr/local/bin"

# 显示用法信息
usage() {
    echo "用法: sudo $0 [--silent-install [custom_root_prefix]] [--silent-uninstall] [--silent-update]"
    echo "  --silent-install      静默模式安装，不进行任何交互"
    echo "  custom_root_prefix    (可选) 在静默模式下设置 MAMBA_ROOT_PREFIX 的路径"
    echo "  --silent-uninstall    静默模式卸载，不进行任何交互"
    echo "  --silent-update       静默模式更新，不进行任何交互"
    exit 1
}

# 安装micromamba
install_micromamba() {
    local mamba_prefix="$1"

    # 自动检测操作系统和处理器架构
    OS="$(uname)"
    ARCH="$(uname -m)"

    # 根据操作系统和架构设置下载链接
    case "$OS" in
        "Linux")
            case "$ARCH" in
                "x86_64") URL="https://micro.mamba.pm/api/micromamba/linux-64/latest" ;;
                "aarch64") URL="https://micro.mamba.pm/api/micromamba/linux-aarch64/latest" ;;
                "ppc64le") URL="https://micro.mamba.pm/api/micromamba/linux-ppc64le/latest" ;;
                *) echo "不支持的架构: $ARCH"; exit 1 ;;
            esac
            ;;
        "Darwin")
            case "$ARCH" in
                "x86_64") URL="https://micro.mamba.pm/api/micromamba/osx-64/latest" ;;
                "arm64") URL="https://micro.mamba.pm/api/micromamba/osx-arm64/latest" ;;
                *) echo "不支持的架构: $ARCH"; exit 1 ;;
            esac
            ;;
        *)
            echo "不支持的操作系统: $OS"; exit 1 ;;
    esac

    # 下载并解压 micromamba 到指定的路径
    echo "正在下载 micromamba..."
    if curl -Ls "$URL" | tar -xvj -C "$mamba_prefix"; then
        echo "micromamba 下载并解压完成。"
        ls -l /usr/local/bin/bin/micromamba
        echo "micromamba 赋予执行权限"
        chmod +x /usr/local/bin/bin/micromamba
        echo "micromamba 安装完成"
        echo "MAMBA_ROOT_PREFIX 路径：$mamba_prefix"
        # 初始化 shell 环境
        echo "正在为root初始化 micromamba shell 环境..."
        "$mamba_prefix/bin/micromamba" shell init -s bash -p "~/micromamba"
        ln -s /usr/local/bin/bin/micromamba /usr/local/bin/micromamba 
    else
        echo "micromamba 下载失败"
    fi
}

# 清理 .bashrc 文件
cleanup_bashrc() {
    local mamba_bin_path="$1"
    
    # 删除 .bashrc 中相关的行
    sed -i '/MICROMAMBA_BIN_PATH/d' ~/.bashrc
    sed -i '/MAMBA_ROOT_PREFIX/d' ~/.bashrc
    sed -i '/alias mba=/d' ~/.bashrc
}

# 删除micromamba
uninstall_micromamba() {

    echo "正在卸载 micromamba..."
    rm -rf /usr/local/bin/micromamba /usr/local/bin/bin /usr/local/bin/info /usr/local/bin/etc

    # 清理 .bashrc 文件
    cleanup_bashrc "$mamba_prefix"

    echo "micromamba 已卸载。"
}


# 获取当前 micromamba 版本
get_current_version() {
    local mamba_path="$1/micromamba"
    if [ -f "$mamba_path" ]; then
        local current_version
        current_version=$("$mamba_path" --version | grep -o 'version [^ ]*' | cut -d ' ' -f2 | cut -d '-' -f1)
        echo "$current_version"
    else
        echo "未安装"
    fi
}

# 获取最新的 micromamba 版本
get_latest_version() {
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/mamba-org/micromamba-releases/releases/latest | jq -r '.tag_name' | cut -d '-' -f1)
    echo "$latest_version"
}

# 检查是否有更新并提示用户
check_for_updates() {
    local current_version latest_version
    current_version=$(get_current_version "$1")
    latest_version=$(get_latest_version)

    if [ "$latest_version" != "$current_version" ]; then
        echo "有可用的更新：当前版本 $current_version, 最新版本 $latest_version"
        read -p "是否更新到最新版本? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            update_micromamba "$1"
        else
            echo "更新已取消"
        fi
    else
        echo "当前已是最新版本 ($current_version)"
    fi
}

# 更新micromamba
update_micromamba() {
    local mamba_prefix="$1"
    local current_version latest_version
    current_version=$(get_current_version "$mamba_prefix")
    latest_version=$(get_latest_version)

    if [ "$latest_version" != "$current_version" ]; then
        echo "有可用的更新：当前版本 $current_version, 最新版本 $latest_version"
        read -p "是否更新到最新版本? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo "正在卸载旧版本 micromamba..."
            uninstall_micromamba "$mamba_prefix"
            echo "正在安装最新版本 micromamba..."
            install_micromamba "$mamba_prefix"
        else
            echo "更新已取消"
        fi
    else
        echo "当前已是最新版本 ($current_version)"
    fi
}


# 交互式安装、卸载和更新菜单
interactive_menu() {
    local current_version latest_version
    current_version=$(get_current_version "$DEFAULT_MAMBA_ROOT_PREFIX")
    latest_version=$(get_latest_version)

    # 检测并显示当前和最新版本
    echo "当前 micromamba 版本: $current_version"
    echo "最新 micromamba 版本: $latest_version"
    if [ "$latest_version" != "$current_version" ]; then
        echo "有可用的更新。"
    fi

    echo "选择操作："
    echo "1) 安装 micromamba"
    echo "2) 删除 micromamba"
    echo "3) 更新 micromamba"
    echo "q) 退出"
    read -p "请输入选项（1、2、3或q）: " main_choice

    case "$main_choice" in
        1)
            echo "MAMBA_ROOT_PREFIX 的路径: $DEFAULT_MAMBA_ROOT_PREFIX: " 
            install_micromamba "$DEFAULT_MAMBA_ROOT_PREFIX"
            ;;
        2)
            uninstall_micromamba "$DEFAULT_MAMBA_ROOT_PREFIX"
            ;;
        3)
            update_micromamba "$DEFAULT_MAMBA_ROOT_PREFIX"
            ;;
        q)
            echo "退出。"
            exit 0
            ;;
        *)
            echo "无效的选项。退出。"
            exit 1
            ;;
    esac
}

# 静默卸载
silent_uninstall() {
    # 在卸载之前保留虚拟环境目录
    local envs_dir="$DEFAULT_MAMBA_ROOT_PREFIX/envs"
    mkdir -p "$envs_dir"
    mv "$DEFAULT_MAMBA_ROOT_PREFIX/envs" "$(mktemp -d)"
    uninstall_micromamba "$DEFAULT_MAMBA_ROOT_PREFIX"
    mv "$(mktemp -d)/envs" "$envs_dir"
}

# 静默更新
silent_update() {
    update_micromamba "$DEFAULT_MAMBA_ROOT_PREFIX"
}

# 解析命令行参数
if [ "$1" = "--silent-install" ]; then
    silent_install "$2"
elif [ "$1" = "--silent-uninstall" ]; then
    silent_uninstall
elif [ "$1" = "--silent-update" ]; then
    silent_update
elif [ "$1" = "--help" ]; then
    usage
else
    interactive_menu
fi
