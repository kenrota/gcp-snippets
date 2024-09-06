val pattern = raw"(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})".r
val input = "2024-09-06"

input match {
  case pattern(year, month, day) =>
    println(s"Year: $year, Month: $month, Day: $day")
  case _ => println("No match")
}
