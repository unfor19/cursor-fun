# cursor-fun

A simple project to learn how to use cursor.

This is a monorepo project, we'll start with a simple python project and then add more projects to it.

## Requirements

Read the `README.md` file os each project to see the requirements for each project.

For example, see [azureai-basic-python/README.md](azureai-basic-python/README.md) for the requirements for the azureai-basic-python project.

### Getting Started

1. Copy `env` to `.env` and update the `PROJECT_NAME`
   ```bash
   cp env .env
   ```

   ```
   PROJECT_NAME=azureai-basic-python
   ```
1. Copy `${PROJECT_NAME}/env` to `${PROJECT_NAME}/.env`
   ```bash
   cp ${PROJECT_NAME}/env ${PROJECT_NAME}/.env
   ```

    ```
    USE_SEARCH_SERVICE=false
    USE_APPLICATION_INSIGHTS=true
    USE_CONTAINER_REGISTRY=true
    SUBDIR=src
    PYTHON_SCRIPT=main.py
    REQUIREMENTS_FILE_PATH=src/requirements.txt
    ```

2. Prepare the virtual environment
   ```bash
   make prepare
   ```
3. Install Python packages on the virtual environment
   ```bash
   make install
   ```
4. Run the application
   ```bash
   make run
   ```
