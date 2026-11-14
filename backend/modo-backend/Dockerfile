From maven:3.9-eclipse-temurin-21 as build

Workdir /app

copy mvnw pom.xml ./
copy .mvn .mvn

run sed -i 's/\r$//' mvnw && chmod +x mvnw

Copy src ./src 

Run ./mvnw clean package -DskipTests

From eclipse-temurin:21-jre-alpine

workdir /app

copy --from=build /app/target/modo-backend-*.jar ./modo-backend.jar

expose 8080 

EntryPoint ["java", "-jar", "modo-backend.jar"]