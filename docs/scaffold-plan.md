# Task Tracker CRUD App Scaffold Plan

## Overview
This document outlines the initial scaffold plan for the Task Tracker backend application. The goal is to build a simple CRUD service that interacts with AWS services to showcase core AWS skills.

## Technology Stack
- Language: Java (Spring Boot recommended)
- Database: Amazon RDS (PostgreSQL)
- Optional later addition: DynamoDB for caching/session storage
- Infrastructure as Code: Terraform (EC2), CloudFormation (Fargate)
- Monitoring: AWS CloudWatch

## API Endpoints (Initial)
- `GET /tasks` – List all tasks
- `GET /tasks/{id}` – Retrieve a single task by ID
- `POST /tasks` – Create a new task
- `PUT /tasks/{id}` – Update a task by ID
- `DELETE /tasks/{id}` – Delete a task by ID

## Data Model (Initial)
- Task
  - id (UUID)
  - title (string)
  - description (string)
  - status (enum: TODO, IN_PROGRESS, DONE)
  - createdAt (timestamp)
  - updatedAt (timestamp)

## Testing
- Use Postman or curl for API endpoint testing
- Basic unit tests with JUnit

## Notes
- Frontend is optional and planned for Phase 7
- Focus is on backend and AWS integration for now

## Next Steps
- Initialize GitHub repo and push scaffold plan
- Start Java Spring Boot project setup
- Create basic CRUD endpoints and connect to RDS
