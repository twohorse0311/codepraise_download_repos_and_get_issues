# CodePraise Project

CodePraise is a tool for analyzing the code quality of GitHub repositories. It can retrieve repository information, analyze code metrics, and generate reports.

## Features

- Retrieve repository information from GitHub
- Analyze code quality metrics (such as readability, code smells, cyclomatic complexity, etc.)
- Generate Excel reports
- Support batch processing of multiple repositories
- Retrieve repository issue information

## Installation

1. Ensure you have Ruby installed (version specified in the `.ruby-version` file)
2. Clone this repository
3. Run `bundle install` to install dependencies

## Configuration

1. Copy `config/secrets.yml.example` to `config/secrets.yml`
2. Fill in your GitHub token and other necessary configuration information in `config/secrets.yml`

## Usage

### Run the main program

`rake run:dev`

### Run single repository analysis

`rake run:single`

### Export data

`rake export:data`

### Get issues

`rake get_issue`