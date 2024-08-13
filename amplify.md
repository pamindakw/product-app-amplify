version: 1
applications:
  - frontend:
      phases:
        preBuild:
          commands:
            - echo Installing source NPM dependencies
            - npm install
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory:
        files:
          - "**/*"
      cache:
        paths:
          - node_modules/**/*
    appRoot: frontend
