//> using scala "3.3.3"
//> using dep "com.lihaoyi::os-lib:0.9.1"
//> using dep "com.lihaoyi::requests:0.8.2"
//> using dep "com.lihaoyi::scalatags:0.12.0"
//> using dep "com.lihaoyi::upickle:3.1.0"
import scalatags.Text.all._
import ujson._
import scala.util.Random

object HtmlReportExample extends App {
  os.remove.all(os.pwd / "out")
  os.makeDir.all(os.pwd / "out")

  // データを生成
  val xValues = (0 to 23)
  val maxYValue = 100
  val yValues = (0 to 23).map(_ => Random.nextInt(maxYValue + 1))
  val data: ujson.Value = ujson.Obj(
    "x" -> ujson.Arr(xValues.map(ujson.Num(_)): _*),
    "y" -> ujson.Arr(yValues.map(ujson.Num(_)): _*),
    "type" -> "bar",
    "name" -> "random data"
  )
  val layout = ujson.Obj(
    "title" -> "Random Data Chart"
  )

  // データをJSONに変換
  val dataJson = ujson.write(data)
  val layoutJson = ujson.write(layout)

  // 平均値、合計値、最大値、最小値を計算
  val average = yValues.sum.toDouble / yValues.size
  val total = yValues.sum
  val maxValue = yValues.max
  val minValue = yValues.min

  // 統計データのテーブルを作成
  val statsTable = table(
    tr(th("Stats"), th("Value")),
    tr(td("Average"), td(f"$average%.2f")),
    tr(td("Total"), td(total)),
    tr(td("Max"), td(maxValue)),
    tr(td("Min"), td(minValue))
  )

  val htmlContent =
    html(
      head(
        script(src := "https://cdn.plot.ly/plotly-latest.min.js")
      ),
      body(
        h1("Report", style := "text-align: center"),
        div(id := "chartDiv"),
        script(raw(s"""
        const data = [$dataJson];
        const layout = $layoutJson;
        Plotly.newPlot('chartDiv', data, layout);
      """)),
        statsTable
      )
    )

  os.write(
    os.pwd / "out" / "report.html",
    doctype("html")(
      htmlContent
    )
  )
}
