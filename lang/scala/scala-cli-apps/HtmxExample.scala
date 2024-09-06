//> using dep com.lihaoyi::cask::0.9.2
//> using dep com.lihaoyi::scalatags::0.13.1
import scalatags.Text.all._
import scala.util.Random
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

object HtmxExample extends cask.MainRoutes {
  var rectColor = "black"

  def rect() = {
    div(
      id := "rect",
      style := s"width: 100px; height: 100px; background-color: $rectColor;",
      attr("hx-get") := "/toggle-color",
      attr("hx-swap") := "outerHTML",
    )
  }

  @cask.get("/")
  def index() = {
    html(
      head(
        script(src := "https://unpkg.com/htmx.org@1.9.12"),
        meta(charset := "utf-8")
      ),
      body(
        h1("Htmx Demo"),

        h2("Load Polling"),
        div(
          attr("hx-get") := "/progress",
          attr("hx-trigger") := "load, every 5s",
        ),

        h2("Click Event"),
        button(
          attr("hx-get") := "/clicked",
          attr("hx-trigger") := "click[shiftKey]",
          attr("hx-confirm") := "ok?",
          attr("hx-target") := "#sample_list",
          attr("hx-swap") := "afterend",
          "Shift + Click"
        ),
        ul(
          id := "sample_list", "History"
        ),

        h2("Toggle Color"),
        rect()
      )
    )
  }

  @cask.get("/progress")
  def progress() = {
    val progressPercentage = Random.between(0, 101)
    s"${progressPercentage}%"
  }

  @cask.get("/clicked")
  def clicked() = {
    val now = ZonedDateTime.now()
    val isoDateTime = now.format(DateTimeFormatter.ISO_DATE_TIME)
    li(isoDateTime)
  }

  @cask.get("/toggle-color")
  def toggleColor() = {
    val newColor = if (rectColor == "black") "gray" else "black"
    rectColor = newColor
    rect()
  }

  initialize()
}
