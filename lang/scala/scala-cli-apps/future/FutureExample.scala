//> using scala "3.3.3"
//> using dep "com.lihaoyi::requests:0.9.0"
//> using dep "com.lihaoyi::upickle:4.0.2"

import scala.concurrent.{Future, Await}
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration.DurationInt

object FutureExample extends App {

  // HTTPリクエストを非同期で実行する関数
  def sendRequest(number: Int): Future[Int] = {
    val url = "https://httpbin.org/anything"
    Future {
      // 数値をリクエストボディに含めて送信
      val response = requests.post(url, data = ujson.Obj("number" -> number))
      val json = ujson.read(response.text())
      json("json")("number").num.toInt
    }
  }

  // 2つの非同期リクエストの結果を合算する
  val futureResult: Future[Int] = for {
    result1 <- sendRequest(number = 1)
    result2 <- sendRequest(number = 2)
  } yield result1 + result2

  // Futureの結果を最大10秒まで待機
  val result = Await.result(futureResult, 10.seconds)
  println(s"Result: $result")
}
