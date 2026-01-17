# Makefile for NYU Lab in Cognition course environment setup
# This is intended to be run on JupyterHub to set up the student environment

# Can be overridden: make setup CONDA_ENV_NAME=my-env
CONDA_ENV_NAME ?= cognition
PYTHON_VERSION ?= 3.12

# Ensure venv doesn't interfere with conda commands
unexport VIRTUAL_ENV

.PHONY: help setup clean install-kernel remove-kernel list-kernels \
        test-notebooks test-chapters test-labs test-homeworks test-tips \
        test-chapter test-notebook test-config test-imports validate validate-quick

help:
	@echo "Available targets:"
	@echo ""
	@echo "Environment Setup:"
	@echo "  setup            Create conda environment and install all packages"
	@echo "  install-kernel   Manually register kernel (only if not auto-discovered)"
	@echo "  remove-kernel    Remove the Jupyter kernel"
	@echo "  list-kernels     List available Jupyter kernels"
	@echo "  clean            Remove the conda environment"
	@echo ""
	@echo "Testing:"
	@echo "  test-notebooks   Test all notebooks"
	@echo "  test-chapters    Test only chapter notebooks"
	@echo "  test-labs        Test only lab notebooks"
	@echo "  test-homeworks   Test only homework notebooks"
	@echo "  test-tips        Test only tips notebooks"
	@echo "  test-chapter     Test specific chapter (CHAPTER=05)"
	@echo "  test-notebook    Test specific notebook (NB=path/to.ipynb)"
	@echo "  test-config      Validate config files and dependencies"
	@echo "  test-imports     Check all notebook imports are available"
	@echo ""
	@echo "Validation:"
	@echo "  validate         Full validation (fresh env + all tests)"
	@echo "  validate-quick   Quick validation (existing env + all tests)"
	@echo ""
	@echo "Quick start:"
	@echo "  make setup"
	@echo ""
	@echo "Examples:"
	@echo "  make test-chapter CHAPTER=05"
	@echo "  make test-notebook NB=book/labs/LabSDT-Pt1.ipynb"
	@echo "  make setup CONDA_ENV_NAME=lab-in-cp-test  # Use custom env name"

setup:
	@echo "Creating conda environment '$(CONDA_ENV_NAME)' with Python $(PYTHON_VERSION)..."
	conda create -n $(CONDA_ENV_NAME) python=$(PYTHON_VERSION) -y
	@echo "Installing conda packages..."
	conda install -n $(CONDA_ENV_NAME) -y \
		numpy \
		pandas \
		matplotlib \
		seaborn \
		scipy \
		statsmodels \
		scikit-learn \
		ipywidgets \
		ipykernel \
		pillow
	@echo "Installing conda-forge packages..."
	conda install -n $(CONDA_ENV_NAME) -c conda-forge -y nodejs
	@echo "Installing pip packages..."
	@# Use bash subshell to fully isolate from any local venv
	conda run -n $(CONDA_ENV_NAME) --no-capture-output bash -c '\
		unset VIRTUAL_ENV; \
		python -m pip install \
			ipycanvas \
			pingouin \
			nibabel \
			celluloid \
			watermark \
			yellowbrick \
			xarray \
			wikipedia \
			ptitprince \
			scikit-image \
			petpy \
			myst-nb \
			pyreadr \
			markdown'
	@echo ""
	@echo "========================================"
	@echo "Setup complete!"
	@echo "========================================"
	@echo "Environment '$(CONDA_ENV_NAME)' created."
	@echo "Select 'Python ($(CONDA_ENV_NAME))' in JupyterHub to use it."

install-kernel:
	@echo "Installing Jupyter kernel for '$(CONDA_ENV_NAME)'..."
	conda run -n $(CONDA_ENV_NAME) python -m ipykernel install --user --name $(CONDA_ENV_NAME) --display-name "Python (Cognition)"
	@echo "Kernel installed! You can now select 'Python (Cognition)' in JupyterHub."

remove-kernel:
	@echo "Removing Jupyter kernel '$(CONDA_ENV_NAME)'..."
	jupyter kernelspec uninstall $(CONDA_ENV_NAME) -y || true
	@echo "Kernel removed."

list-kernels:
	@echo "Available Jupyter kernels:"
	jupyter kernelspec list

clean: remove-kernel
	@echo "Removing conda environment '$(CONDA_ENV_NAME)'..."
	conda env remove -n $(CONDA_ENV_NAME) -y || true
	@echo "Environment removed."

# =============================================================================
# NOTEBOOK TESTING
# =============================================================================

# Helper function to test notebooks (used by other targets)
define test_notebooks
	@echo "========================================"; \
	echo "Testing: $(1)"; \
	echo "========================================"; \
	echo ""; \
	failed=""; passed=0; total=0; \
	for nb in $(2); do \
	    total=$$((total + 1)); \
	    printf "[%d] %-65s " "$$total" "$$nb"; \
	    if conda run -n $(CONDA_ENV_NAME) jupyter nbconvert --to notebook --execute \
	        --ExecutePreprocessor.timeout=300 \
	        --ExecutePreprocessor.kernel_name=$(CONDA_ENV_NAME) \
	        --output /tmp/test_output.ipynb "$$nb" >/dev/null 2>&1; then \
	        echo "✓ PASSED"; \
	        passed=$$((passed + 1)); \
	    else \
	        echo "✗ FAILED"; \
	        failed="$$failed\n  - $$nb"; \
	    fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	echo "RESULTS: $$passed/$$total notebooks passed"; \
	echo "========================================"; \
	if [ -n "$$failed" ]; then \
	    echo ""; \
	    echo "Failed notebooks:"; \
	    printf "$$failed\n"; \
	    echo ""; \
	    exit 1; \
	fi
endef

# Find notebooks excluding checkpoints, Untitled, and MRI labs
NOTEBOOKS_ALL = $(shell find book -name "*.ipynb" \
    -not -path "*/.ipynb_checkpoints/*" \
    -not -name "Untitled.ipynb" \
    -not -name "LabReg-MRI-Pt1.ipynb" \
    -not -name "LabReg-MRI-Pt2.ipynb" | sort)

NOTEBOOKS_CHAPTERS = $(shell find book/chapters -name "*.ipynb" \
    -not -path "*/.ipynb_checkpoints/*" \
    -not -name "Untitled.ipynb" | sort)

NOTEBOOKS_LABS = $(shell find book/labs -name "*.ipynb" \
    -not -path "*/.ipynb_checkpoints/*" \
    -not -name "LabReg-MRI-Pt1.ipynb" \
    -not -name "LabReg-MRI-Pt2.ipynb" | sort)

NOTEBOOKS_HOMEWORKS = $(shell find book/homeworks -name "*.ipynb" \
    -not -path "*/.ipynb_checkpoints/*" | sort)

NOTEBOOKS_TIPS = $(shell find book/tips -name "*.ipynb" \
    -not -path "*/.ipynb_checkpoints/*" | sort)

# Test all notebooks
test-notebooks:
	$(call test_notebooks,All Notebooks,$(NOTEBOOKS_ALL))

# Test only chapter notebooks
test-chapters:
	$(call test_notebooks,Chapter Notebooks,$(NOTEBOOKS_CHAPTERS))

# Test only lab notebooks
test-labs:
	$(call test_notebooks,Lab Notebooks,$(NOTEBOOKS_LABS))

# Test only homework notebooks
test-homeworks:
	$(call test_notebooks,Homework Notebooks,$(NOTEBOOKS_HOMEWORKS))

# Test only tips notebooks
test-tips:
	$(call test_notebooks,Tips Notebooks,$(NOTEBOOKS_TIPS))

# Test a specific chapter (usage: make test-chapter CHAPTER=05)
test-chapter:
ifndef CHAPTER
	$(error CHAPTER is not set. Usage: make test-chapter CHAPTER=05)
endif
	$(call test_notebooks,Chapter $(CHAPTER),$(shell find book/chapters/$(CHAPTER) -name "*.ipynb" \
	    -not -path "*/.ipynb_checkpoints/*" -not -name "Untitled.ipynb" | sort))

# Test a specific notebook (usage: make test-notebook NB=book/labs/LabSDT-Pt1.ipynb)
test-notebook:
ifndef NB
	$(error NB is not set. Usage: make test-notebook NB=book/labs/LabSDT-Pt1.ipynb)
endif
	$(call test_notebooks,Single Notebook,$(NB))

# =============================================================================
# CONFIG VALIDATION
# =============================================================================

# Validate Jupyter Book configuration
test-config:
	@echo "========================================"
	@echo "Validating Configuration"
	@echo "========================================"
	@echo ""
	@echo "Checking _config.yml..."
	@if [ -f book/_config.yml ]; then \
	    echo "  ✓ _config.yml exists"; \
	    conda run -n $(CONDA_ENV_NAME) python -c "import yaml; yaml.safe_load(open('book/_config.yml'))" && \
	    echo "  ✓ _config.yml is valid YAML" || echo "  ✗ _config.yml has YAML errors"; \
	else \
	    echo "  ✗ _config.yml not found"; \
	fi
	@echo ""
	@echo "Checking _toc.yml..."
	@if [ -f book/_toc.yml ]; then \
	    echo "  ✓ _toc.yml exists"; \
	    conda run -n $(CONDA_ENV_NAME) python -c "import yaml; yaml.safe_load(open('book/_toc.yml'))" && \
	    echo "  ✓ _toc.yml is valid YAML" || echo "  ✗ _toc.yml has YAML errors"; \
	else \
	    echo "  ✗ _toc.yml not found"; \
	fi
	@echo ""
	@echo "Checking required data files..."
	@for f in book/data/advertising.csv book/data/parenthood.csv book/data/salary.csv; do \
	    if [ -f "$$f" ]; then echo "  ✓ $$f"; else echo "  ✗ $$f missing"; fi; \
	done
	@echo ""
	@echo "Checking custom modules..."
	@for f in book/labs/sdt_exp.py book/labs/rl_exp.py; do \
	    if [ -f "$$f" ]; then echo "  ✓ $$f"; else echo "  ✗ $$f missing"; fi; \
	done
	@echo ""
	@echo "========================================"
	@echo "Config validation complete"
	@echo "========================================"

# Check all imports used in notebooks are available
test-imports:
	conda run -n $(CONDA_ENV_NAME) python scripts/check_imports.py

# Check imports with verbose output
test-imports-verbose:
	conda run -n $(CONDA_ENV_NAME) python scripts/check_imports.py --verbose

# =============================================================================
# FULL VALIDATION
# =============================================================================

# Full validation: fresh environment + config + all notebooks
validate: clean setup test-config test-notebooks
	@echo ""
	@echo "========================================"
	@echo "Full Validation Complete!"
	@echo "========================================"

# Quick validation: just config + notebooks (uses existing environment)
validate-quick: test-config test-notebooks
	@echo ""
	@echo "========================================"
	@echo "Quick Validation Complete!"
	@echo "========================================"
