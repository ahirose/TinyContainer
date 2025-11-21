# コンテナ学習ガイド

このガイドでは、Linuxコンテナの仕組みを理解するために、段階的に独自のコンテナを実装していきます。

## 前提知識

- C言語の基礎知識
- Linuxコマンドの基本操作
- システムコールの概念

## 必要な環境

- Linux環境（WSL2で実行可能）
- GCC（Cコンパイラ）
- root権限またはunshareコマンド

## 学習ステップ

### ステップ1: 基本的なchroot環境

**学習目標**: ファイルシステムの隔離の基礎を理解する

**使用する技術**:
- `chroot()` システムコール
- ルートファイルシステム（rootfs）の準備

**実装内容**:
- Alpine Linux rootfsのダウンロード
- chrootによるルート変更
- 隔離されたシェルの起動

**ファイル**: `step1_chroot/simple_container.c`

---

### ステップ2: PID Namespace

**学習目標**: プロセスIDの隔離を理解する

**使用する技術**:
- `clone()` システムコール
- `CLONE_NEWPID` フラグ
- PID namespace

**実装内容**:
- 新しいPID namespaceの作成
- コンテナ内でPID 1として動作
- プロセスツリーの隔離

**ファイル**: `step2_pid_namespace/container_with_pid.c`

**確認方法**:
```bash
# コンテナ内で
ps aux  # PID 1から始まることを確認
```

---

### ステップ3: Mount Namespace

**学習目標**: ファイルシステムマウントの隔離を理解する

**使用する技術**:
- `CLONE_NEWNS` フラグ
- `mount()` システムコール
- `/proc`, `/sys` の再マウント

**実装内容**:
- Mount namespaceの作成
- procfsとsysfsのマウント
- 独立したマウントポイント

**ファイル**: `step3_mount_namespace/container_with_mount.c`

---

### ステップ4: UTS Namespace

**学習目標**: ホスト名の隔離を理解する

**使用する技術**:
- `CLONE_NEWUTS` フラグ
- `sethostname()` システムコール

**実装内容**:
- UTS namespaceの作成
- コンテナ独自のホスト名設定

**ファイル**: `step4_uts_namespace/container_with_uts.c`

---

### ステップ5: Network Namespace

**学習目標**: ネットワークの隔離を理解する

**使用する技術**:
- `CLONE_NEWNET` フラグ
- vethペアの作成
- ネットワークブリッジ

**実装内容**:
- Network namespaceの作成
- 仮想ネットワークインターフェースの設定
- ホストとの通信

**ファイル**: `step5_network_namespace/container_with_network.c`

---

### ステップ6: cgroups（リソース制限）

**学習目標**: リソース制限の仕組みを理解する

**使用する技術**:
- cgroup filesystem
- memory cgroup
- CPU cgroup

**実装内容**:
- cgroupの作成と設定
- メモリ制限の適用
- CPU使用率の制限

**ファイル**: `step6_cgroups/container_with_cgroups.c`

---

### ステップ7: 統合コンテナ

**学習目標**: すべての技術を統合した完全なコンテナを作成する

**実装内容**:
- すべてのnamespaceを統合
- cgroupsによるリソース制限
- エラーハンドリングの強化
- コマンドライン引数の処理

**ファイル**: `step7_full_container/mycontainer.c`

---

## 各ステップの実行方法

各ディレクトリに移動して以下を実行：

```bash
# コンパイル
make

# 実行（root権限が必要）
sudo ./container

# または（unshareが使える場合）
./container
```

## 推奨学習順序

1. まず各ステップのコードを読んで理解する
2. コンパイルして実行してみる
3. コード内のコメントを参考に、動作を確認する
4. 自分でコードを修正して実験してみる
5. 次のステップに進む

## デバッグのヒント

- `strace` コマンドでシステムコールを追跡
- `/proc` ファイルシステムで現在の状態を確認
- `ps`, `mount`, `ip` などのコマンドで隔離状態を確認

## 参考資料

- [Linux Namespaces (man 7 namespaces)](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [cgroups (man 7 cgroups)](https://man7.org/linux/man-pages/man7/cgroups.7.html)
- [Docker のアーキテクチャ](https://docs.docker.com/get-started/overview/)
- [LXC (Linux Containers)](https://linuxcontainers.org/)

## よくある質問

**Q: なぜroot権限が必要なのですか？**
A: 多くのnamespaceの作成にはroot権限が必要です。ただし、User namespaceを使うことで、非特権ユーザーでも実行可能になります（ステップ7で学習）。

**Q: Dockerとはどのような関係ですか？**
A: Dockerも基本的に同じLinuxカーネル機能を使用しています。このプロジェクトでDockerの内部動作を理解できます。

**Q: WindowsやmacOSでは動きますか？**
A: Linux専用の機能のため、WSL2（Windows）やLinux VM（macOS）が必要です。

## 次のステップ

すべてのステップを完了したら、以下に挑戦してみましょう：

- [ ] イメージレイヤーシステムの実装
- [ ] ネットワークブリッジの自動設定
- [ ] コンテナのライフサイクル管理
- [ ] OCIランタイム仕様の学習
