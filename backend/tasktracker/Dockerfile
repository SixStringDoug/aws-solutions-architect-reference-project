# syntax=docker/dockerfile:1

# -----------------------------
# Build stage
# -----------------------------
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copy pom first for dependency caching
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline

# Copy source
COPY src ./src

RUN mvn -q -DskipTests clean package


# -----------------------------
# Runtime stage
# -----------------------------
FROM eclipse-temurin:17-jre

WORKDIR /app

# Install curl for healthcheck
RUN apt-get update \
 && apt-get install -y curl \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/target/*-SNAPSHOT.jar app.jar

ENV JAVA_OPTS=""

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:8080/api/tasks || exit 1

ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]