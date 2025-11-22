#!/bin/bash

# ステップ7: 複数コンテナの同時起動
#
# 目的:
# - 複数の独立したコンテナを同時に立ち上げる
# - nsenter を使って個々のコンテナにアタッチする流れを体験する

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="${ROOTFS:-"$SCRIPT_DIR/rootfs"}"
DEFAULT_COUNT=2

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
    echo "[ホスト] sudo権限を事前確認しています (パスワード入力は一度だけ)" 
    $SUDO -v
else
    SUDO=""
fi

if [ ! -d "$ROOTFS" ]; then
    echo "エラー: $ROOTFS が見つかりません"
    echo "まず ./setup_rootfs.sh を実行してください"
    exit 1
fi

mkdir -p "$ROOTFS/proc"

CONTAINER_COUNT="${1:-$DEFAULT_COUNT}"
if ! [[ "$CONTAINER_COUNT" =~ ^[0-9]+$ ]] || [ "$CONTAINER_COUNT" -lt 1 ]; then
    echo "使用方法: $0 [コンテナ数]"
    echo "例: $0 3"
    exit 1
fi

CONTAINER_PIDS=()
CONTAINER_NAMES=()

cleanup() {
    echo
    echo "[ホスト] コンテナを終了しています..."
    for pid in "${CONTAINER_PIDS[@]}"; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            $SUDO kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done
}
trap cleanup EXIT INT TERM

echo "===== ステップ7: 複数コンテナの同時起動 ====="
echo "[ホスト] 起動するコンテナ数: $CONTAINER_COUNT"
echo
echo "[ホスト] スクリプトディレクトリ: $SCRIPT_DIR"
echo "[ホスト] 使用するrootfs: $ROOTFS"
echo

start_container() {
    local container_name="$1"

    echo "[ホスト] コンテナ '$container_name' を起動します..."
    $SUDO unshare --pid --mount --uts --net --fork chroot "$ROOTFS" /bin/sh -c "
        hostname $container_name
        mount -t proc proc /proc
        if command -v ip >/dev/null 2>&1; then
            ip link set lo up || true
        fi
        echo '[コンテナ:$container_name] 起動！ PID: \\$$'
        exec sleep 999999
    " &

    local pid=$!
    sleep 0.1
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "[ホスト] $container_name の起動に失敗しました"
        exit 1
    fi

    CONTAINER_PIDS+=("$pid")
    CONTAINER_NAMES+=("$container_name")
}

for i in $(seq 1 "$CONTAINER_COUNT"); do
    start_container "multi-container-$i"
done

echo
for idx in "${!CONTAINER_PIDS[@]}"; do
    host_name="${CONTAINER_NAMES[$idx]}"
    host_pid="${CONTAINER_PIDS[$idx]}"
    echo "[ホスト] $host_name が起動しました (ホスト側PID: $host_pid)"
    echo "        アタッチ: sudo nsenter --target $host_pid --pid --mount --uts --net /bin/sh"
    echo
    echo "        コンテナ内で試す:"
    echo "          hostname   # 各コンテナ固有のホスト名"
    echo "          ps aux     # PID namespace が隔離されている"
    echo
    echo "        終了方法: コンテナ内で 'exit'、またはホストで 'sudo kill $host_pid'"
    echo "------------------------------------------------------------"
    echo
done

echo "[ホスト] コンテナが起動しています。必要なコンテナに nsenter で接続してください。"
echo "[ホスト] Ctrl+C で全コンテナをまとめて終了します。"

# スクリプトをブロックしてコンテナを動かし続ける
wait
