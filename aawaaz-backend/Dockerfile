# Build the Spring Boot jar, then run it on a slim JRE.
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
COPY . .
RUN ./mvnw -q -B -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/aawaaz-backend-*.jar app.jar
EXPOSE 8080
# SARVAM_API_KEY is injected at runtime (docker run -e SARVAM_API_KEY=...).
ENTRYPOINT ["java", "-jar", "app.jar"]
