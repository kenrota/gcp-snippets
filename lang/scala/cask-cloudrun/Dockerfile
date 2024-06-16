FROM openjdk:11

WORKDIR /app

COPY out/app/assembly.dest/out.jar /app

EXPOSE 8080

CMD ["java", "-jar", "/app/out.jar"]
