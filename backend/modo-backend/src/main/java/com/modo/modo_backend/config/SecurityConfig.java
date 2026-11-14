package com.modo.modo_backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Actuator endpoints must be reachable by Prometheus without authentication
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/**").permitAll()
                .anyRequest().authenticated()
            )
            // Disable CSRF for actuator scraping simplicity
            .csrf(csrf -> csrf
                .ignoringRequestMatchers("/actuator/**")
            );
        return http.build();
    }
}