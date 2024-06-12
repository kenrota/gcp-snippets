//> using dep com.lihaoyi::cask::0.9.2
//> using dep com.lihaoyi::scalatags::0.13.1
import scalatags.Text.all.*
import scala.util.Random

object HtmxExample extends cask.MainRoutes {
  @cask.get("/")
  def index() = {
    html(
      head(
        script(src := "https://unpkg.com/htmx.org@1.9.12"),
        meta(charset := "utf-8")
      ),
      body(
        h1("Progress"),
        div(
          attr("hx-get") := "/progress",
          attr("hx-trigger") := "load, every 5s",
        ),
      )
    )
  }

  @cask.get("/progress")
  def progress() = {
    val progressPercentage = Random.between(0, 101)
    s"${progressPercentage}%"
  }

  initialize()
}
