#!/bin/bash

PROJECT_NAME=''
PYTHON_VERSION=''
MAIN_MODULE=''

while getopts "p:v:m:" flag; do
  case "${flag}" in
    p) PROJECT_NAME="${OPTARG}" ;;
    v) PYTHON_VERSION="${OPTARG}" ;;
    m) MAIN_MODULE=$(echo ${OPTARG} | sed 's/-/_/g') ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done
if [ -z $PROJECT_NAME ]; then
  PROJECT_NAME='example-python-project';
fi
if [ -z $PYTHON_VERSION ]; then
  PYTHON_VERSION='3.5.0';
fi
if [ -z $MAIN_MODULE ]; then
  MAIN_MODULE=$(echo $PROJECT_NAME | sed 's/-/_/g');
fi

# Step 1: Make the root project, tests, and requirements directories
cd ..
mkdir $PROJECT_NAME
cd $PROJECT_NAME
mkdir $MAIN_MODULE requirements tests

# Step 2: Create a standard .gitignore
cat >.gitignore <<EOL
__pycache__
*.py[cod]
*.sw[po]

.DS_Store

# C extensions
*.so

# Packages
dist
build
env/
.env.local

# Installer logs
pip-log.txt

# Unit test / coverage reports
.coverage
htmlcov/
coverage.xml

docs/_build
EOL

# Step 3: Create a standard README.md
cat >README.md <<EOL
Bootstrapped with the Python Bootstrapper!
EOL

# Step 4: Pin the Python version
pyenv local $PYTHON_VERSION

# Step 5: Create a standard coverage.cfg file
cat >coverage.cfg <<EOL
[run]
branch = True
source = $MAIN_MODULE
include = $MAIN_MODULE/*
          tests/*
EOL

# Step 6: Create a standard scent.py file
cat >scent.py <<EOL
from sniffer.api import file_validator, runnable
import os
import termstyle


pass_fg_color = termstyle.green
pass_bg_color = termstyle.bg_default
fail_fg_color = termstyle.red
fail_bg_color = termstyle.bg_default

watch_paths = ['$MAIN_MODULE/', 'tests/', './scent.py']


@file_validator
def py_files(filename):
    return (filename.endswith('.py') and
            not os.path.basename(filename).startswith('.'))


@runnable
def execute_manage_test(*args):
    import os
    os.system('env/bin/coverage erase')
    exit_code = os.system(
        'env/bin/coverage run --rcfile=coverage.cfg -m unittest discover ./tests'
    )
    os.system('env/bin/coverage report --rcfile=coverage.cfg')
    os.system('env/bin/coverage html --rcfile=coverage.cfg; touch htmlcov')
    return exit_code == 0
EOL

# Step 7: Create a standard requirements/base.txt file
cat >requirements/base.txt <<EOL
Sphinx==1.5.2
EOL

# Step 8: Create a standard requirements/dev.txt file
cat >requirements/dev.txt <<EOL
bpython==0.16
coverage==4.3.4
sniffer==0.4.0
EOL

# Step 9: Add __init__.py files to the root project and tests directories
touch $MAIN_MODULE/__init__.py tests/__init__.py

# Step 10: Create a standard Makefile
cat >Makefile <<EOL
VENV     = \$(CURDIR)/env
PIP      = \$(VENV)/bin/pip
DEV_DEPS = install -r requirements/dev.txt

test: | \$(VENV)/bin/coverage
$(res='\t'; echo -e ''$res'')\$(VENV)/bin/coverage run --rcfile=coverage.cfg -m unittest discover ./tests
$(res='\t'; echo -e ''$res'')\$(VENV)/bin/coverage report --rcfile=coverage.cfg
$(res='\t'; echo -e ''$res'')\$(VENV)/bin/coverage html --rcfile=coverage.cfg
$(res='\t'; echo -e ''$res'')touch htmlcov

test-watch: | \$(VENV)/bin/sniffer
$(res='\t'; echo -e ''$res'')\$(VENV)/bin/sniffer

shell: | \$(VENV)/bin/bpython
$(res='\t'; echo -e ''$res'')\$(VENV)/bin/bpython

clean:
$(res='\t'; echo -e ''$res'')find . -name "__pycache__" -exec rm -rf {} \;
$(res='\t'; echo -e ''$res'')rm -rf \$(VENV) htmlcov

\$(VENV)/bin/bpython: | \$(PIP)
$(res='\t'; echo -e ''$res'')\$(PIP) \$(DEV_DEPS)

\$(VENV)/bin/coverage: | \$(PIP)
$(res='\t'; echo -e ''$res'')\$(PIP) \$(DEV_DEPS)

\$(VENV)/bin/sniffer: | \$(PIP)
$(res='\t'; echo -e ''$res'')\$(PIP) \$(DEV_DEPS)

\$(PIP): | env
$(res='\t'; echo -e ''$res'')\$(PIP) install -r requirements/base.txt

env:
$(res='\t'; echo -e ''$res'')virtualenv -p `which python` \$(VENV)
$(res='\t'; echo -e ''$res'')\$(PIP) install pip --upgrade
EOL

# Step 11: Install the environment
make test
