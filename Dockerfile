# Build stage (Java 17)
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage (Must also be Java 17)
FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=build /app/target/devops-assignment-1.0.0.jar /app/app.jar
RUN chown -R appuser:appgroup /app
USER appuser

# Ensure entrypoint is explicitly defined
ENTRYPOINT ["java", "-jar", "app.jar"]
