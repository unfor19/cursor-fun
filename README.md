# cursor-fun

A simple project to learn how to use cursor.

This is a monorepo project, we'll start with a simple python project and then add more projects to it.

## Requirements

Read the `README.md` file os each project to see the requirements for each project.

For example, see [azureai-basic-python/README.md](azureai-basic-python/README.md) for the requirements for the azureai-basic-python project.

### Setup

1. Copy `env` to `.env` and update the `PROJECT_NAME`
   ```bash
   cp env .env
   ```

   ```
   PROJECT_NAME=azureai-basic-python
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
