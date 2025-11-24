# Shell版 コンテナ学習プロジェクト

Linuxコンテナの仕組みを学ぶための、Shellスクリプトで実装したシンプルなコンテナです。

## 特徴

- **シンプル**: Shellスクリプトのみ
- **段階的学習**: 7つのステップで徐々に機能を追加
- **実践的**: Dockerと同じLinuxカーネル機能を使用
- **理解しやすい**: コメント付きで各コマンドの意味を説明

## 必要な環境

- Linux環境（WSL2でも動作）
- bash
- sudo権限
- 基本的なLinuxコマンド（unshare, chroot, mountなど）

## セットアップ

### 1. rootfsの準備

```bash
chmod +x *.sh
./setup_rootfs.sh
```

このスクリプトは：
- Alpine Linux（軽量Linuxディストリビューション）をダウンロード
- `./rootfs` ディレクトリに展開
- 必要なディレクトリを作成

### 2. 各ステップの実行

#### ステップ1: 基本的なchroot

```bash
./step1_chroot.sh
```

**学ぶこと**:
- `chroot` コマンドの使い方
- ファイルシステムの隔離
- ルートディレクトリの変更

**確認すること**:
```bash
# コンテナ内で実行
ls /          # 隔離されたファイルシステム
pwd           # 現在のディレクトリ
ps aux        # まだホストのプロセスが見える
```

---

#### ステップ2: PID Namespace

```bash
./step2_pid_namespace.sh
```

**学ぶこと**:
- `unshare` コマンドの使い方
- PID namespaceの作成
- プロセスの隔離の第一歩

**確認すること**:
```bash
# コンテナ内で実行
echo $$       # このシェルのPID
ps aux        # まだホストのプロセスが見える（/procが共有）
```

---

#### ステップ3: Mount Namespace

```bash
./step3_mount_namespace.sh
```

**学ぶこと**:
- Mount namespaceの作成
- `/proc` の再マウント
- 完全なプロセス隔離

**確認すること**:
```bash
# コンテナ内で実行
ps aux        # コンテナ内のプロセスだけが見える！
ls /proc      # 隔離されたプロセス情報
```

---

#### ステップ4: フル機能コンテナ

```bash
./step4_full_container.sh
```

**学ぶこと**:
- 複数のnamespaceの組み合わせ
- UTS namespace（ホスト名の隔離）
- より完全なコンテナ環境

**確認すること**:
```bash
# コンテナ内で実行
hostname      # コンテナ独自のホスト名
ps aux        # 隔離されたプロセス
ls /          # 隔離されたファイルシステム
```

---

#### ステップ5: Network Namespace

```bash
./step5_network_namespace.sh
```

**学ぶこと**:
- Network namespaceの作成
- ネットワークの完全な隔離
- 独立したネットワークスタック

**確認すること**:
```bash
# コンテナ内で実行
cat /proc/net/dev    # ネットワークデバイスの確認
hostname             # コンテナのホスト名
# ホストのネットワークは見えません
```

---

#### ステップ6: cgroups（リソース制限）

```bash
./step6_cgroups.sh
```

**学ぶこと**:
- cgroups (Control Groups) の使い方
- メモリ制限の設定
- CPU制限の設定
- リソース使用量の監視

**確認すること**:
```bash
# コンテナ内で実行
# メモリを大量に使うテスト（制限を超えるとkillされます）
# yes | head -c 200M | tail

# CPU使用率を確認
# yes > /dev/null &  # バックグラウンドでCPU負荷
# top                # CPU使用率を確認（制限されている）
```

---

#### ステップ7: 複数コンテナの同時起動

```bash
./step7_multi_container.sh          # デフォルトで2つ起動
./step7_multi_container.sh 3        # 3つ起動したい場合
```

**学ぶこと**:
- 複数のコンテナを同時に立ち上げるフロー
- `nsenter` で特定のコンテナにアタッチする方法

**ポイント**:
- スクリプトは自動で `shell_version/rootfs` を参照（どのディレクトリから呼んでもOK）
- 起動時に一度だけ `sudo` 認証を行い、終了時は全コンテナをまとめてクリーンアップ

**確認すること**:
```bash
# ホスト側で表示される nsenter コマンド例を実行
sudo nsenter --target <PID> --pid --mount --uts --net /bin/sh

# コンテナ内で
hostname   # コンテナごとに異なるホスト名
ps aux     # 各コンテナごとに隔離されたプロセス
```

---

## 各ステップの技術解説

### ステップ1: chroot

```bash
chroot ./rootfs /bin/sh
```

- **chroot**: ルートディレクトリを変更
- プロセスは `./rootfs` を `/` として認識
- 基本的なファイルシステム隔離

### ステップ2: PID Namespace

```bash
unshare --pid --fork chroot ./rootfs /bin/sh
```

- **unshare**: 新しいnamespaceを作成
- **--pid**: PID namespaceを作成
- **--fork**: 新しいプロセスをfork（PID namespaceに必要）

### ステップ3: Mount Namespace

```bash
unshare --pid --mount --fork chroot ./rootfs /bin/sh -c "
    mount -t proc proc /proc
    /bin/sh
"
```

- **--mount**: Mount namespaceを作成
- **mount -t proc**: `/proc` を再マウント
- これで `ps` コマンドが隔離されたプロセスのみ表示

### ステップ4: フル機能

```bash
unshare --pid --mount --uts --fork chroot ./rootfs /bin/sh -c "
    hostname my-container
    mount -t proc proc /proc
    /bin/sh
"
```

- **--uts**: UTS namespaceを追加
- **hostname**: コンテナ独自のホスト名を設定
- より完全な隔離環境

### ステップ5: Network Namespace

```bash
unshare --pid --mount --uts --net --fork chroot ./rootfs /bin/sh -c "
    hostname my-container
    mount -t proc proc /proc
    /bin/sh
"
```

- **--net**: Network namespaceを追加
- ネットワークが完全に隔離される
- loopbackインターフェースのみが存在

### ステップ6: cgroups

```bash
# cgroup v2の場合
mkdir /sys/fs/cgroup/my_container
echo "100M" > /sys/fs/cgroup/my_container/memory.max
echo "50000 100000" > /sys/fs/cgroup/my_container/cpu.max
echo $$ > /sys/fs/cgroup/my_container/cgroup.procs
```

- **cgroups**: リソース使用量を制限
- **memory.max**: メモリの上限を設定
- **cpu.max**: CPU使用率を制限
- プロセスをcgroupに追加して制限を適用

### ステップ7: 複数コンテナの同時起動

```bash
./step7_multi_container.sh 2
```

- **nsenter**: 既存のnamespaceにアタッチしてシェルを開く
- **同時起動**: ホスト側で複数の `unshare` プロセスを並列に起動し、それぞれに接続

---

## よくある質問（FAQ）

### Q1: なぜsudo権限が必要なのですか？

A: `chroot`、`mount`、一部の`unshare`機能はroot権限を必要とします。セキュリティ上の理由です。

### Q2: Dockerとの違いは何ですか？

A: このプロジェクトはDockerの**基礎部分**だけを実装しています。Dockerは以下も含みます：
- イメージ管理
- ネットワーク設定
- cgroups（リソース制限）
- レイヤーファイルシステム
- デーモンプロセス

### Q3: ネットワークはどうなっていますか？

A: ステップ5でNetwork namespaceを使ってネットワークを隔離します。ただし、外部との通信には：
- vethペア
- ブリッジネットワーク
- ルーティング設定

が必要です（より高度なトピック）。

### Q4: プロセスはどこまで隔離されていますか？

A: ステップ3以降は：
- ✅ プロセスツリーが隔離
- ✅ `/proc` が隔離
- ✅ コンテナ内から他のプロセスが見えない

### Q5: WSL2で動きますか？

A: はい！WSL2は完全なLinuxカーネルを実行しているため、すべての機能が動作します。

---

## トラブルシューティング

### エラー: "unshare: unshare failed: Operation not permitted"

**原因**: 権限不足

**解決策**:
```bash
sudo ./stepX_xxx.sh
```

### エラー: "chroot: failed to run command '/bin/sh': No such file or directory"

**原因**: rootfsが正しく準備されていない

**解決策**:
```bash
./setup_rootfs.sh
```

### エラー: "mount: /proc: permission denied"

**原因**: Mount namespaceでのマウント権限がない

**解決策**: スクリプト全体をsudoで実行

---

## 次のステップ

このプロジェクトを完了したら、以下に挑戦してみましょう：

### 1. vethペアとブリッジネットワーク

コンテナとホスト間の通信を実現：

```bash
# vethペアの作成
ip link add veth0 type veth peer name veth1
# ブリッジの作成
ip link add br0 type bridge
```

### 2. User Namespaceの追加

非特権コンテナの実装：

```bash
unshare --user --pid --fork /bin/sh
```

### 3. Overlay ファイルシステム

イメージレイヤーの実装：

```bash
mount -t overlay overlay -o lowerdir=base,upperdir=container,workdir=work merged
```

---

## 参考資料

- [Linux Namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [unshare コマンド](https://man7.org/linux/man-pages/man1/unshare.1.html)
- [chroot の仕組み](https://man7.org/linux/man-pages/man2/chroot.2.html)
- [Docker のアーキテクチャ](https://docs.docker.com/get-started/overview/)

---

## コードの改造アイデア

1. **コンテナ名を引数で指定**:
```bash
./step4_full_container.sh my-awesome-container
```

2. **起動時に任意のコマンドを実行**:
```bash
./step4_full_container.sh --command "ls -la"
```

3. **複数のコンテナを同時起動**:
```bash
./step4_full_container.sh &
./step4_full_container.sh &
```

4. **ログ記録機能の追加**:
```bash
./step4_full_container.sh 2>&1 | tee container.log
```

---

## ライセンス

このプロジェクトは教育目的で作成されています。自由に学習、改造、共有してください。

## 貢献

バグ報告、改善提案、質問は大歓迎です！
