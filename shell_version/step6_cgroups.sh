#!/bin/bash

# ステップ6: cgroups によるリソース制限（Shell版）
#
# CPU、メモリなどのリソース使用量を制限します
#
# 学習ポイント:
# - cgroups (Control Groups) の使い方
# - メモリ制限の設定
# - CPU制限の設定
# - リソース使用量の監視

set -e

ROOTFS="./rootfs"
CONTAINER_HOSTNAME="my-container"
CGROUP_NAME="my_container_$$"
MEMORY_LIMIT="100M"  # メモリ制限: 100MB
CPU_QUOTA="50000"    # CPU制限: 50% (100000が100%)

echo "===== ステップ6: cgroups リソース制限コンテナ (Shell版) ====="
echo

if [ ! -d "$ROOTFS" ]; then
    echo "エラー: $ROOTFS が見つかりません"
    echo "まず ./setup_rootfs.sh を実行してください"
    exit 1
fi

# cgroup v2 をチェック
if [ -d "/sys/fs/cgroup/cgroup.controllers" ]; then
    CGROUP_VERSION="v2"
    CGROUP_PATH="/sys/fs/cgroup/$CGROUP_NAME"
elif [ -d "/sys/fs/cgroup/memory" ]; then
    CGROUP_VERSION="v1"
    CGROUP_MEMORY_PATH="/sys/fs/cgroup/memory/$CGROUP_NAME"
    CGROUP_CPU_PATH="/sys/fs/cgroup/cpu/$CGROUP_NAME"
else
    echo "⚠️  警告: cgroupが見つかりません"
    echo "このシステムではcgroupsが利用できない可能性があります"
    CGROUP_VERSION="none"
fi

echo "[ホスト] cgroup バージョン: $CGROUP_VERSION"
echo "[ホスト] メモリ制限: $MEMORY_LIMIT"
echo "[ホスト] CPU制限: $(( CPU_QUOTA / 1000 ))%"
echo

# cgroupのセットアップ（v2の場合）
setup_cgroup_v2() {
    echo "[ホスト] cgroup v2 のセットアップ中..."

    # cgroupディレクトリを作成
    sudo mkdir -p "$CGROUP_PATH"

    # メモリ制限を設定
    echo "$MEMORY_LIMIT" | sudo tee "$CGROUP_PATH/memory.max" > /dev/null

    # CPU制限を設定
    echo "$CPU_QUOTA 100000" | sudo tee "$CGROUP_PATH/cpu.max" > /dev/null

    echo "[ホスト] cgroup設定完了"
}

# cgroupのセットアップ（v1の場合）
setup_cgroup_v1() {
    echo "[ホスト] cgroup v1 のセットアップ中..."

    # メモリcgroupを作成
    sudo mkdir -p "$CGROUP_MEMORY_PATH"
    echo "$MEMORY_LIMIT" | sudo tee "$CGROUP_MEMORY_PATH/memory.limit_in_bytes" > /dev/null

    # CPU cgroupを作成
    sudo mkdir -p "$CGROUP_CPU_PATH"
    echo "$CPU_QUOTA" | sudo tee "$CGROUP_CPU_PATH/cpu.cfs_quota_us" > /dev/null
    echo "100000" | sudo tee "$CGROUP_CPU_PATH/cpu.cfs_period_us" > /dev/null

    echo "[ホスト] cgroup設定完了"
}

# cgroupのクリーンアップ
cleanup_cgroup() {
    if [ "$CGROUP_VERSION" = "v2" ]; then
        sudo rmdir "$CGROUP_PATH" 2>/dev/null || true
    elif [ "$CGROUP_VERSION" = "v1" ]; then
        sudo rmdir "$CGROUP_MEMORY_PATH" 2>/dev/null || true
        sudo rmdir "$CGROUP_CPU_PATH" 2>/dev/null || true
    fi
}

# 終了時にクリーンアップ
trap cleanup_cgroup EXIT

# cgroupのセットアップ
if [ "$CGROUP_VERSION" = "v2" ]; then
    setup_cgroup_v2
elif [ "$CGROUP_VERSION" = "v1" ]; then
    setup_cgroup_v1
fi

echo
echo "[コンテナ] コンテナを起動..."
echo "=========================================="
echo

# コンテナプロセスを起動
sudo unshare --pid --mount --uts --fork bash -c "
    # このプロセスをcgroupに追加
    if [ '$CGROUP_VERSION' = 'v2' ]; then
        echo \$\$ | sudo tee $CGROUP_PATH/cgroup.procs > /dev/null
    elif [ '$CGROUP_VERSION' = 'v1' ]; then
        echo \$\$ | sudo tee $CGROUP_MEMORY_PATH/cgroup.procs > /dev/null
        echo \$\$ | sudo tee $CGROUP_CPU_PATH/cgroup.procs > /dev/null
    fi

    # コンテナ環境を設定
    hostname $CONTAINER_HOSTNAME
    cd $ROOTFS
    mount -t proc proc proc

    echo '[コンテナ] cgroups リソース制限コンテナ起動！'
    echo
    echo '========== コンテナ情報 =========='
    echo 'PID: \$\$'
    echo 'ホスト名: \$(hostname)'
    echo 'メモリ制限: $MEMORY_LIMIT'
    echo 'CPU制限: $(( CPU_QUOTA / 1000 ))%'
    echo '=================================='
    echo
    echo '📝 リソース制限が有効です:'
    echo '  - メモリを$MEMORY_LIMIT以上使おうとするとプロセスが停止します'
    echo '  - CPUは$(( CPU_QUOTA / 1000 ))%までしか使えません'
    echo
    echo '試してみましょう:'
    echo '  # メモリを大量に使うテスト（制限を超えるとkillされます）'
    echo '  # yes | head -c 200M | tail'
    echo
    echo '  # CPU使用率を確認'
    echo '  # yes > /dev/null &  # バックグラウンドでCPU負荷'
    echo '  # top                # CPU使用率を確認'
    echo
    echo '  exit  # コンテナを終了'
    echo

    chroot . /bin/sh
"

echo
echo "=========================================="
echo "[ホスト] コンテナが終了しました"
echo

if [ "$CGROUP_VERSION" != "none" ]; then
    echo "💡 学んだこと:"
    echo "  ✅ cgroupsでメモリとCPUを制限しました"
    echo "  ✅ コンテナは設定されたリソース以上を使えません"
    echo "  ✅ これによりシステムの安定性が向上します"
else
    echo "⚠️  この環境ではcgroupsが利用できませんでした"
fi
