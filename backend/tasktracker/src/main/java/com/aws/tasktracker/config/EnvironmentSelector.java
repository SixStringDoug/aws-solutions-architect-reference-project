package com.aws.tasktracker.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class EnvironmentSelector {

    @Value("${app.env}")
    private String environment;

    /**
     * Phase 4 decision:
     * Fargate uses RDS, not DynamoDB.
     * DynamoDB can be reintroduced later in a future phase when intentionally planned.
     */
    public boolean useDynamoDb() {
//        return "fargate".equalsIgnoreCase(environment);
        return false;
    }

    public boolean useRds() {
//        return "ec2".equalsIgnoreCase(environment) || "beanstalk".equalsIgnoreCase(environment);
        return "ec2".equalsIgnoreCase(environment)
                || "fargate".equalsIgnoreCase(environment)
                || "beanstalk".equalsIgnoreCase(environment)
                || "local".equalsIgnoreCase(environment);
    }
}
