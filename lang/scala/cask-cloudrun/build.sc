import mill._, scalalib._

object app extends ScalaModule {
  def scalaVersion = "2.13.14"

  def ivyDeps = Agg(
    ivy"com.lihaoyi::cask:0.9.2",
  )
}
