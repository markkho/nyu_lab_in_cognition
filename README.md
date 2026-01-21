# NYU Lab in Cognition (+ Perception or what have you)

## Overview

NYU Psychology department recently has begun to roll out a new approach to laboratory classes in
psychology.  One aspect of this new approach is the use of Jupyter notebooks to help provide
interesting and interactive "hands-on" type learning tasks.  This repository includes
the notebooks, quizzes, exams, and laboratory units that make up these labs.  They are available
open source so that other instructors can use these materials and hopefully even contribute to them
via git pull requests!

## Hosting the book

Deployment is handled from this repository using github actions.
Changes to this repository will be reflected in the hosted website.

## Setting up JupyterHub

The course materials support integration with JupyterHub. To set this up:

1. Contact Instructional-Tools-For-Coding@nyu.edu to set up a JupyterHub site for the course
2. Log into JupyterHub as an **instructor** in **turbo mode** and open a terminal.
3. Clone or upload this repository to JupyterHub by typing:
```
git clone https://github.com/markkho/nyu_lab_in_cognition.git
```
5. Navigate to the repository directory (`nyu_lab_in_cognition/`)
6. Run:
```
make setup
```

This creates a conda environment called `cognition` with all required Python packages.

If kernels aren't auto-discovered, also run `make install-kernel`.

### Launching notebooks from the book

The Jupyter Book is configured with a launch button (rocket icon) that lets students open notebooks directly in JupyterHub. Make sure `_config.yml` has the correct JupyterHub URL configured under `launch_buttons`.

## Setting up for local development

To build the book, from the root directory:
```bash
$ cd book
$ make book
```

To serve locally, from the root directory:
```bash
$ cd book
$ make serve
```

## Course resources
- JupyterHub for notebooks (email Instructional-Tools-For-Coding@nyu.edu)
- Gradescope for assignments
- Ed discussion for announcements

## TODO
- Fix images in Ch 9 on sampling
- Add Ch 8 on describing data ICA
