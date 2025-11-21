/*
 * ステップ1: 基本的なchrootコンテナ
 *
 * このプログラムは、chrootシステムコールを使用して
 * ファイルシステムの隔離を実現します。
 *
 * 学習ポイント:
 * - chroot()の動作原理
 * - ルートファイルシステムの変更
 * - プロセスから見える世界の制限
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>
#include <errno.h>

// 新しいルートディレクトリのパス
#define NEW_ROOT "./rootfs"

/*
 * コンテナ内で実行する関数
 */
int container_main(void* arg) {
    printf("[コンテナ] コンテナプロセス開始 (PID: %d)\n", getpid());

    // 1. 新しいルートディレクトリに移動
    printf("[コンテナ] %s に移動します\n", NEW_ROOT);
    if (chdir(NEW_ROOT) != 0) {
        fprintf(stderr, "エラー: chdir失敗: %s\n", strerror(errno));
        return 1;
    }

    // 2. chrootでルートを変更
    printf("[コンテナ] chrootを実行します\n");
    if (chroot(".") != 0) {
        fprintf(stderr, "エラー: chroot失敗: %s\n", strerror(errno));
        fprintf(stderr, "ヒント: sudo で実行してください\n");
        return 1;
    }

    // 3. 新しいルート内の /bin に移動
    if (chdir("/bin") != 0) {
        fprintf(stderr, "エラー: /bin への移動失敗: %s\n", strerror(errno));
        return 1;
    }

    printf("[コンテナ] 隔離されたシェルを起動します\n");
    printf("[コンテナ] 'ls', 'pwd', 'exit' などを試してみてください\n");
    printf("=====================================\n\n");

    // 4. シェルを起動
    char *const args[] = {"/bin/sh", NULL};
    if (execv("/bin/sh", args) != 0) {
        fprintf(stderr, "エラー: シェルの起動失敗: %s\n", strerror(errno));
        return 1;
    }

    // execv が成功すれば、ここには到達しない
    return 0;
}

int main() {
    printf("===== ステップ1: 基本的なchroot コンテナ =====\n\n");

    // rootfsの存在確認
    if (access(NEW_ROOT, F_OK) != 0) {
        fprintf(stderr, "エラー: %s が見つかりません\n", NEW_ROOT);
        fprintf(stderr, "まず ./setup.sh を実行してrootfsを準備してください\n");
        return 1;
    }

    printf("[ホスト] 現在のPID: %d\n", getpid());
    printf("[ホスト] コンテナプロセスを起動します...\n\n");

    // 子プロセスを作成してコンテナを実行
    pid_t pid = fork();

    if (pid == -1) {
        fprintf(stderr, "エラー: fork失敗: %s\n", strerror(errno));
        return 1;
    }

    if (pid == 0) {
        // 子プロセス（コンテナ）
        return container_main(NULL);
    }

    // 親プロセス（ホスト）
    // 子プロセスの終了を待つ
    int status;
    waitpid(pid, &status, 0);

    printf("\n=====================================\n");
    printf("[ホスト] コンテナプロセスが終了しました\n");

    if (WIFEXITED(status)) {
        printf("[ホスト] 終了コード: %d\n", WEXITSTATUS(status));
    }

    return 0;
}
