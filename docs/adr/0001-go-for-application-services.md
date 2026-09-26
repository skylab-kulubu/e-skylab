# Go for application services

Java application services (super-skylab, Spring Cloud Gateway, Eureka) will be replaced with Go. The team no longer maintains Java, and the current JVM trio plus Keycloak is exhausting RAM and CPU on the host. Keycloak stays as the identity provider; it is a third-party JVM we run, not an application we write.
