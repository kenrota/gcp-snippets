//> using scala "3.3.3"
import java.io.{File, RandomAccessFile}
import scala.concurrent._
import ExecutionContext.Implicits.global

object LogWatcher {
  def watch(logFilePath: String, interval: Int): Unit = {
    val logFile = new RandomAccessFile(logFilePath, "r")
    var offsetPosition = logFile.length() // 初期オフセット位置をファイルの最後に設定

    Future {
      try {
        while (true) {
          if (!new File(logFilePath).exists()) {
            throw new Exception("Log file has been deleted")
          }

          logFile.seek(offsetPosition) // オフセット位置までファイルポインタを移動
          var line = logFile.readLine()

          while (line != null) {
            println(s"New log line: $line")
            offsetPosition = logFile.getFilePointer // 次回のファイルチェックのためにオフセット位置を更新
            line = logFile.readLine()
          }
          Thread.sleep(interval * 1000) // 定期的にファイルをチェック
        }
      } catch {
        case e: Exception => e.printStackTrace()
      } finally {
        logFile.close()
        System.exit(1)
      }
    }
  }

  def main(args: Array[String]): Unit = {
    if (args.length != 2) {
      println(
        "Usage: scala-cli LogWatcher.scala -- <log_file_path> <interval_in_seconds>"
      )
      println("Example: scala-cli LogWatcher.scala -- in/test.log 3")
      System.exit(1)
    }

    val logFilePath = args(0)
    val interval = args(1).toInt

    println(s"Watching log file: $logFilePath")
    println(s"Checking interval: $interval seconds")
    watch(logFilePath, interval)

    // メインスレッドを終了させないために無限ループ
    while (true) {
      Thread.sleep(60_000)
    }
  }
}
