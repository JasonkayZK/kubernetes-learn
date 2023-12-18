FROM openjdk:8-jre-slim
MAINTAINER jasonkayzk@gmail.com
RUN mkdir /app
COPY target/*.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -jar /app/app.jar --spring.profiles.active=prod" ]
